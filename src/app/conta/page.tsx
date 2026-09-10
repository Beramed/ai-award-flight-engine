"use client";

import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";

type Me = {
  preferredName: string;
  fullName: string;
  email: string;
  country: string;
  phone: string;
  address: string;
  cpfLast4: string;
  role: "user" | "master";
  accessPlan: string;
  accessExpiresAt: string | null;
};

export default function ContaPage() {
  const router = useRouter();
  const [user, setUser] = useState<Me | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    void fetch("/api/auth/me")
      .then((response) => response.json())
      .then((data: { user?: Me }) => setUser(data.user ?? null));
  }, []);

  async function remove() {
    if (!confirm("Apagar seu cadastro? O CPF ficará vinculado a este nome e não poderá ser usado por outra pessoa.")) {
      return;
    }
    const response = await fetch("/api/auth/delete", { method: "POST", headers: { "Content-Type": "application/json" }, body: "{}" });
    const data = (await response.json()) as { error?: string };
    if (!response.ok) {
      setError(data.error ?? "Não foi possível apagar.");
      return;
    }
    router.push("/login");
    router.refresh();
  }

  if (!user) return <section className="panel">Carregando conta…</section>;

  return (
    <section className="panel">
      <div className="panel-head">
        <h1>Olá, {user.preferredName}</h1>
        <p>Seus dados de cadastro. O ícone de lixo apaga a conta, mas o CPF continua reservado para o seu nome.</p>
      </div>
      {error ? <p className="banner error">{error}</p> : null}
      <dl className="account">
        <div>
          <dt>Nome completo</dt>
          <dd>{user.fullName}</dd>
        </div>
        <div>
          <dt>E-mail</dt>
          <dd>{user.email}</dd>
        </div>
        <div>
          <dt>CPF</dt>
          <dd>***{user.cpfLast4 || " master"}</dd>
        </div>
        <div>
          <dt>País</dt>
          <dd>{user.country || "—"}</dd>
        </div>
        <div>
          <dt>Telefone</dt>
          <dd>{user.phone || "—"}</dd>
        </div>
        <div>
          <dt>Endereço</dt>
          <dd>{user.address || "—"}</dd>
        </div>
        <div>
          <dt>Prazo de acesso</dt>
          <dd>
            {user.accessPlan === "indefinite"
              ? "Indefinido"
              : user.accessExpiresAt
                ? new Date(user.accessExpiresAt).toLocaleDateString("pt-BR")
                : user.accessPlan}
          </dd>
        </div>
      </dl>
      {user.role === "master" ? (
        <a className="primary" href="/master">
          Abrir gerenciamento de usuários
        </a>
      ) : (
        <button type="button" className="trash" onClick={() => void remove()} aria-label="Apagar cadastro">
          🗑 Apagar meu cadastro
        </button>
      )}
    </section>
  );
}
