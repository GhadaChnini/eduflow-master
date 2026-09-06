import { getSupabaseAdmin } from '@/lib/supabase';
import { NextResponse } from 'next/server';

export async function GET() {
  const supabase = getSupabaseAdmin();

  const [
    { count: users },
    { count: teachers },
    { count: students },
    { count: units },
    { count: pending },
  ] = await Promise.all([
    supabase.from('profiles').select('*', { count: 'exact', head: true }),
    supabase.from('profiles').select('*', { count: 'exact', head: true }).eq('role', 'teacher'),
    supabase.from('profiles').select('*', { count: 'exact', head: true }).eq('role', 'parent'),
    supabase.from('behavioral_units').select('*', { count: 'exact', head: true }),
    supabase.from('teacher_applications').select('*', { count: 'exact', head: true }).eq('status', 'pending'),
  ]);

  // Calculate EduFlow revenue: 10% from student + 5% from teacher = 15% of price per enrollment
  let eduflowRevenue = 0;
  try {
    const { data: paidUnits } = await supabase
      .from('behavioral_units')
      .select('price, total_enrolled')
      .eq('is_free', false);
    const { data: paidSessions } = await supabase
      .from('live_sessions')
      .select('price, total_enrolled')
      .eq('is_paid', true);

    for (const u of paidUnits || []) {
      eduflowRevenue += (u.price || 0) * (u.total_enrolled || 0) * 0.15;
    }
    for (const s of paidSessions || []) {
      eduflowRevenue += (s.price || 0) * (s.total_enrolled || 0) * 0.15;
    }
  } catch (_) {}

  return NextResponse.json({
    users: users || 0,
    teachers: teachers || 0,
    students: students || 0,
    units: units || 0,
    pending: pending || 0,
    eduflowRevenue: Math.round(eduflowRevenue * 100) / 100,
  });
}