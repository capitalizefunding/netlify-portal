/*
  # Fix partner registration

  1. Changes
    - Update handle_new_user function to properly handle email and company name
    - Add better error handling and logging
    - Ensure partner record is created for new users
    - Fix issue with email not being stored

  2. Security
    - Maintain existing RLS policies
    - No changes to table permissions
*/

-- Update handle_new_user function with improved error handling and email handling
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

  -- Validate email exists
  IF NEW.email IS NULL OR trim(NEW.email) = '' THEN
    RAISE EXCEPTION 'Email is required and cannot be empty';
  END IF;

  -- Use a transaction to ensure atomicity
  BEGIN
    -- Delete any existing partner record (cleanup)
    DELETE FROM public.partners WHERE id = NEW.id OR email = NEW.email;

    -- Insert new partner with email
    INSERT INTO public.partners (id, company_name, email)
    VALUES (
      NEW.id,
      trim(company_name_value),
      NEW.email
    );
  EXCEPTION WHEN unique_violation THEN
    RAISE EXCEPTION 'A partner with this email already exists';
  END;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log the error with detailed context
  RAISE LOG 'Error in handle_new_user for user % (email: %): %, SQLSTATE: %', 
    NEW.id, NEW.email, SQLERRM, SQLSTATE;
  RAISE; -- Re-raise the error to prevent invalid state
END;
$$ language 'plpgsql';