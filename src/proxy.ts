import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { decodeSession, readCookie } from "./lib/session";

const PUBLIC = [
  "/login",
  "/cadastro",
  "/api/auth/login",
  "/api/auth/register",
  "/mapa-rotas.png",
  "/icon.svg",
  "/sw.js",
  "/manifest.webmanifest",
];

export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  if (
    pathname.startsWith("/_next") ||
    pathname.startsWith("/favicon") ||
    PUBLIC.some((path) => pathname === path || pathname.startsWith(`${path}/`))
  ) {
    return NextResponse.next();
  }

  const session = decodeSession(readCookie(request.headers.get("cookie")));
  if (!session) {
    if (pathname.startsWith("/api/")) {
      return NextResponse.json({ error: "Faça login." }, { status: 401 });
    }
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    url.searchParams.set("next", pathname);
    return NextResponse.redirect(url);
  }

  if (pathname.startsWith("/master") || pathname.startsWith("/api/master")) {
    if (session.role !== "master") {
      return NextResponse.redirect(new URL("/", request.url));
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!_next/static|_next/image).*)"],
};
