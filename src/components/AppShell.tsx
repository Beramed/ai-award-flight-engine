"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const NAV = [
  { href: "/", label: "Busca", hint: "Motor" },
  { href: "/carteiras", label: "Carteiras", hint: "Milhas" },
  { href: "/tabelas", label: "Tabelas", hint: "Matriz" },
  { href: "/alertas", label: "Alertas", hint: "Emissão" },
];

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  return (
    <div className="app-shell">
      <header className="topbar">
        <Link href="/" className="brand">
          <span className="brand-mark" aria-hidden>
            ✈
          </span>
          <span>
            <strong>Award Engine</strong>
            <small>Tabela fixa × dinâmica</small>
          </span>
        </Link>
        <nav className="desk-nav" aria-label="Principal">
          {NAV.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className={pathname === item.href ? "nav-link active" : "nav-link"}
            >
              {item.label}
            </Link>
          ))}
        </nav>
        <p className="live-pill">
          <span />
          Aprovação humana obrigatória
        </p>
      </header>
      <main className="stage">{children}</main>
      <nav className="mobile-nav" aria-label="Navegação móvel">
        {NAV.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className={pathname === item.href ? "m-link active" : "m-link"}
          >
            <b>{item.label}</b>
            <span>{item.hint}</span>
          </Link>
        ))}
      </nav>
    </div>
  );
}
