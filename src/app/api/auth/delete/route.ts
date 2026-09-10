import { decodeSession, readCookie, clearSessionCookie } from "@/lib/session";
import { deleteUser } from "@/lib/user-store";

export async function POST(request: Request) {
  const session = decodeSession(readCookie(request.headers.get("cookie")));
  if (!session) return Response.json({ error: "Não autenticado." }, { status: 401 });
  const body = (await request.json().catch(() => ({}))) as { id?: string };
  const targetId = body.id ?? session.sub;
  const result = deleteUser(targetId, { id: session.sub, role: session.role });
  if ("error" in result) return Response.json(result, { status: 400 });
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (targetId === session.sub) headers["Set-Cookie"] = clearSessionCookie();
  return new Response(JSON.stringify({ ok: true }), { headers });
}
