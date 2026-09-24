import { getSupabaseAdmin } from '@/lib/supabase';
import { NextResponse } from 'next/server';

export async function GET() {
  const supabase = getSupabaseAdmin();

  const { data: paidUnits } = await supabase
    .from('behavioral_units')
    .select('id, title, title_ar, price, total_enrolled, created_at, teacher_id, profiles(name)')
    .eq('is_free', false)
    .gt('total_enrolled', 0)
    .order('created_at', { ascending: false });

  const { data: paidSessions } = await supabase
    .from('live_sessions')
    .select('id, title, title_ar, price, total_enrolled, created_at, teacher_id, profiles(name)')
    .eq('is_paid', true)
    .gt('total_enrolled', 0)
    .order('created_at', { ascending: false });

  const unitRevenue = (paidUnits || []).map(u => ({
    id: u.id,
    type: 'unit',
    title: u.title_ar || u.title,
    teacher: (u.profiles as any)?.name || 'Unknown',
    price: u.price,
    enrollments: u.total_enrolled,
    gross: u.price * u.total_enrolled,
    eduflow_share: Math.round(u.price * u.total_enrolled * 0.15 * 100) / 100,
    teacher_receives: Math.round(u.price * u.total_enrolled * 0.85 * 100) / 100,
    date: u.created_at,
  }));

  const sessionRevenue = (paidSessions || []).map(s => ({
    id: s.id,
    type: 'session',
    title: s.title_ar || s.title,
    teacher: (s.profiles as any)?.name || 'Unknown',
    price: s.price,
    enrollments: s.total_enrolled,
    gross: s.price * s.total_enrolled,
    eduflow_share: Math.round(s.price * s.total_enrolled * 0.15 * 100) / 100,
    teacher_receives: Math.round(s.price * s.total_enrolled * 0.85 * 100) / 100,
    date: s.created_at,
  }));

  const all = [...unitRevenue, ...sessionRevenue].sort(
    (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()
  );

  return NextResponse.json({
    rows: all,
    summary: {
      totalGross: Math.round(all.reduce((s, r) => s + r.gross, 0) * 100) / 100,
      totalEduflow: Math.round(all.reduce((s, r) => s + r.eduflow_share, 0) * 100) / 100,
      totalTeachers: Math.round(all.reduce((s, r) => s + r.teacher_receives, 0) * 100) / 100,
      totalTransactions: all.length,
    }
  });
}