import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Leaf, ArrowLeft } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../context/AuthContext';

interface ReferralForm {
  businessName: string;
  contactName: string;
  email: string;
  phone: string;
  monthlyRevenue: string;
  fundingAmount: string;
  businessType: string;
  timeInBusiness: string;
  notes: string;
}

export default function NewReferral() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [formData, setFormData] = useState<ReferralForm>({
    businessName: '',
    contactName: '',
    email: '',
    phone: '',
    monthlyRevenue: '',
    fundingAmount: '',
    businessType: '',
    timeInBusiness: '',
    notes: ''
  });
  const [error, setError] = useState<string | null>(null);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (!user) throw new Error('Not authenticated');

      const { error: submitError } = await supabase
        .from('referrals')
        .insert([
          {
            partner_id: user.id,
            business_name: formData.businessName,
            contact_name: formData.contactName,
            email: formData.email,
            phone: formData.phone,
            monthly_revenue: parseFloat(formData.monthlyRevenue.replace(/[^0-9.]/g, '')),
            funding_amount: parseFloat(formData.fundingAmount.replace(/[^0-9.]/g, '')),
            business_type: formData.businessType,
            time_in_business: formData.timeInBusiness,
            notes: formData.notes,
            status: 'pending'
          }
        ]);

      if (submitError) throw submitError;
      navigate('/dashboard');
    } catch (error) {
      console.error('Submission failed:', error);
      setError('Failed to submit referral. Please try again.');
    }
  };

  return (
    <div className="min-h-screen bg-[#FFFFFE]">
      <nav className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center">
              <Leaf className="h-8 w-8 text-[#6AB235]" />
              <span className="ml-2 text-xl font-bold">Partner Portal</span>
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <button
          onClick={() => navigate('/dashboard')}
          className="flex items-center text-gray-600 hover:text-gray-900 mb-6"
        >
          <ArrowLeft className="h-5 w-5 mr-2" />
          Back to Dashboard
        </button>

        <h1 className="text-3xl font-bold text-black mb-8">
          Submit a New <span className="text-[#6AB235]">Referral</span>
        </h1>

        {error && (
          <div className="mb-4 p-4 bg-red-50 text-red-700 rounded-lg">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="bg-white p-6 rounded-lg shadow-sm space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label htmlFor="businessName" className="block text-sm font-bold text-black mb-2">
                Business Name
              </label>
              <input
                type="text"
                id="businessName"
                name="businessName"
                value={formData.businessName}
                onChange={handleChange}
                required
                className="input-field"
              />
            </div>

            <div>
              <label htmlFor="contactName" className="block text-sm font-bold text-black mb-2">
                Contact Name
              </label>
              <input
                type="text"
                id="contactName"
                name="contactName"
                value={formData.contactName}
                onChange={handleChange}
                required
                className="input-field"
              />
            </div>

            <div>
              <label htmlFor="email" className="block text-sm font-bold text-black mb-2">
                Email Address
              </label>
              <input
                type="email"
                id="email"
                name="email"
                value={formData.email}
                onChange={handleChange}
                required
                className="input-field"
              />
            </div>

            <div>
              <label htmlFor="phone" className="block text-sm font-bold text-black mb-2">
                Phone Number
              </label>
              <input
                type="tel"
                id="phone"
                name="phone"
                value={formData.phone}
                onChange={handleChange}
                required
                className="input-field"
              />
            </div>

            <div>
              <label htmlFor="monthlyRevenue" className="block text-sm font-bold text-black mb-2">
                Monthly Revenue
              </label>
              <input
                type="text"
                id="monthlyRevenue"
                name="monthlyRevenue"
                value={formData.monthlyRevenue}
                onChange={handleChange}
                required
                className="input-field"
                placeholder="$"
              />
            </div>

            <div>
              <label htmlFor="fundingAmount" className="block text-sm font-bold text-black mb-2">
                Desired Funding Amount
              </label>
              <input
                type="text"
                id="fundingAmount"
                name="fundingAmount"
                value={formData.fundingAmount}
                onChange={handleChange}
                required
                className="input-field"
                placeholder="$"
              />
            </div>

            <div>
              <label htmlFor="businessType" className="block text-sm font-bold text-black mb-2">
                Business Type
              </label>
              <select
                id="businessType"
                name="businessType"
                value={formData.businessType}
                onChange={handleChange}
                required
                className="input-field"
              >
                <option value="">Select business type</option>
                <option value="retail">Retail</option>
                <option value="restaurant">Restaurant</option>
                <option value="service">Service</option>
                <option value="manufacturing">Manufacturing</option>
                <option value="other">Other</option>
              </select>
            </div>

            <div>
              <label htmlFor="timeInBusiness" className="block text-sm font-bold text-black mb-2">
                Time in Business
              </label>
              <select
                id="timeInBusiness"
                name="timeInBusiness"
                value={formData.timeInBusiness}
                onChange={handleChange}
                required
                className="input-field"
              >
                <option value="">Select time in business</option>
                <option value="0-6">0-6 months</option>
                <option value="6-12">6-12 months</option>
                <option value="1-2">1-2 years</option>
                <option value="2-5">2-5 years</option>
                <option value="5+">5+ years</option>
              </select>
            </div>
          </div>

          <div>
            <label htmlFor="notes" className="block text-sm font-bold text-black mb-2">
              Additional Notes
            </label>
            <textarea
              id="notes"
              name="notes"
              value={formData.notes}
              onChange={handleChange}
              rows={4}
              className="input-field"
              placeholder="Any additional information about the business..."
            />
          </div>

          <div className="flex justify-end">
            <button type="submit" className="btn-primary">
              Submit Referral
            </button>
          </div>
        </form>
      </main>
    </div>
  );
}