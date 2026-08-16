import { NextRequest, NextResponse } from 'next/server';
import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_APP_PASSWORD,
  },
});

export async function POST(request: NextRequest) {
  const { to, name, status, reason } = await request.json();

  const isApproved = status === 'approved';

  const subject = isApproved
    ? '🎉 تهانينا! تم قبولك كأستاذ على EduFlow'
    : '📋 بخصوص طلبك للتدريس على EduFlow';

  const html = isApproved
    ? `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; direction: rtl;">
        <div style="background: linear-gradient(135deg, #7C3AED, #EC4899); padding: 32px; border-radius: 16px 16px 0 0; text-align: center;">
          <h1 style="color: white; margin: 0;">🎉 مبروك!</h1>
        </div>
        <div style="background: white; padding: 32px; border: 1px solid #E9D5FF; border-top: 0; border-radius: 0 0 16px 16px;">
          <p style="font-size: 18px; color: #3B0764; font-weight: bold;">مرحباً ${name}،</p>
          <p style="color: #6B7280; line-height: 1.8;">تم <strong style="color: #059669;">قبول طلبك</strong> كأستاذ على EduFlow!</p>
          <div style="background: #F0FDF4; border: 2px solid #86EFAC; border-radius: 12px; padding: 16px; margin: 20px 0;">
            <p style="color: #166534; font-weight: bold;">✅ يمكنك الآن تسجيل الدخول وإنشاء وحداتك التعليمية.</p>
          </div>
          <p style="color: #9CA3AF; font-size: 12px; text-align: center;">فريق EduFlow</p>
        </div>
      </div>
    `
    : `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; direction: rtl;">
        <div style="background: #DC2626; padding: 32px; border-radius: 16px 16px 0 0; text-align: center;">
          <h1 style="color: white; margin: 0;">📋 بخصوص طلبك</h1>
        </div>
        <div style="background: white; padding: 32px; border: 1px solid #FEE2E2; border-top: 0; border-radius: 0 0 16px 16px;">
          <p style="font-size: 18px; color: #3B0764; font-weight: bold;">مرحباً ${name}،</p>
          <p style="color: #6B7280; line-height: 1.8;">نأسف لإخبارك بأنه لم يتم قبول طلبك في الوقت الحالي.</p>
          ${reason ? `
          <div style="background: #FEF2F2; border: 2px solid #FEE2E2; border-radius: 12px; padding: 16px; margin: 20px 0;">
            <p style="color: #DC2626; font-weight: bold;">📌 سبب الرفض:</p>
            <p style="color: #7F1D1D;">${reason}</p>
          </div>
          ` : ''}
          <div style="background: #EDE9FE; border-radius: 12px; padding: 16px; margin: 20px 0;">
            <p style="color: #3B0764; font-weight: bold;">🔄 يمكنك إعادة التقديم!</p>
            <p style="color: #6B7280;">يمكنك تقديم طلب جديد مع مراعاة سبب الرفض وتحسين بياناتك.</p>
          </div>
          <p style="color: #9CA3AF; font-size: 12px; text-align: center;">فريق EduFlow</p>
        </div>
      </div>
    `;

  try {
    await transporter.sendMail({
      from: `"EduFlow" <${process.env.GMAIL_USER}>`,
      to,
      subject,
      html,
    });
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Email error:', error);
    return NextResponse.json({ success: false, error: 'Email failed' });
  }
}