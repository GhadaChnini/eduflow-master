'use client';
import { useEffect, useState, useRef } from 'react';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

interface Message {
  id: string;
  sender_id: string;
  content: string;
  is_from_admin: boolean;
  is_read: boolean;
  created_at: string;
}

interface Conversation {
  user_id: string;
  name: string;
  email: string;
  role: string;
  last_message: string;
  unread_count: number;
}

export default function MessagesTab() {
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [selectedUser, setSelectedUser] = useState<string | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [replyText, setReplyText] = useState('');
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const selectedUserRef = useRef<string | null>(null);

  useEffect(() => {
    loadConversations(true);
    const interval = setInterval(() => {
      loadConversations(false);
      if (selectedUserRef.current) loadMessages(selectedUserRef.current);
    }, 3000);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    selectedUserRef.current = selectedUser;
    if (selectedUser) loadMessages(selectedUser);
  }, [selectedUser]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);


  const loadConversations = async (showLoading = false) => {
    if (showLoading) setLoading(true);
    try {
      const res = await fetch('/api/messages');
      const msgs: Message[] = await res.json();
      if (!Array.isArray(msgs)) { setLoading(false); return; }

      const senderIds = [...new Set(msgs.map(m => m.sender_id))];
      if (senderIds.length === 0) { setConversations([]); setLoading(false); return; }

      const profilesRes = await fetch('/api/profiles?ids=' + senderIds.join(','));
      const profiles = await profilesRes.json();
      const profileMap: Record<string, any> = {};
      for (const p of (profiles || [])) profileMap[p.id] = p;

      const grouped: Record<string, Conversation> = {};
      for (const msg of msgs) {
        const uid = msg.sender_id;
        const profile = profileMap[uid];
        if (!grouped[uid]) {
          grouped[uid] = {
            user_id: uid,
            name: profile?.name || 'Unknown',
            email: profile?.email || '',
            role: profile?.role || 'student',
            last_message: msg.content,
            unread_count: 0,
          };
        }
        if (!msg.is_read) grouped[uid].unread_count++;
      }
      setConversations(Object.values(grouped));
    } catch (e) {
      console.error('Load conversations error:', e);
    }
    setLoading(false);
  };

  const loadMessages = async (userId: string) => {
    const res = await fetch('/api/messages?sender_id=' + userId);
    const data = await res.json();
    const sorted = Array.isArray(data)
      ? [...data].sort((a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime())
      : [];
    setMessages(sorted);
  };

  const sendReply = async () => {
    if (!replyText.trim() || !selectedUser) return;
    setSending(true);
    const text = replyText.trim();
    setReplyText('');

    const res = await fetch('/api/messages', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        sender_id: selectedUser,
        content: text,
        is_from_admin: true,
        is_read: false,
      }),
    });

    const newMsg = await res.json();
    if (newMsg?.id) {
      setMessages(prev => [...prev, newMsg].sort((a, b) =>
        new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
      ));
    }
    setSending(false);
  };

  const formatTime = (iso: string) => {
    const d = new Date(iso);
    return d.toLocaleTimeString('fr-TN', { hour: '2-digit', minute: '2-digit' });
  };

  const selectedConv = conversations.find(c => c.user_id === selectedUser);

  return (
    <div className="flex h-[700px] bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
      {/* Sidebar */}
      <div className="w-80 border-r border-gray-100 flex flex-col">
        <div className="p-4 border-b border-gray-100 flex justify-between items-center">
          <div>
            <h2 className="text-lg font-bold text-gray-800">💬 Support Messages</h2>
            <p className="text-sm text-gray-500">{conversations.length} conversations</p>
          </div>
          <button onClick={() => loadConversations(true)} className="text-purple-600 text-sm font-bold hover:underline">Refresh</button>
        </div>
        <div className="flex-1 overflow-y-auto">
          {loading ? (
            <div className="flex items-center justify-center h-32">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-600" />
            </div>
          ) : conversations.length === 0 ? (
            <div className="text-center py-12 text-gray-400">
              <div className="text-4xl mb-3">📭</div>
              <p>No messages yet</p>
            </div>
          ) : (
            conversations.map(conv => (
              <div
                key={conv.user_id}
                onClick={() => setSelectedUser(conv.user_id)}
                className={`p-4 cursor-pointer border-b border-gray-50 hover:bg-gray-50 transition-colors ${selectedUser === conv.user_id ? 'bg-purple-50 border-r-4 border-r-purple-600' : ''}`}
              >
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-purple-100 flex items-center justify-center font-bold text-purple-600 flex-shrink-0">
                    {conv.name[0]?.toUpperCase()}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex justify-between items-center">
                      <span className="font-semibold text-sm text-gray-800">{conv.name}</span>
                      {conv.unread_count > 0 && (
                        <span className="bg-purple-600 text-white text-xs rounded-full px-2 py-0.5">{conv.unread_count}</span>
                      )}
                    </div>
                    <div className="flex justify-between items-center gap-2">
                      <p className="text-xs text-gray-400 truncate">{conv.last_message}</p>
                      <span className={`text-xs px-2 py-0.5 rounded-full flex-shrink-0 ${conv.role === 'teacher' ? 'bg-blue-100 text-blue-600' : 'bg-green-100 text-green-600'}`}>
                        {conv.role === 'teacher' ? 'Teacher' : 'Student'}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Chat area */}
      <div className="flex-1 flex flex-col">
        {!selectedUser ? (
          <div className="flex-1 flex items-center justify-center text-gray-400">
            <div className="text-center">
              <div className="text-6xl mb-4">💬</div>
              <p className="text-lg">Select a conversation to reply</p>
            </div>
          </div>
        ) : (
          <>
            <div className="p-4 border-b border-gray-100 flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-purple-100 flex items-center justify-center font-bold text-purple-600">
                {selectedConv?.name[0]?.toUpperCase()}
              </div>
              <div>
                <p className="font-bold text-gray-800">{selectedConv?.name}</p>
                <p className="text-xs text-gray-400">{selectedConv?.email}</p>
              </div>
            </div>
            <div className="flex-1 overflow-y-auto p-4 space-y-3">
              {messages.map((msg, i) => (
                <div key={i} className={`flex ${msg.is_from_admin ? 'justify-end' : 'justify-start'}`}>
                  <div className={`max-w-xs lg:max-w-md px-4 py-2 rounded-2xl ${msg.is_from_admin ? 'bg-purple-600 text-white' : 'bg-gray-100 text-gray-800'}`}>
                    <p className="text-sm">{msg.content}</p>
                    <p className={`text-xs mt-1 ${msg.is_from_admin ? 'text-purple-200' : 'text-gray-400'}`}>{formatTime(msg.created_at)}</p>
                  </div>
                </div>
              ))}
              <div ref={messagesEndRef} />
            </div>
            <div className="p-4 border-t border-gray-100 flex gap-3">
              <input
                value={replyText}
                onChange={e => setReplyText(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && !e.shiftKey && sendReply()}
                placeholder="Type your reply..."
                className="flex-1 border border-gray-200 rounded-xl px-4 py-2 text-sm focus:outline-none focus:border-purple-400"
              />
              <button
                onClick={sendReply}
                disabled={sending || !replyText.trim()}
                className="bg-purple-600 text-white px-6 py-2 rounded-xl text-sm font-bold hover:bg-purple-700 disabled:opacity-50"
              >
                {sending ? '...' : 'Send'}
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  );
}