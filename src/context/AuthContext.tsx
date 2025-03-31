import React, { createContext, useContext, useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { User } from '@supabase/supabase-js';

interface AuthContextType {
  isAuthenticated: boolean;
  user: User | null;
  login: (email: string, password: string) => Promise<void>;
  register: (email: string, password: string, firstName: string, lastName: string, companyName: string, phone: string) => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    // Check current session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setIsAuthenticated(!!session);
      setUser(session?.user ?? null);
    });

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setIsAuthenticated(!!session);
      setUser(session?.user ?? null);
    });

    return () => subscription.unsubscribe();
  }, []);

  const login = async (email: string, password: string) => {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      if (error.message === 'Invalid login credentials') {
        throw new Error('Invalid email or password. Please check your credentials and try again.');
      }
      throw new Error(error.message);
    }

    if (!data.user) {
      throw new Error('Login failed. Please try again.');
    }
  };

  const register = async (
    email: string,
    password: string,
    firstName: string,
    lastName: string,
    companyName: string,
    phone: string
  ) => {
    // Validate required fields
    if (!email.trim()) throw new Error('Email is required');
    if (!password.trim()) throw new Error('Password is required');
    if (!firstName.trim()) throw new Error('First name is required');
    if (!lastName.trim()) throw new Error('Last name is required');
    if (!companyName.trim()) throw new Error('Company name is required');
    if (!phone.trim()) throw new Error('Phone number is required');

    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          first_name: firstName.trim(),
          last_name: lastName.trim(),
          company_name: companyName.trim(),
          phone: phone.trim()
        },
      },
    });

    if (error) {
      if (error.message.includes('User already registered')) {
        throw new Error('This email is already registered. Please use a different email or try logging in.');
      }
      throw new Error(error.message);
    }

    if (!data.user) {
      throw new Error('Registration failed. Please try again.');
    }
  };

  const logout = async () => {
    const { error } = await supabase.auth.signOut();
    if (error) {
      throw new Error('Failed to log out. Please try again.');
    }
  };

  return (
    <AuthContext.Provider value={{ isAuthenticated, user, login, register, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}