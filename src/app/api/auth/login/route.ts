import { authenticate } from "@/lib/user-store";
import { encodeSession, sessionCookie } from "@/lib/session";

export async function POST(request: Request) {
  const body = (await request.json().catch(() => ({}))) as { login?: string; password?: string };
  const result = authenticate(String(body.login ?? ""), String(body.password ?? ""));
  if ("error" in result) return Response.json(result, { status: 401 });
  const token = encodeSession({
    sub: result.user.id,
    role: result.user.role,
    name: result.user.preferredName,
  });
  return new Response(JSON.stringify({ user: result.user }), {
    headers: {
      "Content-Type": "application/json",
      "Set-Cookie": sessionCookie(token),
    },
  });
}
