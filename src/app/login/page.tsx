"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useState } from "react";

function LoginForm() {
  const router = useRouter();
  const next = useSearchParams().get("next") ?? "/";
  const [login, setLogin] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function submit(event: React.FormEvent) {
    event.preventDefault();
    setLoading(true);
    setError(null);
    const response = await fetch("/api/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ login, password }),
    });
    const data = (await response.json()) as { error?: string };
    setLoading(false);
    if (!response.ok) {
      setError(data.error ?? "Não foi possível entrar.");
      return;
    }
    router.push(next);
    router.refresh();
  }

  return (
    <form className="search-card auth-card" onSubmit={submit}>
      <div className="search-head">
        <h1>Entrar</h1>
        <p>Use o nome de como quer ser chamado, o e-mail ou o acesso master.</p>
      </div>
      {error ? <p className="banner error">{error}</p> : null}
      <label>
        Nome ou e-mail
        <input value={login} onChange={(event) => setLogin(event.target.value)} autoComplete="username" />
      </label>
      <label>
        Senha
        <input
          type="password"
          value={password}
          onChange={(event) => setPassword(event.target.value)}
          autoComplete="current-password"
        />
      </label>
      <div className="actions">
        <button className="primary" type="submit" disabled={loading}>
          {loading ? "Entrando…" : "Entrar"}
        </button>
        <a className="ghost" href="/cadastro">
          Criar cadastro
        </a>
      </div>
    </form>
  );
}

export default function LoginPage() {
  return (
    <Suspense>
      <LoginForm />
    </Suspense>
  );
}
