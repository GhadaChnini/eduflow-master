import { getSupabaseAdmin } from '@/lib/supabase';
import { NextResponse, NextRequest } from 'next/server';

export async function GET(req: NextRequest) {
  const supabase = getSupabaseAdmin();
  const senderId = req.nextUrl.searchParams.get('sender_id');

  let query = supabase
    .from('support_messages')
    .select('*')
    .order('created_at', { ascending: true });

  if (senderId) {
    query = query.eq('sender_id', senderId);
  } else {
    query = query.eq('is_from_admin', false);
  }

  const { data, error } = await query;
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json(data);
}

export async function POST(req: Request) {
  const supabase = getSupabaseAdmin();
  const body = await req.json();

  const { data, error } = await supabase
    .from('support_messages')
    .insert(body)
    .select()
    .single();

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  if (body.is_from_admin) {
    await supabase.from('notifications').insert({
      user_id: body.sender_id,
      title: '💬 Reply from support team',
      body: body.content.substring(0, 100),
      type: 'support',
    });
  }

  return NextResponse.json(data);
}