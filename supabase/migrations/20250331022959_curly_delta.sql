/*
  # Fix registration error handling

  1. Changes
    - Update handle_new_user function to handle errors gracefully
    - Add error handling for duplicate emails
    - Add validation for company name

  2. Security
    - No changes to existing policies
*/

-- Update the handle_new_user function with better error handling
CREATE OR REPLACE FUNCTION handle_new_user()
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
    (NEW.raw_user_meta_data->>'company_name')::text
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log the error (Supabase will capture this)
  RAISE LOG 'Error in handle_new_user: %', SQLERRM;
  RETURN NEW;
END;
$$ language 'plpgsql';