'use client';
import { useState, useEffect } from 'react';

export default function NotificationsTab() {
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [target, setTarget] = useState('all');
  const [specificUser, setSpecificUser] = useState('');
  const [users, setUsers] = useState<any[]>([]);
  const [userSearch, setUserSearch] = useState('');
  const [sending, setSending] = useState(false);
  const [result, setResult] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  useEffect(() => {
    if (target === 'specific') fetchUsers();
  }, [target]);

  const fetchUsers = async () => {
    const res = await fetch('/api/admin-data?type=users&filter=all');
    const data = await res.json();
    setUsers(Array.isArray(data) ? data : []);
  };

  const filteredUsers = users.filter(u =>
    u.name?.toLowerCase().includes(userSearch.toLowerCase()) ||
    u.email?.toLowerCase().includes(userSearch.toLowerCase())
  );

  const selectedUser = users.find(u => u.id === specificUser);

  const handleSend = async () => {
    if (!title.trim() || !message.trim()) {
      setResult({ type: 'error', text: 'Title and message are required' });
      return;
    }
    if (target === 'specific' && !specificUser) {
      setResult({ type: 'error', text: 'Please select a user' });
      return;
    }
    setSending(true);
    setResult(null);
    try {
      const res = await fetch('/api/admin-data', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          type: 'send_notification',
          data: {
            title,
            title_ar: title,
            message,
            message_ar: message,
            target,
            user_id: specificUser,
          },
        }),
      });
      const data = await res.json();
      if (data.success) {
        setResult({ type: 'success', text: `Sent to ${data.sent} user${data.sent !== 1 ? 's' : ''}` });
        setTitle(''); setMessage(''); setSpecificUser(''); setUserSearch('');
      } else {
        setResult({ type: 'error', text: data.error || 'Failed to send' });
      }
    } catch (e) {
      setResult({ type: 'error', text: 'Network error' });
    }
    setSending(false);
  };

  const targetOptions = [
    { val: 'all', label: 'Everyone', icon: '🌍', desc: 'All students and teachers' },
    { val: 'students', label: 'Students', icon: '🎓', desc: 'All students only' },
    { val: 'teachers', label: 'Teachers', icon: '👩‍🏫', desc: 'All teachers only' },
    { val: 'specific', label: 'Specific User', icon: '👤', desc: 'Choose one person' },
  ];

  return (
    <div className="max-w-2xl mx-auto">
      <div className="mb-6">
        <h2 className="text-xl font-bold text-gray-900">Send Notification</h2>
        <p className="text-sm text-gray-400 mt-1">Push a notification to users in the app</p>
      </div>

      <div className="space-y-5">
        {/* Target Selection */}
        <div>
          <label className="block text-sm font-semibold text-gray-700 mb-3">Send to</label>
          <div className="grid grid-cols-2 gap-2">
            {targetOptions.map(opt => (
              <button key={opt.val} onClick={() => { setTarget(opt.val); setSpecificUser(''); setUserSearch(''); }}
                className={`flex items-center gap-3 p-3 rounded-2xl border-2 text-left transition-all ${
                  target === opt.val
                    ? 'border-purple-500 bg-purple-50'
                    : 'border-gray-100 bg-gray-50 hover:border-gray-200'
                }`}>
                <span className="text-2xl">{opt.icon}</span>
                <div>
                  <div className={`text-sm font-semibold ${target === opt.val ? 'text-purple-700' : 'text-gray-700'}`}>{opt.label}</div>
                  <div className="text-xs text-gray-400">{opt.desc}</div>
                </div>
              </button>
            ))}
          </div>
        </div>

        {/* Specific User Search */}
        {target === 'specific' && (
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-2">Select User</label>
            {selectedUser ? (
              <div className="flex items-center gap-3 p-3 bg-purple-50 border-2 border-purple-300 rounded-2xl">
                <div className="w-10 h-10 rounded-xl bg-purple-200 flex items-center justify-center font-bold text-purple-700">
                  {(selectedUser.name || '?')[0].toUpperCase()}
                </div>
                <div className="flex-1">
                  <div className="font-semibold text-gray-900">{selectedUser.name}</div>
                  <div className="text-xs text-gray-500">{selectedUser.email}</div>
                </div>
                <button onClick={() => { setSpecificUser(''); setUserSearch(''); }}
                  className="text-gray-400 hover:text-red-500 transition-colors text-xl">×</button>
              </div>
            ) : (
              <div>
                <div className="relative mb-2">
                  <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">🔍</span>
                  <input value={userSearch} onChange={e => setUserSearch(e.target.value)}
                    placeholder="Search by name or email..."
                    className="w-full border border-gray-200 rounded-xl pl-9 pr-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500" />
                </div>
                <div className="max-h-48 overflow-y-auto space-y-1 border border-gray-100 rounded-xl p-2 bg-gray-50">
                  {filteredUsers.slice(0, 20).map(u => (
                    <button key={u.id} onClick={() => setSpecificUser(u.id)}
                      className="w-full flex items-center gap-3 p-2.5 rounded-xl hover:bg-white hover:shadow-sm transition-all text-left">
                      <div className="w-8 h-8 rounded-lg bg-purple-100 flex items-center justify-center font-bold text-purple-600 text-sm flex-shrink-0">
                        {(u.name || '?')[0].toUpperCase()}
                      </div>
                      <div className="min-w-0">
                        <div className="text-sm font-medium text-gray-800 truncate">{u.name}</div>
                        <div className="text-xs text-gray-400 truncate">{u.email}</div>
                      </div>
                      <span className={`ml-auto px-2 py-0.5 rounded-lg text-xs font-medium flex-shrink-0 ${
                        u.role === 'parent' ? 'bg-blue-50 text-blue-600' : 'bg-purple-50 text-purple-600'
                      }`}>{u.role === 'parent' ? 'Student' : 'Teacher'}</span>
                    </button>
                  ))}
                  {filteredUsers.length === 0 && <p className="text-center text-sm text-gray-400 py-4">No users found</p>}
                </div>
              </div>
            )}
          </div>
        )}

        {/* Title */}
        <div>
          <label className="block text-sm font-semibold text-gray-700 mb-2">Title</label>
          <input value={title} onChange={e => setTitle(e.target.value)}
            placeholder="Notification title..."
            className="w-full border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500" />
        </div>

        {/* Message */}
        <div>
          <label className="block text-sm font-semibold text-gray-700 mb-2">Message</label>
          <textarea value={message} onChange={e => setMessage(e.target.value)}
            placeholder="Write your notification message..."
            rows={4}
            className="w-full border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500 resize-none" />
        </div>

        {/* Result */}
        {result && (
          <div className={`flex items-center gap-3 p-4 rounded-2xl text-sm font-medium ${
            result.type === 'success' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' : 'bg-red-50 text-red-700 border border-red-200'
          }`}>
            <span className="text-lg">{result.type === 'success' ? '✓' : '✕'}</span>
            {result.text}
          </div>
        )}

        {/* Send Button */}
        <button onClick={handleSend} disabled={sending}
          className="w-full py-3.5 bg-gradient-to-r from-purple-600 to-purple-700 text-white rounded-2xl font-semibold hover:from-purple-700 hover:to-purple-800 disabled:opacity-50 transition-all shadow-md shadow-purple-200 flex items-center justify-center gap-2">
          {sending ? (
            <><div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" /> Sending...</>
          ) : (
            <><span>🔔</span> Send Notification</>
          )}
        </button>
      </div>
    </div>
  );
}   