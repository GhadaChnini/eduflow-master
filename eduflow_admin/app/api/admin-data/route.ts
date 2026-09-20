import { getSupabaseAdmin } from '@/lib/supabase';
import { NextResponse, NextRequest } from 'next/server';

export async function GET(req: NextRequest) {
  const supabase = getSupabaseAdmin();
  const type = req.nextUrl.searchParams.get('type');
  const filter = req.nextUrl.searchParams.get('filter');

  try {
    if (type === 'applications') {
      let query = supabase.from('teacher_applications').select('*').order('created_at', { ascending: false });
      if (filter && filter !== 'all') query = query.eq('status', filter);
      const { data, error } = await query;
      console.log('applications error:', error, 'data count:', data?.length);
      if (error) return NextResponse.json({ error: error.message }, { status: 500 });
      return NextResponse.json(data || []);
    }
    if (type === 'users') {
      let query = supabase.from('profiles').select('*').order('created_at', { ascending: false });
      if (filter && filter !== 'all') query = query.eq('role', filter);
      const { data, error } = await query;
      if (error) return NextResponse.json({ error: error.message }, { status: 500 });
      return NextResponse.json(data || []);
    }
    if (type === 'units') {
      const { data, error } = await supabase
        .from('behavioral_units')
        .select('id, title, title_ar, title_en, title_fr, status, is_free, price, total_enrolled, avg_rating, created_at, teacher_id, grade_id, subject_id, content_url, content_type, description, description_ar')
        .order('created_at', { ascending: false });
      if (error) return NextResponse.json({ error: error.message }, { status: 500 });
      // Fetch teacher names separately
      const teacherIds = [...new Set((data || []).map((u: any) => u.teacher_id).filter(Boolean))];
      let teacherMap: Record<string, string> = {};
      if (teacherIds.length > 0) {
        const { data: teachers } = await supabase.from('profiles').select('id, name').in('id', teacherIds);
        (teachers || []).forEach((t: any) => { teacherMap[t.id] = t.name; });
      }
      const enriched = (data || []).map((u: any) => ({ ...u, teacher_name: teacherMap[u.teacher_id] || 'Unknown' }));
      return NextResponse.json(enriched);
    }
    return NextResponse.json({ error: 'Invalid type' }, { status: 400 });
  } catch (e: any) {
    return NextResponse.json({ error: e.message }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  const supabase = getSupabaseAdmin();
  const body = await req.json();
  const { type, id, data } = body;

  try {
    if (type === 'update_user') {
      const { error } = await supabase.from('profiles').update(data).eq('id', id);
      if (error) throw error;
      return NextResponse.json({ success: true });
    }
    if (type === 'delete_user') {
      const { error } = await supabase.from('profiles').delete().eq('id', id);
      if (error) throw error;
      return NextResponse.json({ success: true });
    }
    if (type === 'update_unit') {
      const { error } = await supabase.from('behavioral_units').update(data).eq('id', id);
      if (error) throw error;
      return NextResponse.json({ success: true });
    }
    if (type === 'delete_unit') {
      const { error } = await supabase.from('behavioral_units').delete().eq('id', id);
      if (error) throw error;
      return NextResponse.json({ success: true });
    }
    if (type === 'send_notification') {
      const { title, title_ar, message, message_ar, target } = data;
      let userIds: string[] = [];
      if (target === 'specific' && data.user_id) {
        userIds = [data.user_id];
      } else if (target === 'all') {
        const { data: users } = await supabase.from('profiles').select('id');
        userIds = (users || []).map((u: any) => u.id);
      } else if (target === 'students') {
        const { data: users } = await supabase.from('profiles').select('id').eq('role', 'parent');
        userIds = (users || []).map((u: any) => u.id);
      } else if (target === 'teachers') {
        const { data: users } = await supabase.from('profiles').select('id').eq('role', 'teacher');
        userIds = (users || []).map((u: any) => u.id);
      }
      if (userIds.length > 0) {
        const notifications = userIds.map((userId) => ({
          user_id: userId,
          title,
          title_ar: title_ar || title,
          message,
          message_ar: message_ar || message,
          type: 'announcement',
        }));
        const { error } = await supabase.from('notifications').insert(notifications);
        if (error) throw error;
      }
      return NextResponse.json({ success: true, sent: userIds.length });
    }
    return NextResponse.json({ error: 'Invalid type' }, { status: 400 });
  } catch (e: any) {
    return NextResponse.json({ error: e.message }, { status: 500 });
  }
}