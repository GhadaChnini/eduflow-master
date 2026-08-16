import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_APP_PASSWORD,
  },
});

export async function POST(request: NextRequest) {
  const { name, email, applicationId } = await request.json();

  const supabaseAdmin = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
  );

  try {
    const tempPassword = `EduFlow@${Math.random().toString(36).slice(2, 8).toUpperCase()}`;

    const { data: existingUsers } = await supabaseAdmin.auth.admin.listUsers();
    const existingUser = existingUsers?.users?.find((u: any) => u.email === email);

    let userId: string;

    if (existingUser) {
      userId = existingUser.id;
      await supabaseAdmin.auth.admin.updateUserById(userId, { password: tempPassword });
    } else {
      const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
        email,
        password: tempPassword,
        email_confirm: true,
        user_metadata: { name, role: 'teacher' },
      });
      if (createError) throw createError;
      userId = newUser.user.id;
    }

    await supabaseAdmin.from('profiles').upsert({ id: userId, email, name, role: 'teacher', points: 0 });
    await supabaseAdmin.from('teacher_profiles').upsert({ user_id: userId });
    await supabaseAdmin.from('teacher_applications').update({ status: 'approved' }).eq('id', applicationId);

    // Send email with credentials
    await transporter.sendMail({
      from: `"EduFlow" <${process.env.GMAIL_USER}>`,
      to: email,
      subject: '🎉 تهانينا! تم قبولك كأستاذ على EduFlow',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; direction: rtl;">
          <div style="background: linear-gradient(135deg, #7C3AED, #EC4899); padding: 32px; border-radius: 16px 16px 0 0; text-align: center;">
            <h1 style="color: white; margin: 0;">🎉 مبروك!</h1>
            <p style="color: rgba(255,255,255,0.9); margin: 8px 0 0 0;">تم قبولك في منصة EduFlow</p>
          </div>
          <div style="background: white; padding: 32px; border: 1px solid #E9D5FF; border-top: 0; border-radius: 0 0 16px 16px;">
            <p style="font-size: 18px; color: #3B0764; font-weight: bold;">مرحباً ${name}،</p>
            <p style="color: #6B7280; line-height: 1.8;">تم <strong style="color: #059669;">قبول طلبك</strong> للانضمام كأستاذ على منصة EduFlow!</p>
            
            <div style="background: #F0FDF4; border: 2px solid #86EFAC; border-radius: 12px; padding: 20px; margin: 20px 0;">
              <p style="color: #166534; font-weight: bold; font-size: 16px;">✅ بيانات تسجيل الدخول:</p>
              <p style="color: #166534;"><strong>البريد الإلكتروني:</strong> ${email}</p>
              <p style="color: #166534;"><strong>كلمة المرور المؤقتة:</strong> 
                <span style="background: #DCFCE7; padding: 2px 8px; border-radius: 4px; font-family: monospace; font-size: 16px;">${tempPassword}</span>
              </p>
              <p style="color: #6B7280; font-size: 12px; margin-top: 8px;">⚠️ يرجى تغيير كلمة المرور بعد تسجيل الدخول الأول</p>
            </div>

            <div style="background: #EDE9FE; border-radius: 12px; padding: 16px; margin: 20px 0;">
              <p style="color: #3B0764; font-weight: bold;">🚀 ما يمكنك فعله الآن:</p>
              <ul style="color: #6B7280; padding-right: 20px;">
                <li>إنشاء وحدات تعليمية للكفاءات السلوكية</li>
                <li>إدارة جلسات التدريس المباشرة</li>
                <li>متابعة تقدم الطلاب وكسب العائد المادي</li>
              </ul>
            </div>

            <p style="color: #9CA3AF; font-size: 12px; text-align: center; border-top: 1px solid #E9D5FF; padding-top: 16px;">
              فريق EduFlow | منصة تعليم الكفاءات السلوكية للمرحلة الابتدائية التونسية
            </p>
          </div>
        </div>
      `,
    });

    return NextResponse.json({ success: true, tempPassword });
  } catch (error: any) {
    console.error('Approve error:', error);
    return NextResponse.json({ success: false, error: error.message });
  }
}