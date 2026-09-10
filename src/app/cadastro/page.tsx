"use client";

import { formatCpf } from "@/lib/cpf";
import { PASSWORD_RULE } from "@/lib/password-rules";
import { useRouter } from "next/navigation";
import { useState } from "react";

const COUNTRIES = ["Brasil", "Portugal", "Estados Unidos", "Espanha", "França", "Itália", "Argentina", "Chile", "Outro"];

type FormState = {
  fullName: string;
  preferredName: string;
  cpf: string;
  country: string;
  phone: string;
  email: string;
  address: string;
  password: string;
};

const EMPTY: FormState = {
  fullName: "",
  preferredName: "",
  cpf: "",
  country: "Brasil",
  phone: "",
  email: "",
  address: "",
  password: "",
};

export default function CadastroPage() {
  const router = useRouter();
  const [form, setForm] = useState(EMPTY);
  const [error, setError] = useState<string | null>(null);
  const [recoverable, setRecoverable] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  function patch<K extends keyof FormState>(key: K, value: FormState[K]) {
    setForm((current) => ({ ...current, [key]: value }));
  }

  async function submit(recover = false) {
    setLoading(true);
    setError(null);
    const response = await fetch("/api/auth/register", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ ...form, recover }),
    });
    const data = (await response.json()) as { error?: string; recoverable?: boolean; message?: string };
    setLoading(false);
    if (data.recoverable) {
      setRecoverable(data.message ?? "Deseja recuperar a conta antiga?");
      return;
    }
    if (!response.ok) {
      setError(data.error ?? "Não foi possível cadastrar.");
      return;
    }
    router.push("/");
    router.refresh();
  }

  return (
    <form
      className="search-card auth-card"
      onSubmit={(event) => {
        event.preventDefault();
        void submit(false);
      }}
    >
      <div className="search-head">
        <h1>Cadastro</h1>
        <p>CPF único. Se a conta foi apagada, o mesmo CPF só volta no mesmo nome, com opção de recuperação.</p>
      </div>
      {error ? <p className="banner error">{error}</p> : null}
      {recoverable ? (
        <div className="banner warning">
          <p>{recoverable}</p>
          <div className="actions">
            <button type="button" className="primary" onClick={() => void submit(true)} disabled={loading}>
              Recuperar conta antiga
            </button>
            <button type="button" className="ghost" onClick={() => setRecoverable(null)}>
              Cancelar
            </button>
          </div>
        </div>
      ) : null}
      <label>
        Nome completo
        <input value={form.fullName} onChange={(event) => patch("fullName", event.target.value)} required />
      </label>
      <label>
        Como gostaria de ser chamado
        <input value={form.preferredName} onChange={(event) => patch("preferredName", event.target.value)} required />
      </label>
      <label>
        CPF
        <input value={form.cpf} onChange={(event) => patch("cpf", formatCpf(event.target.value))} required />
      </label>
      <label>
        País
        <select value={form.country} onChange={(event) => patch("country", event.target.value)}>
          {COUNTRIES.map((country) => (
            <option key={country}>{country}</option>
          ))}
        </select>
      </label>
      <label>
        Telefone
        <input value={form.phone} onChange={(event) => patch("phone", event.target.value)} required />
      </label>
      <label>
        E-mail
        <input type="email" value={form.email} onChange={(event) => patch("email", event.target.value)} required />
      </label>
      <label>
        Endereço
        <input value={form.address} onChange={(event) => patch("address", event.target.value)} required />
      </label>
      <label>
        Senha
        <input
          type="password"
          value={form.password}
          onChange={(event) => patch("password", event.target.value)}
          minLength={8}
          maxLength={16}
          required
        />
        <small>{PASSWORD_RULE}</small>
      </label>
      <div className="actions">
        <button className="primary" type="submit" disabled={loading}>
          {loading ? "Salvando…" : "Cadastrar"}
        </button>
        <a className="ghost" href="/login">
          Já tenho conta
        </a>
      </div>
    </form>
  );
}
