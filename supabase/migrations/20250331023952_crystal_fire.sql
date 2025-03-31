/*
  # Reset Database Tables and Functions
  
  1. Changes
    - Drop existing triggers and functions
    - Drop and recreate tables with fresh state
    - Recreate function and trigger for new user handling
    
  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
*/

-- First, drop existing triggers and functions
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS update_partner_stats ON public.referrals;
DROP TRIGGER IF EXISTS update_referrals_updated_at ON public.referrals;
DROP TRIGGER IF EXISTS update_partners_updated_at ON public.partners;

DROP FUNCTION IF EXISTS handle_new_user();
DROP FUNCTION IF EXISTS update_partner_statistics();
DROP FUNCTION IF EXISTS update_updated_at_column();
DROP FUNCTION IF EXISTS update_partner_updated_at_column();

-- Drop existing tables
DROP TABLE IF EXISTS public.referrals;
DROP TABLE IF EXISTS public.partners;

-- Recreate partners table
CREATE TABLE public.partners (
  id uuid PRIMARY KEY,
  company_name text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  total_referrals integer DEFAULT 0,
  total_commission numeric DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Recreate referrals table
CREATE TABLE public.referrals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id uuid NOT NULL REFERENCES public.partners(id),
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

-- Create RLS policies
CREATE POLICY "Partners can view their own profile"
  ON public.partners
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Partners can insert their own referrals"
  ON public.referrals
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = partner_id);

CREATE POLICY "Partners can update notes on their own referrals"
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

-- Create partner statistics update function
CREATE OR REPLACE FUNCTION update_partner_statistics()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.partners
  SET 
    total_referrals = (
      SELECT count(*)
      FROM public.referrals
      WHERE partner_id = NEW.partner_id
    ),
    total_commission = COALESCE((
      SELECT sum(commission_amount)
      FROM public.referrals
      WHERE partner_id = NEW.partner_id
      AND status = 'approved'
    ), 0),
    updated_at = now()
  WHERE id = NEW.partner_id;
  
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create handle_new_user function
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
    trim(NEW.raw_user_meta_data->>'company_name')
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'Error in handle_new_user: %', SQLERRM;
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

CREATE TRIGGER update_partner_stats
  AFTER INSERT OR UPDATE OF status, commission_amount ON public.referrals
  FOR EACH ROW EXECUTE FUNCTION update_partner_statistics();

CREATE TRIGGER update_referrals_updated_at
  BEFORE UPDATE ON public.referrals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_partners_updated_at
  BEFORE UPDATE ON public.partners
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();