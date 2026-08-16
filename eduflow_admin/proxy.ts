import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function proxy(request: NextRequest) {
  const adminToken = request.cookies.get('admin_token')?.value;
  const isLoginPage = request.nextUrl.pathname === '/login';

  if (!adminToken && !isLoginPage) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  if (adminToken && isLoginPage) {
    return NextResponse.redirect(new URL('/', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};