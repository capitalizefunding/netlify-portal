/*
  # Create referrals table and policies

  1. New Tables
    - `referrals`
      - `id` (uuid, primary key)
      - `partner_id` (uuid, references auth.users)
      - `business_name` (text)
      - `contact_name` (text)
      - `email` (text)
      - `phone` (text)
      - `monthly_revenue` (numeric)
      - `funding_amount` (numeric)
      - `business_type` (text)
      - `time_in_business` (text)
      - `notes` (text)
      - `status` (text)
      - `commission_amount` (numeric)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `referrals` table
    - Add policies for partners to:
      - Insert their own referrals
      - Read their own referrals
      - Update notes on their own referrals
*/

CREATE TABLE referrals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id uuid REFERENCES auth.users NOT NULL,
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

ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;

-- Allow partners to insert their own referrals
CREATE POLICY "Partners can insert their own referrals"
  ON referrals
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = partner_id);

-- Allow partners to read their own referrals
CREATE POLICY "Partners can view their own referrals"
  ON referrals
  FOR SELECT
  TO authenticated
  USING (auth.uid() = partner_id);

-- Allow partners to update notes on their own referrals
CREATE POLICY "Partners can update notes on their own referrals"
  ON referrals
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = partner_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_referrals_updated_at
  BEFORE UPDATE ON referrals
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();