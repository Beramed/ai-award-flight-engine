import { registerUser } from "@/lib/user-store";
import { encodeSession, sessionCookie } from "@/lib/session";

export async function POST(request: Request) {
  const body = (await request.json().catch(() => ({}))) as {
    fullName?: string;
    preferredName?: string;
    email?: string;
    country?: string;
    phone?: string;
    address?: string;
    cpf?: string;
    password?: string;
    recover?: boolean;
  };
  const result = registerUser({
    fullName: String(body.fullName ?? ""),
    preferredName: String(body.preferredName ?? ""),
    email: String(body.email ?? ""),
    country: String(body.country ?? ""),
    phone: String(body.phone ?? ""),
    address: String(body.address ?? ""),
    cpf: String(body.cpf ?? ""),
    password: String(body.password ?? ""),
    recover: Boolean(body.recover),
  });
  if ("error" in result) return Response.json(result, { status: 400 });
  if ("recoverable" in result) return Response.json(result);
  const token = encodeSession({
    sub: result.user.id,
    role: result.user.role,
    name: result.user.preferredName,
  });
  return new Response(JSON.stringify(result), {
    status: 201,
    headers: {
      "Content-Type": "application/json",
      "Set-Cookie": sessionCookie(token),
    },
  });
}
