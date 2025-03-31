/*
  # Clear all data and reset tables

  1. Changes
    - Delete all existing data from referrals and partners tables
    - Delete all auth users
    - Reset sequences
*/

-- First delete all referrals
TRUNCATE TABLE public.referrals CASCADE;

-- Then delete all partners
TRUNCATE TABLE public.partners CASCADE;

-- Finally delete auth users
DELETE FROM auth.users;

-- Reset sequences if any exist
ALTER SEQUENCE IF EXISTS referrals_id_seq RESTART;