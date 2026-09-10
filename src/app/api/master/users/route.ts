import { decodeSession, readCookie } from "@/lib/session";
import { listUsers, setUserAccess, type AccessPlan } from "@/lib/user-store";

function requireMaster(request: Request) {
  const session = decodeSession(readCookie(request.headers.get("cookie")));
  if (!session || session.role !== "master") return null;
  return session;
}

export async function GET(request: Request) {
  if (!requireMaster(request)) return Response.json({ error: "Acesso master necessário." }, { status: 403 });
  return Response.json({ users: listUsers() });
}

export async function POST(request: Request) {
  if (!requireMaster(request)) return Response.json({ error: "Acesso master necessário." }, { status: 403 });
  const body = (await request.json().catch(() => ({}))) as { id?: string; plan?: AccessPlan };
  const plans: AccessPlan[] = ["indefinite", "7d", "1m", "6m", "1y"];
  if (!body.id || !body.plan || !plans.includes(body.plan)) {
    return Response.json({ error: "Dados inválidos." }, { status: 400 });
  }
  const result = setUserAccess(body.id, body.plan);
  if ("error" in result) return Response.json(result, { status: 400 });
  return Response.json(result);
}
