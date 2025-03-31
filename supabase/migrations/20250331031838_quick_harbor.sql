/*
  # Create Partners Table with Registration Info

  1. New Tables
    - `partners` table with:
      - `id` (uuid, primary key)
      - `email` (text, unique)
      - `first_name` (text)
      - `last_name` (text)
      - `company_name` (text)
      - `phone` (text)
      - `status` (text)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on partners table
    - Add policies for authenticated users
    - Link partners to auth.users

  3. Changes
    - Update referrals table to use partner_id
    - Add foreign key constraints
*/

-- Create partners table
CREATE TABLE public.partners (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  first_name text,
  last_name text,
  company_name text NOT NULL,
  phone text,
  status text NOT NULL DEFAULT 'active',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.partners ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
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

-- Update referrals table
ALTER TABLE public.referrals
  DROP CONSTRAINT IF EXISTS fk_user,
  DROP CONSTRAINT IF EXISTS referrals_user_id_fkey,
  ALTER COLUMN user_id SET NOT NULL,
  ALTER COLUMN user_id TYPE uuid,
  ALTER COLUMN user_id SET DEFAULT auth.uid(),
  ADD CONSTRAINT fk_partner FOREIGN KEY (user_id) REFERENCES public.partners(id) ON DELETE CASCADE;

-- Create trigger function for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for partners updated_at
CREATE TRIGGER update_partners_updated_at
  BEFORE UPDATE ON public.partners
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to handle new user registration
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Get metadata values
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
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'Error in handle_new_user: %', SQLERRM;
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for new user registration
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();