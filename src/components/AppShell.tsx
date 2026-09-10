"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useState } from "react";

const NAV = [
  { href: "/", label: "Busca", hint: "Motor" },
  { href: "/carteiras", label: "Carteiras", hint: "Milhas" },
  { href: "/tabelas", label: "Tabelas", hint: "Matriz" },
  { href: "/alertas", label: "Alertas", hint: "Emissão" },
  { href: "/conta", label: "Conta", hint: "Perfil" },
];

type Me = { preferredName: string; role: "user" | "master" };

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [mounted, setMounted] = useState(false);
  const [user, setUser] = useState<Me | null>(null);
  useEffect(() => setMounted(true), []);
  useEffect(() => {
    void fetch("/api/auth/me")
      .then((response) => (response.ok ? response.json() : { user: null }))
      .then((data: { user?: Me | null }) => setUser(data.user ?? null));
  }, [pathname]);
  const current = mounted ? pathname : "";
  const authPage = pathname === "/login" || pathname === "/cadastro";
  const items = user?.role === "master" ? [...NAV, { href: "/master", label: "Master", hint: "Painel" }] : NAV;

  async function logout() {
    await fetch("/api/auth/logout", { method: "POST" });
    setUser(null);
    router.push("/login");
    router.refresh();
  }

  return (
    <div className="app-shell">
      <div className="sky" aria-hidden />
      <header className="topbar">
        <Link href="/" className="brand">
          <span className="brand-mark" aria-hidden>
            ✈
          </span>
          <span>
            <strong>Voando com Tati</strong>
            <small>Milhas e destinos</small>
          </span>
        </Link>
        {!authPage ? (
          <nav className="desk-nav" aria-label="Principal">
            {items.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className={current === item.href ? "nav-link active" : "nav-link"}
              >
                {item.label}
              </Link>
            ))}
          </nav>
        ) : null}
        <p className="live-pill">
          {user ? (
            <>
              <span />
              {user.preferredName}
              <button type="button" className="ghost" onClick={() => void logout()}>
                Sair
              </button>
            </>
          ) : (
            <>
              <span />
              Aprovação humana obrigatória
            </>
          )}
        </p>
      </header>
      <main className="stage">{children}</main>
      {!authPage ? (
        <nav className="mobile-nav" aria-label="Navegação móvel">
          {items.slice(0, 5).map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className={current === item.href ? "m-link active" : "m-link"}
            >
              <b>{item.label}</b>
              <span>{item.hint}</span>
            </Link>
          ))}
        </nav>
      ) : null}
    </div>
  );
}
