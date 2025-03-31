import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Leaf, PlusCircle, History, LogOut } from 'lucide-react';
import { supabase } from '../lib/supabase';

interface Stats {
  total_referrals: number;
  total_commission: number;
  pending_referrals: number;
}

export default function Dashboard() {
  const { logout, user } = useAuth();
  const [stats, setStats] = useState<Stats>({
    total_referrals: 0,
    total_commission: 0,
    pending_referrals: 0
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        if (!user) return;

        // Get total referrals count
        const { count: totalCount, error: totalError } = await supabase
          .from('referrals')
          .select('*', { count: 'exact', head: true })
          .eq('partner_id', user.id);

        if (totalError) throw totalError;

        // Get pending referrals count
        const { count: pendingCount, error: pendingError } = await supabase
          .from('referrals')
          .select('*', { count: 'exact', head: true })
          .eq('partner_id', user.id)
          .eq('status', 'pending');

        if (pendingError) throw pendingError;

        // Calculate total commission
        const { data: commissionData, error: commissionError } = await supabase
          .from('referrals')
          .select('commission_amount')
          .eq('partner_id', user.id)
          .eq('status', 'approved');

        if (commissionError) throw commissionError;

        const totalCommission = commissionData.reduce((sum, referral) => 
          sum + (referral.commission_amount || 0), 0);

        setStats({
          total_referrals: totalCount || 0,
          total_commission: totalCommission,
          pending_referrals: pendingCount || 0
        });
      } catch (err) {
        console.error('Error fetching stats:', err);
        setError('Failed to load dashboard statistics');
      } finally {
        setLoading(false);
      }
    };

    fetchStats();
  }, [user]);

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount);
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
            <button
              onClick={logout}
              className="flex items-center text-gray-600 hover:text-gray-900"
            >
              <LogOut className="h-5 w-5 mr-2" />
              Sign Out
            </button>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <h1 className="text-3xl font-bold text-black mb-8">
          Welcome to your <span className="text-[#6AB235]">Partner Dashboard</span>
        </h1>

        {error && (
          <div className="mb-8 p-4 bg-red-50 text-red-700 rounded-lg">
            {error}
          </div>
        )}

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <Link
            to="/new-referral"
            className="bg-white p-6 rounded-lg shadow-sm hover:shadow-md transition-shadow"
          >
            <div className="flex items-center mb-4">
              <PlusCircle className="h-8 w-8 text-[#6AB235]" />
              <h2 className="text-xl font-bold ml-3">New Referral</h2>
            </div>
            <p className="text-gray-600">
              Submit a new funding application for your client
            </p>
          </Link>

          <Link
            to="/history"
            className="bg-white p-6 rounded-lg shadow-sm hover:shadow-md transition-shadow"
          >
            <div className="flex items-center mb-4">
              <History className="h-8 w-8 text-[#6AB235]" />
              <h2 className="text-xl font-bold ml-3">Referral History</h2>
            </div>
            <p className="text-gray-600">
              Track your referrals and commission status
            </p>
          </Link>
        </div>

        <div className="mt-12 bg-white p-6 rounded-lg shadow-sm">
          <h2 className="text-xl font-bold mb-4">Quick Stats</h2>
          {loading ? (
            <div className="flex justify-center items-center h-32">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#6AB235]"></div>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="p-4 bg-gray-50 rounded-lg">
                <p className="text-sm text-gray-600">Total Referrals</p>
                <p className="text-2xl font-bold">{stats.total_referrals}</p>
              </div>
              <div className="p-4 bg-gray-50 rounded-lg">
                <p className="text-sm text-gray-600">Pending Applications</p>
                <p className="text-2xl font-bold">{stats.pending_referrals}</p>
              </div>
              <div className="p-4 bg-gray-50 rounded-lg">
                <p className="text-sm text-gray-600">Total Commission</p>
                <p className="text-2xl font-bold">{formatCurrency(stats.total_commission)}</p>
              </div>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}