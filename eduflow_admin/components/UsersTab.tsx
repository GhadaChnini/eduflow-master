'use client';
import { useState, useEffect } from 'react';

export default function UsersTab() {
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');
  const [search, setSearch] = useState('');
  const [selected, setSelected] = useState<any>(null);

  useEffect(() => { fetchUsers(); }, [filter]);

  const fetchUsers = async () => {
    setLoading(true);
    const res = await fetch(`/api/admin-data?type=users&filter=${filter}`);
    const data = await res.json();
    setUsers(Array.isArray(data) ? data : []);
    setLoading(false);
  };

  const handleDelete = async (id: string, name: string) => {
    if (!confirm(`Delete user ${name}? This cannot be undone.`)) return;
    await fetch('/api/admin-data', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ type: 'delete_user', id }),
    });
    setSelected(null);
    fetchUsers();
  };

  const filtered = users.filter(u =>
    u.name?.toLowerCase().includes(search.toLowerCase()) ||
    u.email?.toLowerCase().includes(search.toLowerCase())
  );

  const roleLabel = (role: string) => role === 'parent' ? 'Student' : role === 'teacher' ? 'Teacher' : 'Admin';
  const roleStyle = (role: string) => role === 'parent'
    ? 'bg-blue-50 text-blue-700 border-blue-200'
    : role === 'teacher'
    ? 'bg-purple-50 text-purple-700 border-purple-200'
    : 'bg-red-50 text-red-700 border-red-200';

  const roleIcon = (role: string) => role === 'parent' ? '🎓' : role === 'teacher' ? '👩‍🏫' : '⚙️';

  const initials = (name: string) => name ? name.split(' ').map((n: string) => n[0]).join('').toUpperCase().slice(0, 2) : '?';

  const avatarColor = (role: string) => role === 'parent' ? 'from-blue-400 to-blue-600' : role === 'teacher' ? 'from-purple-400 to-purple-600' : 'from-red-400 to-red-600';

  return (
    <div>
      {/* Toolbar */}
      <div className="flex flex-wrap gap-3 mb-6">
        <div className="relative flex-1 min-w-[200px]">
          <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm">🔍</span>
          <input value={search} onChange={e => setSearch(e.target.value)}
            placeholder="Search name or email..."
            className="w-full border border-gray-200 rounded-xl pl-9 pr-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500" />
        </div>
        <div className="flex gap-1 bg-gray-100 rounded-xl p-1">
          {[
            { val: 'all', label: 'All' },
            { val: 'parent', label: 'Students' },
            { val: 'teacher', label: 'Teachers' },
          ].map(f => (
            <button key={f.val} onClick={() => setFilter(f.val)}
              className={`px-4 py-1.5 rounded-lg text-sm font-medium transition-all ${
                filter === f.val ? 'bg-white text-purple-700 shadow-sm font-semibold' : 'text-gray-500 hover:text-gray-700'
              }`}>
              {f.label}
            </button>
          ))}
        </div>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-3 gap-3 mb-6">
        {[
          { label: 'Total', count: users.length, icon: '👥', color: 'purple' },
          { label: 'Students', count: users.filter(u => u.role === 'parent').length, icon: '🎓', color: 'blue' },
          { label: 'Teachers', count: users.filter(u => u.role === 'teacher').length, icon: '👩‍🏫', color: 'violet' },
        ].map(s => (
          <div key={s.label} className="bg-gray-50 rounded-2xl border border-gray-100 p-4 flex items-center gap-3">
            <div className="text-2xl">{s.icon}</div>
            <div>
              <div className="text-xl font-bold text-gray-800">{s.count}</div>
              <div className="text-xs text-gray-500">{s.label}</div>
            </div>
          </div>
        ))}
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-16">
          <div className="w-8 h-8 border-4 border-purple-200 border-t-purple-600 rounded-full animate-spin" />
        </div>
      ) : filtered.length === 0 ? (
        <div className="text-center py-16">
          <div className="text-4xl mb-3">👥</div>
          <p className="text-gray-400 font-medium">No users found</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3">
          {filtered.map(user => (
            <div key={user.id}
              onClick={() => setSelected(user)}
              className="bg-gray-50 rounded-2xl border border-gray-100 p-4 cursor-pointer hover:border-purple-300 hover:shadow-md transition-all group">
              <div className="flex items-center gap-3">
                {user.avatar_url ? (
                  <img src={user.avatar_url} className="w-12 h-12 rounded-2xl object-cover" />
                ) : (
                  <div className={`w-12 h-12 rounded-2xl bg-gradient-to-br ${avatarColor(user.role)} flex items-center justify-center text-white font-bold text-lg`}>
                    {initials(user.name || '')}
                  </div>
                )}
                <div className="flex-1 min-w-0">
                  <div className="font-semibold text-gray-900 truncate">{user.name || 'No name'}</div>
                  <div className="text-xs text-gray-400 truncate">{user.email}</div>
                </div>
                <span className={`px-2 py-1 rounded-lg text-xs font-medium border ${roleStyle(user.role)}`}>
                  {roleIcon(user.role)} {roleLabel(user.role)}
                </span>
              </div>
              <div className="flex items-center justify-between mt-3 pt-3 border-t border-gray-100">
                <div className="flex gap-3 text-xs text-gray-400">
                  <span>⭐ {user.points || 0} pts</span>
                  <span>📅 {new Date(user.created_at).toLocaleDateString()}</span>
                </div>
                <span className="text-purple-400 text-xs opacity-0 group-hover:opacity-100 transition-opacity">View →</span>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* User Detail Modal */}
      {selected && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4" onClick={() => setSelected(null)}>
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl" onClick={e => e.stopPropagation()}>
            <div className="flex items-center gap-4 mb-6">
              {selected.avatar_url ? (
                <img src={selected.avatar_url} className="w-16 h-16 rounded-2xl object-cover" />
              ) : (
                <div className={`w-16 h-16 rounded-2xl bg-gradient-to-br ${avatarColor(selected.role)} flex items-center justify-center text-white font-bold text-2xl`}>
                  {initials(selected.name || '')}
                </div>
              )}
              <div>
                <h2 className="text-xl font-bold text-gray-900">{selected.name || 'No name'}</h2>
                <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-lg text-xs font-medium border ${roleStyle(selected.role)}`}>
                  {roleIcon(selected.role)} {roleLabel(selected.role)}
                </span>
              </div>
            </div>
            <div className="space-y-3 mb-6">
              {[
                { label: 'Email', value: selected.email, icon: '📧' },
                { label: 'Phone', value: selected.phone || '—', icon: '📞' },
                { label: 'Points', value: selected.points || 0, icon: '⭐' },
                { label: 'Grade', value: selected.grade_level || '—', icon: '🎓' },
                { label: 'Joined', value: new Date(selected.created_at).toLocaleString(), icon: '📅' },
              ].map(item => (
                <div key={item.label} className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                  <span className="text-lg">{item.icon}</span>
                  <div>
                    <div className="text-xs text-gray-400">{item.label}</div>
                    <div className="text-sm font-medium text-gray-800">{String(item.value)}</div>
                  </div>
                </div>
              ))}
              {selected.bio && (
                <div className="p-3 bg-gray-50 rounded-xl">
                  <div className="text-xs text-gray-400 mb-1">Bio</div>
                  <div className="text-sm text-gray-700">{selected.bio}</div>
                </div>
              )}
            </div>
            <div className="flex gap-3">
              <button onClick={() => setSelected(null)}
                className="flex-1 py-2.5 bg-gray-100 text-gray-700 rounded-xl font-medium hover:bg-gray-200 transition-all">
                Close
              </button>
              <button onClick={() => handleDelete(selected.id, selected.name)}
                className="flex-1 py-2.5 bg-red-500 text-white rounded-xl font-medium hover:bg-red-600 transition-all">
                Delete User
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}