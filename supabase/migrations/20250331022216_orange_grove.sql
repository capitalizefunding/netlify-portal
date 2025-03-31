/*
  # Create partners table and enhance user profiles

  1. New Tables
    - `partners`
      - `id` (uuid, primary key, references auth.users)
      - `company_name` (text)
      - `status` (text) - active/inactive
      - `total_referrals` (integer)
      - `total_commission` (numeric)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on `partners` table
    - Add policies for authenticated users to read their own data
    - Add trigger to create partner profile on user registration

  3. Changes
    - Add trigger to update partner statistics when referrals change
*/

-- Create partners table
CREATE TABLE partners (
  id uuid PRIMARY KEY REFERENCES auth.users,
  company_name text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  total_referrals integer DEFAULT 0,
  total_commission numeric DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE partners ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Partners can view their own profile"
  ON partners
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_partner_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_partners_updated_at
  BEFORE UPDATE ON partners
  FOR EACH ROW
  EXECUTE FUNCTION update_partner_updated_at_column();

-- Create function to create partner profile on user registration
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.partners (id, company_name)
  VALUES (NEW.id, (NEW.raw_user_meta_data->>'company_name')::text);
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically create partner profile
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Create function to update partner statistics
CREATE OR REPLACE FUNCTION update_partner_statistics()
RETURNS TRIGGER AS $$
BEGIN
  -- Update total_referrals and total_commission for the partner
  UPDATE partners
  SET 
    total_referrals = (
      SELECT COUNT(*)
      FROM referrals
      WHERE partner_id = NEW.partner_id
    ),
    total_commission = (
      SELECT COALESCE(SUM(commission_amount), 0)
      FROM referrals
      WHERE partner_id = NEW.partner_id
        AND status = 'approved'
        AND commission_amount IS NOT NULL
    )
  WHERE id = NEW.partner_id;
  
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update partner statistics
CREATE TRIGGER update_partner_stats
  AFTER INSERT OR UPDATE OF status, commission_amount
  ON referrals
  FOR EACH ROW
  EXECUTE FUNCTION update_partner_statistics();