import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Leaf } from 'lucide-react';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setIsLoading(true);

    try {
      await login(email, password);
      navigate('/dashboard');
    } catch (error) {
      console.error('Login failed:', error);
      setError(error instanceof Error ? error.message : 'Failed to sign in. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#FFFFFE] px-4">
      <div className="max-w-md w-full space-y-8">
        <div className="text-center">
          <Leaf className="mx-auto h-12 w-12 text-[#6AB235]" />
          <h2 className="mt-6 text-3xl font-bold text-black">
            Welcome to <span className="text-[#6AB235]">Partner Portal</span>
          </h2>
          <p className="mt-2 text-black">Sign in to your account</p>
        </div>

        {error && (
          <div className="p-4 bg-red-50 text-red-700 rounded-lg text-sm">
            {error}
          </div>
        )}

        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          <div className="space-y-4">
            <div>
              <label htmlFor="email" className="block text-sm font-bold text-black">
                Email address
              </label>
              <input
                id="email"
                type="email"
                required
                className="input-field"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                disabled={isLoading}
              />
            </div>
            <div>
              <label htmlFor="password" className="block text-sm font-bold text-black">
                Password
              </label>
              <input
                id="password"
                type="password"
                required
                className="input-field"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                disabled={isLoading}
              />
            </div>
          </div>

          <div>
            <button
              type="submit"
              className="btn-primary w-full relative"
              disabled={isLoading}
            >
              {isLoading ? (
                <span className="flex items-center justify-center">
                  <span className="animate-spin h-5 w-5 mr-3 border-2 border-black border-t-transparent rounded-full"></span>
                  Signing in...
                </span>
              ) : (
                'Sign in'
              )}
            </button>
          </div>
        </form>

        <p className="text-center text-black">
          Don't have an account?{' '}
          <Link to="/register" className="text-[#6AB235] font-bold hover:underline">
            Register here
          </Link>
        </p>
      </div>
    </div>
  );
}