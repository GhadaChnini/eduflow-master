'use client';
import { useState, useEffect, useRef } from 'react';

interface Unit {
  id: string;
  title: string;
  title_ar: string;
  title_en: string;
  title_fr: string;
  status: string;
  price: number;
  is_free: boolean;
  total_enrolled: number;
  avg_rating: number;
  content_url: string;
  content_type: string;
  description: string;
  description_ar: string;
  teacher_id: string;
  teacher_name?: string;
  grade_id?: number;
  subject_id?: number;
  created_at: string;
}

export default function UnitsTab() {
  const [units, setUnits] = useState<Unit[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('all');
  const [selectedUnit, setSelectedUnit] = useState<Unit | null>(null);

  useEffect(() => { fetchUnits(); }, []);

  const fetchUnits = async () => {
    setLoading(true);
    const res = await fetch('/api/admin-data?type=units');
    const data = await res.json();
    setUnits(Array.isArray(data) ? data : []);
    setLoading(false);
  };

  const notifyTeacher = async (teacherId: string, title: string, titleAr: string, message: string, messageAr: string) => {
    await fetch('/api/admin-data', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        type: 'send_notification',
        data: { title, title_ar: titleAr, message, message_ar: messageAr, target: 'specific', user_id: teacherId },
      }),
    });
  };

  const handleStatusChange = async (unit: Unit, status: string) => {
    await fetch('/api/admin-data', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ type: 'update_unit', id: unit.id, data: { status } }),
    });
    if (status === 'draft') {
      await notifyTeacher(
        unit.teacher_id,
        'Your unit has been unpublished',
        'تم إلغاء نشر وحدتك',
        `Your unit "${unit.title_ar || unit.title}" has been unpublished by the admin.`,
        `تم إلغاء نشر وحدتك "${unit.title_ar || unit.title}" من قبل المسؤول.`
      );
    }
    setSelectedUnit(null);
    fetchUnits();
  };

  const handleDelete = async (unit: Unit) => {
    if (!confirm(`Delete unit "${unit.title_ar || unit.title}"?`)) return;
    await notifyTeacher(
      unit.teacher_id,
      'Your unit has been deleted',
      'تم حذف وحدتك',
      `Your unit "${unit.title_ar || unit.title}" has been deleted by the admin.`,
      `تم حذف وحدتك "${unit.title_ar || unit.title}" من قبل المسؤول.`
    );
    await fetch('/api/admin-data', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ type: 'delete_unit', id: unit.id }),
    });
    setSelectedUnit(null);
    fetchUnits();
  };

  const filtered = units.filter(u => {
    const matchSearch =
      u.title_ar?.toLowerCase().includes(search.toLowerCase()) ||
      u.title?.toLowerCase().includes(search.toLowerCase()) ||
      u.teacher_name?.toLowerCase().includes(search.toLowerCase());
    const matchFilter = filter === 'all' || u.status === filter;
    return matchSearch && matchFilter;
  });

  const statusColor = (s: string) => s === 'published'
    ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
    : 'bg-amber-50 text-amber-700 border-amber-200';

  const getFileType = (unit: Unit) => {
    // Use content_type column first
    if (unit.content_type) {
      const ct = unit.content_type.toLowerCase().trim();
      if (ct === 'pdf' || ct === 'application/pdf') return 'pdf';
      if (ct === 'video' || ct === 'mp4' || ct === 'mov' || ct === 'avi' || ct.startsWith('video/')) return 'video';
      if (ct === 'image' || ct === 'png' || ct === 'jpg' || ct === 'jpeg' || ct === 'webp' || ct.startsWith('image/')) return 'image';
    }
    // Fallback: strip query params and check extension only
    const url = getFirstUrl(unit.content_url);
    if (!url) return 'unknown';
    const ext = url.split('?')[0].toLowerCase().split('.').pop() || '';
    if (ext === 'pdf') return 'pdf';
    if (['mp4', 'mov', 'avi', 'webm', 'mkv'].includes(ext)) return 'video';
    if (['png', 'jpg', 'jpeg', 'webp', 'gif', 'svg'].includes(ext)) return 'image';
    return 'unknown';
  };

  // content_url may be a JSON array string ["url1","url2"] or a plain URL
  const getFirstUrl = (content_url: string | null): string => {
    if (!content_url) return '';
    const trimmed = content_url.trim();
    if (trimmed.startsWith('[')) {
      try {
        const arr = JSON.parse(trimmed);
        return Array.isArray(arr) && arr.length > 0 ? arr[0] : '';
      } catch { return ''; }
    }
    return trimmed;
  };

  const formatDate = (d: string) =>
    new Date(d).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });

  return (
    <div>
      {/* Search + Filters */}
      <div className="flex gap-3 mb-6 flex-wrap">
        <input value={search} onChange={e => setSearch(e.target.value)}
          placeholder="Search by title or teacher..."
          className="flex-1 min-w-[200px] border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500" />
        {['all', 'published', 'draft'].map(f => (
          <button key={f} onClick={() => setFilter(f)}
            className={`px-4 py-2 rounded-xl text-sm font-medium capitalize transition-all ${
              filter === f ? 'bg-purple-600 text-white shadow-md' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}>
            {f}
          </button>
        ))}
      </div>

      {/* Units List */}
      {loading ? (
        <div className="flex items-center justify-center py-16">
          <div className="w-8 h-8 border-4 border-purple-200 border-t-purple-600 rounded-full animate-spin" />
        </div>
      ) : filtered.length === 0 ? (
        <div className="text-center py-16">
          <div className="text-4xl mb-3">📚</div>
          <p className="text-gray-400 font-medium">No units found</p>
        </div>
      ) : (
        <div className="space-y-3">
          {filtered.map(unit => (
            <div key={unit.id}
              className="bg-gray-50 rounded-2xl border border-gray-100 p-4 flex items-center justify-between hover:border-purple-200 transition-all cursor-pointer"
              onClick={() => setSelectedUnit(unit)}>
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <h3 className="font-semibold text-gray-900">{unit.title_ar || unit.title_en || unit.title}</h3>
                  {(unit.title_ar && unit.title) && (
                    <p className="text-xs text-gray-400">{unit.title}</p>
                  )}
                  <span className={`px-2 py-0.5 rounded-lg text-xs font-medium border ${statusColor(unit.status)}`}>
                    {unit.status}
                  </span>
                </div>
                <p className="text-sm text-gray-500 mb-2">by {unit.teacher_name || 'Unknown'} · {formatDate(unit.created_at)}</p>
                <div className="flex gap-2 flex-wrap">
                  {unit.is_free
                    ? <span className="px-2 py-0.5 rounded-lg text-xs bg-blue-50 text-blue-700 border border-blue-200">Free</span>
                    : <span className="px-2 py-0.5 rounded-lg text-xs bg-orange-50 text-orange-700 border border-orange-200">{unit.price} DT</span>}
                  <span className="px-2 py-0.5 rounded-lg text-xs bg-gray-100 text-gray-600">{unit.total_enrolled || 0} enrolled</span>
                  <span className="px-2 py-0.5 rounded-lg text-xs bg-yellow-50 text-yellow-700">★ {unit.avg_rating?.toFixed(1) || '0.0'}</span>
                  {unit.content_url && (
                    <span className="px-2 py-0.5 rounded-lg text-xs bg-indigo-50 text-indigo-700 border border-indigo-200">
                      {getFileType(unit).toUpperCase()}
                    </span>
                  )}
                </div>
              </div>
              <div className="flex gap-2 ml-4" onClick={e => e.stopPropagation()}>
                {unit.status === 'published' ? (
                  <button onClick={() => handleStatusChange(unit, 'draft')}
                    className="px-3 py-1.5 text-xs bg-amber-50 text-amber-700 border border-amber-200 rounded-xl hover:bg-amber-100 font-medium transition-all">
                    Unpublish
                  </button>
                ) : (
                  <button onClick={() => handleStatusChange(unit, 'published')}
                    className="px-3 py-1.5 text-xs bg-emerald-50 text-emerald-700 border border-emerald-200 rounded-xl hover:bg-emerald-100 font-medium transition-all">
                    Publish
                  </button>
                )}
                <button onClick={() => handleDelete(unit)}
                  className="px-3 py-1.5 text-xs bg-red-50 text-red-700 border border-red-200 rounded-xl hover:bg-red-100 font-medium transition-all">
                  Delete
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Unit Detail Modal */}
      {selectedUnit && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4"
          onClick={() => setSelectedUnit(null)}>
          <div className="bg-white rounded-3xl shadow-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto"
            onClick={e => e.stopPropagation()}>

            {/* Modal Header */}
            <div className="flex items-center justify-between p-6 border-b border-gray-100">
              <div>
                <h2 className="text-lg font-bold text-gray-900">{selectedUnit.title_ar || selectedUnit.title_en || selectedUnit.title_fr || selectedUnit.title}</h2>
                {selectedUnit.title && <p className="text-xs text-gray-400 mt-0.5">{selectedUnit.title} {selectedUnit.title_en ? `· ${selectedUnit.title_en}` : ''}</p>}
                <p className="text-sm text-gray-500">by {selectedUnit.teacher_name || 'Unknown'}</p>
              </div>
              <button onClick={() => setSelectedUnit(null)}
                className="w-9 h-9 flex items-center justify-center rounded-xl bg-gray-100 hover:bg-gray-200 text-gray-500 text-lg transition-all">
                ✕
              </button>
            </div>

            {/* Unit Info */}
            <div className="p-6 space-y-4">
              <div className="grid grid-cols-2 gap-3">
                {[
                  { label: 'Status', value: selectedUnit.status },
                  { label: 'Price', value: selectedUnit.is_free ? 'Free' : `${selectedUnit.price} DT` },
                  { label: 'Enrolled', value: selectedUnit.total_enrolled || 0 },
                  { label: 'Rating', value: `★ ${selectedUnit.avg_rating?.toFixed(1) || '0.0'}` },
                  { label: 'Created', value: formatDate(selectedUnit.created_at) },
                  { label: 'File type', value: getFileType(selectedUnit).toUpperCase() },
                ].map(item => (
                  <div key={item.label} className="bg-gray-50 rounded-xl p-3">
                    <p className="text-xs text-gray-400 mb-0.5">{item.label}</p>
                    <p className="text-sm font-semibold text-gray-800">{item.value}</p>
                  </div>
                ))}
              </div>

              {/* Description */}
              {(selectedUnit.description_ar || selectedUnit.description) && (
                <div className="bg-gray-50 rounded-xl p-4">
                  <p className="text-xs text-gray-400 mb-1">Description</p>
                  <p className="text-sm text-gray-700">{selectedUnit.description_ar || selectedUnit.description}</p>
                </div>
              )}

              {/* File Preview */}
              {selectedUnit.content_url && (
                <div>
                  <p className="text-sm font-semibold text-gray-700 mb-3">Content Preview</p>
                  {(() => {
                    const url = getFirstUrl(selectedUnit.content_url);
                    const type = getFileType(selectedUnit);
                    if (!url) return (
                      <div className="rounded-2xl border border-gray-200 p-6 text-center text-gray-400">
                        <p className="text-4xl mb-2">📎</p>
                        <p className="text-sm">No file URL available</p>
                      </div>
                    );
                    if (type === 'pdf') return (
                      <div className="rounded-2xl overflow-hidden border border-gray-200 bg-gray-50">
                        <iframe src={url} className="w-full h-[420px]" title="PDF Preview" />
                      </div>
                    );
                    if (type === 'video') return (
                      <div className="rounded-2xl overflow-hidden border border-gray-200 bg-black">
                        <video src={url} controls className="w-full max-h-[360px]" />
                      </div>
                    );
                    if (type === 'image') return (
                      <div className="rounded-2xl overflow-hidden border border-gray-200">
                        <img src={url} alt="Unit content" className="w-full object-contain max-h-[360px]" />
                      </div>
                    );
                    return (
                      <div className="rounded-2xl border border-gray-200 p-6 text-center text-gray-400">
                        <p className="text-4xl mb-2">📎</p>
                        <p className="text-sm">Preview not available for this file type</p>
                        <a href={url} target="_blank" rel="noreferrer"
                          className="text-purple-600 text-sm underline mt-2 inline-block">
                          Open file
                        </a>
                      </div>
                    );
                  })()}
                </div>
              )}

              {/* Actions */}
              <div className="flex gap-3 pt-2">
                {selectedUnit.status === 'published' ? (
                  <button onClick={() => handleStatusChange(selectedUnit, 'draft')}
                    className="flex-1 py-2.5 text-sm bg-amber-50 text-amber-700 border border-amber-200 rounded-xl hover:bg-amber-100 font-medium transition-all">
                    Unpublish Unit
                  </button>
                ) : (
                  <button onClick={() => handleStatusChange(selectedUnit, 'published')}
                    className="flex-1 py-2.5 text-sm bg-emerald-50 text-emerald-700 border border-emerald-200 rounded-xl hover:bg-emerald-100 font-medium transition-all">
                    Publish Unit
                  </button>
                )}
                <button onClick={() => handleDelete(selectedUnit)}
                  className="flex-1 py-2.5 text-sm bg-red-50 text-red-700 border border-red-200 rounded-xl hover:bg-red-100 font-medium transition-all">
                  Delete Unit
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}