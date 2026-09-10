"use client";

import { useEffect, useState } from "react";
import type { AccessPlan } from "@/lib/auth-types";

type UserRow = {
  id: string;
  fullName: string;
  preferredName: string;
  email: string;
  cpfLast4: string;
  role: "user" | "master";
  deletedAt: string | null;
  accessPlan: AccessPlan;
  accessExpiresAt: string | null;
  expired: boolean;
};

const PLANS: { id: AccessPlan; label: string }[] = [
  { id: "indefinite", label: "Indefinido" },
  { id: "7d", label: "7 dias" },
  { id: "1m", label: "1 mês" },
  { id: "6m", label: "6 meses" },
  { id: "1y", label: "1 ano" },
];

export default function MasterPage() {
  const [users, setUsers] = useState<UserRow[]>([]);
  const [error, setError] = useState<string | null>(null);

  async function load() {
    const response = await fetch("/api/master/users");
    const data = (await response.json()) as { users?: UserRow[]; error?: string };
    if (!response.ok) {
      setError(data.error ?? "Sem acesso master.");
      return;
    }
    setUsers(data.users ?? []);
  }

  useEffect(() => {
    void load();
  }, []);

  async function setPlan(id: string, plan: AccessPlan) {
    await fetch("/api/master/users", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id, plan }),
    });
    await load();
  }

  async function remove(id: string) {
    if (!confirm("Apagar este cadastro? O CPF permanece reservado ao nome original.")) return;
    await fetch("/api/auth/delete", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id }),
    });
    await load();
  }

  return (
    <section className="panel">
      <div className="panel-head">
        <h1>Painel master</h1>
        <p>Acesso total. Defina o tempo de uso de cada conta: indefinido, 7 dias, 1 mês, 6 meses ou 1 ano.</p>
      </div>
      {error ? <p className="banner error">{error}</p> : null}
      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Usuário</th>
              <th>E-mail</th>
              <th>CPF</th>
              <th>Prazo</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {users.map((user) => (
              <tr key={user.id}>
                <td>
                  <strong>{user.preferredName}</strong>
                  <div>{user.fullName}</div>
                </td>
                <td>{user.email}</td>
                <td>{user.cpfLast4 ? `***${user.cpfLast4}` : "master"}</td>
                <td>
                  {user.role === "master" ? (
                    "Indefinido"
                  ) : (
                    <select
                      value={user.accessPlan}
                      onChange={(event) => void setPlan(user.id, event.target.value as AccessPlan)}
                    >
                      {PLANS.map((plan) => (
                        <option key={plan.id} value={plan.id}>
                          {plan.label}
                        </option>
                      ))}
                    </select>
                  )}
                  {user.accessExpiresAt ? (
                    <div>
                      <small>até {new Date(user.accessExpiresAt).toLocaleDateString("pt-BR")}</small>
                    </div>
                  ) : null}
                </td>
                <td>
                  {user.deletedAt ? "apagado" : user.expired ? "expirado" : "ativo"}
                </td>
                <td>
                  {user.role === "master" || user.deletedAt ? null : (
                    <button type="button" className="trash icon" onClick={() => void remove(user.id)} aria-label={`Apagar ${user.preferredName}`}>
                      🗑
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}
