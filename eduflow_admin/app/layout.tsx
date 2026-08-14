import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'EduFlow Admin',
  description: 'EduFlow Admin Panel',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ar" dir="rtl">
      <body className="bg-gray-50">{children}</body>
    </html>
  );
}