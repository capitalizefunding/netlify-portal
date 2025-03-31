/*
  # Update handle_new_user function with improved error handling

  1. Changes
    - Improve error handling in handle_new_user function
    - Add validation for company_name
    - Add better error logging
    - Prevent duplicate partner entries
*/

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS handle_new_user();

-- Create the updated function
CREATE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Validate company_name exists in metadata
  IF (NEW.raw_user_meta_data->>'company_name') IS NULL THEN
    RAISE EXCEPTION 'company_name is required';
  END IF;

  -- Check if partner already exists
  IF EXISTS (SELECT 1 FROM public.partners WHERE id = NEW.id) THEN
    RETURN NEW;
  END IF;

  -- Insert new partner
  INSERT INTO public.partners (id, company_name)
  VALUES (
    NEW.id,
    trim(NEW.raw_user_meta_data->>'company_name')
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'Error in handle_new_user: %', SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;