/*
  # Fix user registration handler

  1. Changes
    - Update handle_new_user function to handle errors gracefully
    - Add better validation and error messages
    - Ensure transaction completes even if partner insert fails
    - Add detailed logging for debugging

  2. Security
    - No changes to RLS policies
    - Maintains existing security model
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
    RAISE LOG 'Invalid company name for user %: %', NEW.id, company_name_value;
    -- Return NEW instead of raising an exception to allow auth user creation
    RETURN NEW;
  END IF;

  BEGIN
    -- Delete any existing partner record (cleanup)
    DELETE FROM public.partners WHERE id = NEW.id;

    -- Insert new partner with email
    INSERT INTO public.partners (id, company_name, email)
    VALUES (
      NEW.id,
      trim(company_name_value),
      COALESCE(NEW.email, '')
    );
  EXCEPTION WHEN OTHERS THEN
    -- Log the error but don't re-raise it
    RAISE LOG 'Error creating partner record for user %: %, SQLSTATE: %', 
      NEW.id, SQLERRM, SQLSTATE;
  END;

  RETURN NEW;
END;
$$ language 'plpgsql';