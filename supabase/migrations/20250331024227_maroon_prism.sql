/*
  # Add Email Column to Partners Table
  
  1. Changes
    - Add email column to partners table
    - Make email unique and required
    - Update handle_new_user function to store email
    
  2. Security
    - No changes to existing RLS policies needed
*/

-- Add email column to partners table
ALTER TABLE public.partners 
ADD COLUMN IF NOT EXISTS email text NOT NULL DEFAULT '';

-- Create unique index on email
CREATE UNIQUE INDEX IF NOT EXISTS partners_email_idx ON public.partners (email);

-- Update handle_new_user function to store email
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
  RETURN NEW;
END;
$$ language 'plpgsql';