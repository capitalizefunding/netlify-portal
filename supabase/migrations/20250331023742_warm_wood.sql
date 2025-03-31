/*
  # Improve error handling for user registration

  1. Changes
    - Update handle_new_user function with better error handling
    - Add explicit validation for company_name
    - Add better error logging
    - Prevent duplicate partner entries
*/

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  company_name_value text;
BEGIN
  -- Extract and validate company_name from metadata
  company_name_value := NEW.raw_user_meta_data->>'company_name';
  
  IF company_name_value IS NULL OR trim(company_name_value) = '' THEN
    RAISE EXCEPTION 'company_name is required';
  END IF;

  -- Check if partner already exists
  IF EXISTS (SELECT 1 FROM public.partners WHERE id = NEW.id) THEN
    RETURN NEW;
  END IF;

  -- Insert new partner with validated company name
  INSERT INTO public.partners (id, company_name)
  VALUES (
    NEW.id,
    trim(company_name_value)
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log the error details
  RAISE LOG 'Error in handle_new_user for user %: %, SQLSTATE: %', NEW.id, SQLERRM, SQLSTATE;
  
  -- Re-raise the error to prevent invalid data
  RAISE;
END;
$$ language 'plpgsql' SECURITY DEFINER;