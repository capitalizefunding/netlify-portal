/*
  # Create Partners Table and Update Referrals

  1. New Tables
    - `partners` table with fields:
      - `id` (uuid, primary key) - Links to auth.users
      - `email` (text, unique)
      - `first_name` (text)
      - `last_name` (text)
      - `company_name` (text)
      - `phone` (text)
      - `status` (text) - Partner status (active/inactive)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Changes
    - Drop existing referrals table and recreate with partner_id reference
    - Update triggers and functions for partner management

  3. Security
    - Enable RLS on partners table
    - Add policies for partner data access
*/

-- First drop existing tables and dependencies
DROP TRIGGER IF EXISTS update_referrals_updated_at ON public.referrals;
DROP FUNCTION IF EXISTS update_updated_at_column();
DROP TABLE IF EXISTS public.referrals;

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

-- Create referrals table with partner_id reference
CREATE TABLE public.referrals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id uuid NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
  business_name text NOT NULL,
  contact_name text NOT NULL,
  email text NOT NULL,
  phone text NOT NULL,
  monthly_revenue numeric NOT NULL,
  funding_amount numeric NOT NULL,
  business_type text NOT NULL,
  time_in_business text NOT NULL,
  notes text,
  status text NOT NULL DEFAULT 'pending',
  commission_amount numeric,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for partners
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

-- Create RLS policies for referrals
CREATE POLICY "Partners can insert their own referrals"
  ON public.referrals
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = partner_id);

CREATE POLICY "Partners can update their own referrals"
  ON public.referrals
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = partner_id);

CREATE POLICY "Partners can view their own referrals"
  ON public.referrals
  FOR SELECT
  TO authenticated
  USING (auth.uid() = partner_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_referrals_updated_at
  BEFORE UPDATE ON public.referrals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

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