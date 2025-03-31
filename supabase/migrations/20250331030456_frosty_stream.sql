/*
  # Reset Database State
  
  1. Changes
    - Delete existing auth users with cascade
    - Reset tables with proper order
    - Update handle_new_user function
    
  2. Security
    - No changes to existing RLS policies
*/

-- First delete all referrals
TRUNCATE TABLE public.referrals CASCADE;

-- Then delete all partners
TRUNCATE TABLE public.partners CASCADE;

-- Finally delete auth users
DELETE FROM auth.users;

-- Update handle_new_user function to be more robust
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Validate company_name exists in metadata
  IF (NEW.raw_user_meta_data->>'company_name') IS NULL THEN
    RAISE EXCEPTION 'company_name is required';
  END IF;

  -- Delete any existing partner record (cleanup)
  DELETE FROM public.partners WHERE id = NEW.id;

  -- Insert new partner with email
  INSERT INTO public.partners (id, company_name, email)
  VALUES (
    NEW.id,
    trim(NEW.raw_user_meta_data->>'company_name'),
    NEW.email
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'Error in handle_new_user: %', SQLERRM;
  RAISE; -- Re-raise the error to prevent invalid state
END;
$$ language 'plpgsql';