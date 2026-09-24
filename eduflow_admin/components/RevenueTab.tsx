'use client';
import { useState, useEffect } from 'react';

interface RevenueRow {
  id: string;
  type: 'unit' | 'session';
  title: string;
  teacher: string;
  price: number;
  enrollments: number;
  gross: number;
  eduflow_share: number;
  teacher_receives: number;
  date: string;
}

interface Summary {
  totalGross: number;
  totalEduflow: number;
  totalTeachers: number;
  totalTransactions: number;
}

export default function RevenueTab() {
  const [rows, setRows] = useState<RevenueRow[]>([]);
  const [summary, setSummary] = useState<Summary>({ totalGross: 0, totalEduflow: 0, totalTeachers: 0, totalTransactions: 0 });
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'unit' | 'session'>('all');
  const [search, setSearch] = useState('');

  useEffect(() => { fetchRevenue(); }, []);

  const fetchRevenue = async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/revenue');
      const data = await res.json();
      setRows(data.rows || []);
      setSummary(data.summary || {});
    } catch (_) {}
    setLoading(false);
  };

  const filtered = rows.filter(r => {
    const matchFilter = filter === 'all' || r.type === filter;
    const matchSearch =
      r.title.toLowerCase().includes(search.toLowerCase()) ||
      r.teacher.toLowerCase().includes(search.toLowerCase());
    return matchFilter && matchSearch;
  });

  const formatDate = (d: string) =>
    new Date(d).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });

  const summaryCards = [
    { label: 'Total Gross', value: `${summary.totalGross} DT`, icon: '💰', bg: 'from-blue-500 to-blue-600' },
    { label: 'EduFlow Share (15%)', value: `${summary.totalEduflow} DT`, icon: '🏦', bg: 'from-purple-500 to-purple-600' },
    { label: 'Teachers Receive (85%)', value: `${summary.totalTeachers} DT`, icon: '👩‍🏫', bg: 'from-emerald-500 to-emerald-600' },
    { label: 'Total Transactions', value: summary.totalTransactions, icon: '📊', bg: 'from-amber-500 to-amber-600' },
  ];

  return (
    <div>
      {/* Summary Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        {summaryCards.map(c => (
          <div key={c.label} className={`bg-gradient-to-br ${c.bg} rounded-2xl p-4 text-white shadow-md`}>
            <div className="text-2xl mb-1">{c.icon}</div>
            <div className="text-xl font-bold">{c.value}</div>
            <div className="text-white/80 text-xs mt-1">{c.label}</div>
          </div>
        ))}
      </div>

      {/* Filters */}
      <div className="flex gap-3 mb-4 flex-wrap">
        <input
          value={search}
          onChange={e => setSearch(e.target.value)}
          placeholder="Search by title or teacher..."
          className="flex-1 min-w-[200px] border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500"
        />
        {(['all', 'unit', 'session'] as const).map(f => (
          <button key={f} onClick={() => setFilter(f)}
            className={`px-4 py-2 rounded-xl text-sm font-medium capitalize transition-all ${
              filter === f ? 'bg-purple-600 text-white shadow-md' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}>
            {f === 'all' ? 'All' : f === 'unit' ? '📚 Units' : '🎥 Sessions'}
          </button>
        ))}
      </div>

      {/* Table */}
      {loading ? (
        <div className="flex items-center justify-center py-16">
          <div className="w-8 h-8 border-4 border-purple-200 border-t-purple-600 rounded-full animate-spin" />
        </div>
      ) : filtered.length === 0 ? (
        <div className="text-center py-16">
          <div className="text-4xl mb-3">💸</div>
          <p className="text-gray-400 font-medium">No revenue records found</p>
        </div>
      ) : (
        <div className="overflow-x-auto rounded-2xl border border-gray-100">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-100">
              <tr>
                <th className="text-left px-4 py-3 text-gray-500 font-medium">Type</th>
                <th className="text-left px-4 py-3 text-gray-500 font-medium">Title</th>
                <th className="text-left px-4 py-3 text-gray-500 font-medium">Teacher</th>
                <th className="text-right px-4 py-3 text-gray-500 font-medium">Price</th>
                <th className="text-right px-4 py-3 text-gray-500 font-medium">Enrollments</th>
                <th className="text-right px-4 py-3 text-gray-500 font-medium">Gross</th>
                <th className="text-right px-4 py-3 text-purple-600 font-medium">EduFlow (15%)</th>
                <th className="text-right px-4 py-3 text-emerald-600 font-medium">Teacher (85%)</th>
                <th className="text-left px-4 py-3 text-gray-500 font-medium">Date</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {filtered.map(row => (
                <tr key={row.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-4 py-3">
                    <span className={`px-2 py-0.5 rounded-lg text-xs font-medium border ${
                      row.type === 'unit'
                        ? 'bg-blue-50 text-blue-700 border-blue-200'
                        : 'bg-purple-50 text-purple-700 border-purple-200'
                    }`}>
                      {row.type === 'unit' ? '📚 Unit' : '🎥 Session'}
                    </span>
                  </td>
                  <td className="px-4 py-3 font-medium text-gray-900 max-w-[180px] truncate">{row.title}</td>
                  <td className="px-4 py-3 text-gray-600">{row.teacher}</td>
                  <td className="px-4 py-3 text-right text-gray-700">{row.price} DT</td>
                  <td className="px-4 py-3 text-right text-gray-700">{row.enrollments}</td>
                  <td className="px-4 py-3 text-right font-medium text-gray-900">{row.gross.toFixed(2)} DT</td>
                  <td className="px-4 py-3 text-right font-semibold text-purple-600">{row.eduflow_share} DT</td>
                  <td className="px-4 py-3 text-right font-semibold text-emerald-600">{row.teacher_receives} DT</td>
                  <td className="px-4 py-3 text-gray-500 text-xs">{formatDate(row.date)}</td>
                </tr>
              ))}
            </tbody>
            <tfoot className="bg-gray-50 border-t border-gray-200">
              <tr>
                <td colSpan={5} className="px-4 py-3 font-semibold text-gray-700">Totals ({filtered.length} records)</td>
                <td className="px-4 py-3 text-right font-bold text-gray-900">
                  {filtered.reduce((s, r) => s + r.gross, 0).toFixed(2)} DT
                </td>
                <td className="px-4 py-3 text-right font-bold text-purple-600">
                  {filtered.reduce((s, r) => s + r.eduflow_share, 0).toFixed(2)} DT
                </td>
                <td className="px-4 py-3 text-right font-bold text-emerald-600">
                  {filtered.reduce((s, r) => s + r.teacher_receives, 0).toFixed(2)} DT
                </td>
                <td />
              </tr>
            </tfoot>
          </table>
        </div>
      )}
    </div>
  );
}