'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

const ADMIN_EMAIL = 'admin@eduflow.com';
const ADMIN_PASSWORD = 'eduflow_admin_2024';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    if (email === ADMIN_EMAIL && password === ADMIN_PASSWORD) {
      document.cookie = 'admin_token=eduflow_admin; path=/; max-age=86400';
      router.push('/');
    } else {
      setError('Invalid credentials');
    }
    setLoading(false);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-50 to-purple-100 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-xl p-8 w-full max-w-md border-4 border-purple-200">
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-purple-600 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <span className="text-3xl">🌟</span>
          </div>
          <h1 className="text-2xl font-bold text-purple-900">EduFlow Admin</h1>
          <p className="text-purple-600 text-sm mt-1">لوحة تحكم المسؤول</p>
        </div>

        <form onSubmit={handleLogin} className="space-y-4">
          <div>
            <label className="block text-sm font-bold text-purple-700 mb-2">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full border-2 border-purple-200 rounded-xl px-4 py-3 focus:outline-none focus:border-purple-500"
              placeholder="admin@eduflow.com"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-bold text-purple-700 mb-2">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full border-2 border-purple-200 rounded-xl px-4 py-3 focus:outline-none focus:border-purple-500"
              placeholder="••••••••"
              required
            />
          </div>

          {error && (
            <div className="bg-red-50 border-2 border-red-200 rounded-xl p-3 text-red-600 text-sm">
              ⚠️ {error}
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-purple-600 text-white rounded-full py-3 font-bold hover:bg-purple-700 transition disabled:opacity-60"
          >
            {loading ? 'Signing in...' : '🚀 Sign In'}
          </button>
        </form>
      </div>
    </div>
  );
}