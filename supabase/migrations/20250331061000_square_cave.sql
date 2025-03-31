/*
  # Fix user registration and partner creation

  1. Changes
    - Drop existing triggers and functions
    - Recreate handle_new_user function with better error handling
    - Add validation for required metadata fields
    - Ensure proper partner record creation
*/

-- First drop existing trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Drop existing function
DROP FUNCTION IF EXISTS handle_new_user();

-- Create improved handle_new_user function
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Validate required metadata fields
  IF NEW.raw_user_meta_data IS NULL THEN
    RAISE LOG 'Missing user metadata for user %', NEW.id;
    RETURN NEW;
  END IF;

  IF NEW.raw_user_meta_data->>'company_name' IS NULL THEN
    RAISE LOG 'Missing company_name in metadata for user %', NEW.id;
    RETURN NEW;
  END IF;

  -- Insert or update partner record
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
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    company_name = EXCLUDED.company_name,
    phone = EXCLUDED.phone,
    updated_at = now();

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log any errors but don't prevent user creation
  RAISE LOG 'Error in handle_new_user for user %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Ensure RLS policies are correct
DROP POLICY IF EXISTS "Partners can view their own profile" ON public.partners;
DROP POLICY IF EXISTS "Partners can update their own profile" ON public.partners;

CREATE POLICY "Partners can view their own profile"
  ON public.partners
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Partners can update their own profile"
  ON public.partners
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);