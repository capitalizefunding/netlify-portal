import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Leaf } from 'lucide-react';

export default function Register() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [companyName, setCompanyName] = useState('');
  const [phone, setPhone] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const { register } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);
    setIsLoading(true);

    try {
      await register(email, password, firstName, lastName, companyName, phone);
      setSuccess('Registration successful! Please check your email to confirm your account.');
      // Don't navigate immediately - let user see the success message
    } catch (error) {
      console.error('Registration failed:', error);
      const message = error instanceof Error ? error.message : 'Failed to create account. Please try again.';
      if (message.includes('Please check your email')) {
        setSuccess(message);
      } else {
        setError(message);
      }
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
            Join our <span className="text-[#6AB235]">Partner Network</span>
          </h2>
          <p className="mt-2 text-black">Create your partner account</p>
        </div>

        {error && (
          <div className="p-4 bg-red-50 text-red-700 rounded-lg text-sm">
            {error}
          </div>
        )}

        {success && (
          <div className="p-4 bg-green-50 text-green-700 rounded-lg text-sm">
            {success}
          </div>
        )}

        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          <div className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label htmlFor="firstName" className="block text-sm font-bold text-black">
                  First Name
                </label>
                <input
                  id="firstName"
                  type="text"
                  required
                  className="input-field"
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  disabled={isLoading}
                />
              </div>
              <div>
                <label htmlFor="lastName" className="block text-sm font-bold text-black">
                  Last Name
                </label>
                <input
                  id="lastName"
                  type="text"
                  required
                  className="input-field"
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  disabled={isLoading}
                />
              </div>
            </div>
            <div>
              <label htmlFor="companyName" className="block text-sm font-bold text-black">
                Company Name
              </label>
              <input
                id="companyName"
                type="text"
                required
                className="input-field"
                value={companyName}
                onChange={(e) => setCompanyName(e.target.value)}
                disabled={isLoading}
              />
            </div>
            <div>
              <label htmlFor="phone" className="block text-sm font-bold text-black">
                Phone Number
              </label>
              <input
                id="phone"
                type="tel"
                required
                className="input-field"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                disabled={isLoading}
              />
            </div>
            <div>
              <label htmlFor="email" className="block text-sm font-bold text-black">
                Email Address
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
                minLength={6}
              />
              <p className="mt-1 text-sm text-gray-500">
                Password must be at least 6 characters long
              </p>
            </div>
          </div>

          <div>
            <button
              type="submit"
              className="btn-primary w-full relative"
              disabled={isLoading || success !== null}
            >
              {isLoading ? (
                <span className="flex items-center justify-center">
                  <span className="animate-spin h-5 w-5 mr-3 border-2 border-black border-t-transparent rounded-full"></span>
                  Creating account...
                </span>
              ) : success ? (
                'Check your email'
              ) : (
                'Create Account'
              )}
            </button>
          </div>
        </form>

        <p className="text-center text-black">
          Already have an account?{' '}
          <Link to="/login" className="text-[#6AB235] font-bold hover:underline">
            Sign in here
          </Link>
        </p>
      </div>
    </div>
  );
}