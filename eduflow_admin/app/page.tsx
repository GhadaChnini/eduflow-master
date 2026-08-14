'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import MessagesTab from '@/components/MessagesTab';
import ApplicationsTab from '@/components/ApplicationsTab';
import UsersTab from '@/components/UsersTab';
import UnitsTab from '@/components/UnitsTab';
import NotificationsTab from '@/components/NotificationsTab';
import RevenueTab from '@/components/RevenueTab';

export default function AdminDashboard() {
  const router = useRouter();
  const [activeTab, setActiveTab] = useState('applications');
  const [stats, setStats] = useState({ users: 0, teachers: 0, students: 0, units: 0, pending: 0, eduflowRevenue: 0 });

  useEffect(() => { fetchStats(); }, []);

  const fetchStats = async () => {
    const res = await fetch('/api/stats');
    const data = await res.json();
    setStats(data);
  };

  const handleLogout = () => {
    document.cookie = 'admin_token=; path=/; max-age=0';
    router.push('/login');
  };

  const tabs = [
    { id: 'applications', label: 'Applications', icon: '📋', badge: stats.pending },
    { id: 'users', label: 'Users', icon: '👥' },
    { id: 'units', label: 'Units', icon: '📚' },
    { id: 'messages', label: 'Messages', icon: '💬' },
    { id: 'notifications', label: 'Notifications', icon: '🔔' },
    { id: 'revenue', label: 'Revenue', icon: '💰' },
  ];

  const statCards = [
    { label: 'Total Users', value: stats.users, icon: '👥', bg: 'from-purple-500 to-purple-600' },
    { label: 'Teachers', value: stats.teachers, icon: '👩‍🏫', bg: 'from-blue-500 to-blue-600' },
    { label: 'Students', value: stats.students, icon: '🎓', bg: 'from-emerald-500 to-emerald-600' },
    { label: 'Units', value: stats.units, icon: '📚', bg: 'from-amber-500 to-amber-600' },
    { label: 'Pending', value: stats.pending, icon: '⏳', bg: 'from-red-500 to-red-600' },
  ];

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      {/* Header */}
      <header className="bg-gradient-to-r from-purple-700 to-purple-900 text-white px-8 py-4 flex items-center justify-between shadow-lg">
        <div className="flex items-center gap-4">
          <div className="w-10 h-10 bg-white/20 rounded-2xl flex items-center justify-center backdrop-blur">
            <span className="text-xl">🌟</span>
          </div>
          <div>
            <h1 className="text-xl font-bold tracking-tight">EduFlow Admin</h1>
            <p className="text-purple-200 text-xs">Control Panel · لوحة التحكم</p>
          </div>
        </div>
        <button onClick={handleLogout}
          className="flex items-center gap-2 bg-white/10 hover:bg-white/20 backdrop-blur px-4 py-2 rounded-xl text-sm font-medium transition-all border border-white/20">
          <span>🚪</span> Logout
        </button>
      </header>

      {/* Stats */}
      <div className="px-8 py-6 grid grid-cols-2 md:grid-cols-6 gap-4">
        {statCards.map((s) => (
          <div key={s.label} className={`bg-gradient-to-br ${s.bg} rounded-2xl p-5 text-white shadow-md`}>
            <div className="text-3xl mb-2">{s.icon}</div>
            <div className="text-3xl font-bold">{s.value}</div>
            <div className="text-white/80 text-xs mt-1">{s.label}</div>
          </div>
        ))}
      </div>

      {/* Tab Bar */}
      <div className="px-8">
        <div className="flex gap-1 bg-white rounded-2xl p-1 shadow-sm border border-gray-100 w-fit">
          {tabs.map((tab) => (
            <button key={tab.id} onClick={() => setActiveTab(tab.id)}
              className={`relative flex items-center gap-2 px-5 py-2.5 rounded-xl text-sm font-medium transition-all ${
                activeTab === tab.id
                  ? 'bg-purple-600 text-white shadow-md'
                  : 'text-gray-500 hover:text-gray-800 hover:bg-gray-50'
              }`}>
              <span>{tab.icon}</span>
              <span>{tab.label}</span>
              {tab.badge ? (
                <span className="absolute -top-1.5 -right-1.5 bg-red-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center font-bold shadow">
                  {tab.badge}
                </span>
              ) : null}
            </button>
          ))}
        </div>
      </div>

      {/* Content */}
      <div className="px-8 py-6 flex-1">
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 min-h-[400px]">
          {activeTab === 'applications' && <ApplicationsTab onUpdate={fetchStats} />}
          {activeTab === 'users' && <UsersTab />}
          {activeTab === 'units' && <UnitsTab />}
          {activeTab === 'messages' && <MessagesTab />}
          {activeTab === 'notifications' && <NotificationsTab />}
          {activeTab === 'revenue' && <RevenueTab />}
        </div>
      </div>
    </div>
  );
} 