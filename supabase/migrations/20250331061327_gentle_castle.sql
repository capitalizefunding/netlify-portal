/*
  # Fix registration process

  1. Changes
    - Update handle_new_user function to properly handle registration errors
    - Add better error handling and validation
    - Ensure proper transaction handling
*/

-- First drop existing trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Drop existing function
DROP FUNCTION IF EXISTS handle_new_user();

-- Create improved handle_new_user function with better error handling
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER 
SECURITY DEFINER -- Run with elevated privileges
AS $$
DECLARE
  trimmed_company_name text;
  trimmed_first_name text;
  trimmed_last_name text;
  trimmed_phone text;
BEGIN
  -- Get and trim values
  trimmed_company_name := trim(NEW.raw_user_meta_data->>'company_name');
  trimmed_first_name := trim(NEW.raw_user_meta_data->>'first_name');
  trimmed_last_name := trim(NEW.raw_user_meta_data->>'last_name');
  trimmed_phone := trim(NEW.raw_user_meta_data->>'phone');

  -- Basic validation
  IF trimmed_company_name IS NULL OR trimmed_company_name = '' THEN
    RAISE EXCEPTION 'Company name is required';
  END IF;

  IF trimmed_first_name IS NULL OR trimmed_first_name = '' THEN
    RAISE EXCEPTION 'First name is required';
  END IF;

  IF trimmed_last_name IS NULL OR trimmed_last_name = '' THEN
    RAISE EXCEPTION 'Last name is required';
  END IF;

  IF trimmed_phone IS NULL OR trimmed_phone = '' THEN
    RAISE EXCEPTION 'Phone number is required';
  END IF;

  -- Delete any existing partner record to avoid conflicts
  DELETE FROM public.partners WHERE id = NEW.id;

  -- Insert new partner record
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
    trimmed_first_name,
    trimmed_last_name,
    trimmed_company_name,
    trimmed_phone
  );

  RETURN NEW;

EXCEPTION WHEN OTHERS THEN
  -- Log the error with context
  RAISE LOG 'Error in handle_new_user for user % (email: %): %, SQLSTATE: %', 
    NEW.id, NEW.email, SQLERRM, SQLSTATE;
  
  -- Re-raise the error with a user-friendly message
  RAISE EXCEPTION 'Failed to create partner profile. Please try again.';
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();