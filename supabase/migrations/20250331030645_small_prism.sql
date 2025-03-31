/*
  # Fix handle_new_user trigger function

  1. Changes
    - Update handle_new_user function to properly handle errors
    - Ensure email is properly stored in partners table
    - Add better error messages for debugging
    
  2. Security
    - No changes to existing RLS policies
*/

-- Update handle_new_user function with better error handling
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  company_name_value text;
BEGIN
  -- Get company_name from metadata with better error handling
  company_name_value := NEW.raw_user_meta_data->>'company_name';
  
  -- Validate company_name exists and is not empty
  IF company_name_value IS NULL OR trim(company_name_value) = '' THEN
    RAISE EXCEPTION 'Company name is required and cannot be empty';
  END IF;

  -- Delete any existing partner record (cleanup)
  DELETE FROM public.partners WHERE id = NEW.id;

  -- Insert new partner with email
  INSERT INTO public.partners (id, company_name, email)
  VALUES (
    NEW.id,
    trim(company_name_value),
    COALESCE(NEW.email, '')
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log the error with more context
  RAISE LOG 'Error in handle_new_user for user %: %, SQLSTATE: %', NEW.id, SQLERRM, SQLSTATE;
  -- Re-raise the error to prevent invalid state
  RAISE;
END;
$$ language 'plpgsql';