import { getSupabaseAdmin } from '@/lib/supabase';
import { NextResponse, NextRequest } from 'next/server';

export async function GET(req: NextRequest) {
  const supabase = getSupabaseAdmin();
  const ids = req.nextUrl.searchParams.get('ids')?.split(',') || [];
  if (!ids.length) return NextResponse.json([]);

  const { data, error } = await supabase
    .from('profiles')
    .select('id, name, email, role')
    .in('id', ids);

  if (error) return NextResponse.json([]);
  return NextResponse.json(data);
}