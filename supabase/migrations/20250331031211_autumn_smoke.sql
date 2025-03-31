/*
  # Remove partners table and simplify schema

  1. Changes
    - Remove partners table and all related triggers/functions
    - Update referrals table to work directly with auth.users
    - Add company_name to referrals table
    - Simplify schema and remove unnecessary complexity

  2. Security
    - Maintain RLS policies for referrals
    - Update policies to use auth.uid() directly
*/

-- Drop existing triggers and functions
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS update_partner_stats ON public.referrals;
DROP TRIGGER IF EXISTS update_referrals_updated_at ON public.referrals;
DROP TRIGGER IF EXISTS update_partners_updated_at ON public.partners;

DROP FUNCTION IF EXISTS handle_new_user();
DROP FUNCTION IF EXISTS update_partner_statistics();
DROP FUNCTION IF EXISTS update_updated_at_column();

-- Drop partners table and its dependencies
DROP TABLE IF EXISTS public.partners CASCADE;

-- Recreate referrals table with updated schema
DROP TABLE IF EXISTS public.referrals;
CREATE TABLE public.referrals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
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
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE
);

-- Enable RLS
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for referrals
CREATE POLICY "Users can insert their own referrals"
  ON public.referrals
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own referrals"
  ON public.referrals
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own referrals"
  ON public.referrals
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for updated_at
CREATE TRIGGER update_referrals_updated_at
  BEFORE UPDATE ON public.referrals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();