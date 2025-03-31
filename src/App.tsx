import React, { useState } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import Register from './pages/Register';
import Dashboard from './pages/Dashboard';
import NewReferral from './pages/NewReferral';
import ReferralHistory from './pages/ReferralHistory';
import { AuthProvider, useAuth } from './context/AuthContext';

function PrivateRoute({ children }: { children: React.ReactNode }) {
  const { isAuthenticated } = useAuth();
  return isAuthenticated ? <>{children}</> : <Navigate to="/login" />;
}

function App() {
  return (
    <AuthProvider>
      <div className="min-h-screen bg-[#FFFFFE]">
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route path="/dashboard" element={
            <PrivateRoute>
              <Dashboard />
            </PrivateRoute>
          } />
          <Route path="/new-referral" element={
            <PrivateRoute>
              <NewReferral />
            </PrivateRoute>
          } />
          <Route path="/history" element={
            <PrivateRoute>
              <ReferralHistory />
            </PrivateRoute>
          } />
          <Route path="/" element={<Navigate to="/login" />} />
        </Routes>
      </div>
    </AuthProvider>
  );
}

export default App;