import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const response = NextResponse.next();
  
  // Aggressive no-cache headers for auth pages
  if (request.nextUrl.pathname.startsWith('/auth/') || request.nextUrl.pathname === '/dashboard') {
    response.headers.set('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0');
    response.headers.set('Pragma', 'no-cache');
    response.headers.set('Expires', '0');
    response.headers.set('X-Accel-Expires', '0');
  }
  
  return response;
}

export const config = {
  matcher: ['/auth/:path*', '/dashboard/:path*'],
};
