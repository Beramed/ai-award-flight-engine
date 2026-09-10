import { decodeSession, readCookie } from "@/lib/session";
import { getUserById } from "@/lib/user-store";

export async function GET(request: Request) {
  const session = decodeSession(readCookie(request.headers.get("cookie")));
  if (!session) return Response.json({ user: null }, { status: 401 });
  const user = getUserById(session.sub);
  if (!user || user.deletedAt) return Response.json({ user: null }, { status: 401 });
  if (user.expired) return Response.json({ error: "Acesso expirado." }, { status: 403 });
  return Response.json({ user });
}
