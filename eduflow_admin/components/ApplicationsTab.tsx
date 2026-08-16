'use client';
import { useState, useEffect } from 'react';

export default function ApplicationsTab({ onUpdate }: { onUpdate: () => void }) {
  const [applications, setApplications] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('pending');
  const [processingId, setProcessingId] = useState<any>(null);
  const [selectedApp, setSelectedApp] = useState<any>(null);

  useEffect(() => { fetchApplications(); }, [filter]);

  const fetchApplications = async () => {
    setLoading(true);
    const res = await fetch(`/api/admin-data?type=applications&filter=${filter}`);
    const data = await res.json();
    setApplications(Array.isArray(data) ? data : []);
    setLoading(false);
  };

  const handleApprove = async (app: any) => {
    setProcessingId(app.id);
    try {
      const res = await fetch('/api/approve-teacher', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: app.name, email: app.email, applicationId: app.id }),
      });
      const data = await res.json();
      if (data.success) alert('Teacher approved! Credentials sent by email.');
      else alert(`Error: ${data.error}`);
      await fetchApplications();
      onUpdate();
    } catch (e) { alert('Error approving'); }
    setProcessingId(null);
  };

  const handleReject = async (app: any) => {
    if (!confirm(`Reject ${app.name}'s application?`)) return;
    await fetch('/api/admin-data', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ type: 'update_unit', id: app.id, data: { status: 'rejected' } }),
    });
    await fetchApplications();
    onUpdate();
  };

  const filters = ['pending', 'approved', 'rejected', 'all'];

  return (
    <div>
      <div className="flex gap-2 mb-6">
        {filters.map(f => (
          <button key={f} onClick={() => setFilter(f)}
            className={`px-4 py-2 rounded-xl text-sm font-medium capitalize transition-all ${filter === f ? 'bg-purple-600 text-white shadow-md' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}`}>
            {f}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-16"><div className="w-8 h-8 border-4 border-purple-200 border-t-purple-600 rounded-full animate-spin" /></div>
      ) : applications.length === 0 ? (
        <div className="text-center py-12 text-gray-400">No {filter} applications</div>
      ) : (
        <div className="space-y-4">
          {applications.map(app => (
            <div key={app.id} className="bg-gray-50 rounded-2xl border border-gray-100 p-5 hover:border-purple-200 transition-all">
              <div className="flex items-start justify-between">
                <div>
                  <h3 className="font-bold text-gray-900">{app.name}</h3>
                  <p className="text-sm text-gray-500">{app.email}</p>
                  <p className="text-xs text-gray-400 mt-1">{new Date(app.created_at).toLocaleDateString()}</p>
                  <span className={`inline-block mt-2 px-2 py-1 rounded text-xs font-medium ${
                    app.status === 'pending' ? 'bg-yellow-100 text-yellow-700' :
                    app.status === 'approved' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                  }`}>{app.status}</span>
                </div>
                <div className="flex gap-2">
                  <button onClick={() => setSelectedApp(app)} className="px-3 py-1.5 text-sm bg-gray-100 rounded-lg hover:bg-gray-200">View</button>
                  {app.status === 'pending' && (
                    <>
                      <button onClick={() => handleApprove(app)} disabled={processingId === app.id}
                        className="px-3 py-1.5 text-sm bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50">
                        {processingId === app.id ? '...' : 'Approve'}
                      </button>
                      <button onClick={() => handleReject(app)}
                        className="px-3 py-1.5 text-sm bg-red-600 text-white rounded-lg hover:bg-red-700">
                        Reject
                      </button>
                    </>
                  )}
                </div>
              </div>
              {app.bio && <p className="text-sm text-gray-600 mt-3 line-clamp-2">{app.bio}</p>}
            </div>
          ))}
        </div>
      )}

      {selectedApp && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-2xl w-full p-6 max-h-[90vh] overflow-y-auto">
            <h2 className="text-xl font-bold mb-4">{selectedApp.name}</h2>
            <div className="space-y-3 mb-6">
              <div className="p-3 bg-gray-50 rounded-xl">
                <div className="text-xs text-gray-400 mb-1">Email</div>
                <div className="text-sm font-medium text-gray-800">{selectedApp.email}</div>
              </div>
              <div className="p-3 bg-gray-50 rounded-xl">
                <div className="text-xs text-gray-400 mb-1">Status</div>
                <span className={`inline-block px-2 py-1 rounded text-xs font-medium ${
                  selectedApp.status === 'pending' ? 'bg-yellow-100 text-yellow-700' :
                  selectedApp.status === 'approved' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                }`}>{selectedApp.status}</span>
              </div>
              <div className="p-3 bg-gray-50 rounded-xl">
                <div className="text-xs text-gray-400 mb-1">Applied</div>
                <div className="text-sm font-medium text-gray-800">{new Date(selectedApp.created_at).toLocaleString()}</div>
              </div>
              {selectedApp.bio && (
                <div className="p-3 bg-gray-50 rounded-xl">
                  <div className="text-xs text-gray-400 mb-1">Bio</div>
                  <div className="text-sm text-gray-700">{selectedApp.bio}</div>
                </div>
              )}
              {selectedApp.cv_url && (
                <div className="p-3 bg-purple-50 rounded-xl border border-purple-100">
                  <div className="text-xs text-gray-400 mb-2">CV / Resume</div>
                  <a href={selectedApp.cv_url} target="_blank" rel="noopener noreferrer"
                    className="flex items-center gap-2 text-sm font-medium text-purple-700 hover:text-purple-900">
                    <span className="text-lg">📄</span>
                    <span>View CV</span>
                    <span className="text-xs text-purple-400">↗</span>
                  </a>
                  {selectedApp.cv_url.toLowerCase().endsWith('.pdf') && (
                    <div className="mt-3 rounded-xl overflow-hidden border border-purple-100" style={{height: '400px'}}>
                      <iframe src={selectedApp.cv_url} className="w-full h-full" title="CV Preview" />
                    </div>
                  )}
                </div>
              )}
            </div>
            <button onClick={() => setSelectedApp(null)} className="mt-4 w-full py-2 bg-gray-100 rounded-lg hover:bg-gray-200">Close</button>
          </div>
        </div>
      )}
    </div>
  );
}