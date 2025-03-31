/*
  # Fix user registration trigger

  1. Changes
    - Update handle_new_user function to properly validate and require metadata
    - Ensure errors are raised instead of silently ignored
    - Add proper error messages for missing fields
*/

-- First drop existing trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Drop existing function
DROP FUNCTION IF EXISTS handle_new_user();

-- Create improved handle_new_user function with strict validation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Validate required metadata fields
  IF NEW.raw_user_meta_data IS NULL THEN
    RAISE EXCEPTION 'User metadata is required';
  END IF;

  -- Validate all required fields
  IF NEW.raw_user_meta_data->>'first_name' IS NULL THEN
    RAISE EXCEPTION 'First name is required';
  END IF;

  IF NEW.raw_user_meta_data->>'last_name' IS NULL THEN
    RAISE EXCEPTION 'Last name is required';
  END IF;

  IF NEW.raw_user_meta_data->>'company_name' IS NULL THEN
    RAISE EXCEPTION 'Company name is required';
  END IF;

  IF NEW.raw_user_meta_data->>'phone' IS NULL THEN
    RAISE EXCEPTION 'Phone number is required';
  END IF;

  -- Insert partner record
  INSERT INTO public.partners (
    id,
    email,
    first_name,
    last_name,
    company_name,
    phone
  ) VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'first_name',
    NEW.raw_user_meta_data->>'last_name',
    NEW.raw_user_meta_data->>'company_name',
    NEW.raw_user_meta_data->>'phone'
  );

  RETURN NEW;
END;
$$ language 'plpgsql';

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();