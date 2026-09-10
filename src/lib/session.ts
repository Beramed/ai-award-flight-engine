import { createHmac, timingSafeEqual } from "node:crypto";

const COOKIE = "vt_session";

export type SessionPayload = {
  sub: string;
  role: "user" | "master";
  name: string;
  exp: number;
};

function secret() {
  return process.env.SESSION_SECRET ?? "voando-com-tati-session";
}

function sign(value: string) {
  return createHmac("sha256", secret()).update(value).digest("base64url");
}

export function encodeSession(payload: Omit<SessionPayload, "exp">, hours = 24 * 14) {
  const body: SessionPayload = { ...payload, exp: Date.now() + hours * 60 * 60 * 1000 };
  const packed = Buffer.from(JSON.stringify(body)).toString("base64url");
  return `${packed}.${sign(packed)}`;
}

export function decodeSession(token?: string | null): SessionPayload | null {
  if (!token) return null;
  const [packed, signature] = token.split(".");
  if (!packed || !signature) return null;
  const expected = sign(packed);
  const a = Buffer.from(signature);
  const b = Buffer.from(expected);
  if (a.length !== b.length || !timingSafeEqual(a, b)) return null;
  try {
    const payload = JSON.parse(Buffer.from(packed, "base64url").toString("utf8")) as SessionPayload;
    if (payload.exp < Date.now()) return null;
    return payload;
  } catch {
    return null;
  }
}

export function sessionCookie(token: string) {
  const secure = process.env.VERCEL ? "Secure; " : "";
  return `${COOKIE}=${token}; Path=/; HttpOnly; ${secure}SameSite=Lax; Max-Age=${60 * 60 * 24 * 14}`;
}

export function clearSessionCookie() {
  const secure = process.env.VERCEL ? "Secure; " : "";
  return `${COOKIE}=; Path=/; HttpOnly; ${secure}SameSite=Lax; Max-Age=0`;
}

export function readCookie(header: string | null) {
  if (!header) return null;
  const match = header.match(new RegExp(`${COOKIE}=([^;]+)`));
  return match?.[1] ?? null;
}

export { COOKIE as SESSION_COOKIE };
