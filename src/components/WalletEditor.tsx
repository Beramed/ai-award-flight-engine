"use client";

import { DEFAULT_WALLETS } from "@/lib/tables";
import type { Wallet } from "@/lib/types";
import { useEffect, useState } from "react";

const WALLET_KEY = "award-engine-wallets";

export function WalletEditor() {
  const [wallets, setWallets] = useState<Wallet[]>(DEFAULT_WALLETS);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    const stored = localStorage.getItem(WALLET_KEY);
    if (!stored) return;
    const parsed = JSON.parse(stored) as Wallet[];
    const byName = new Map(parsed.map((wallet) => [wallet.programName, wallet]));
    setWallets(DEFAULT_WALLETS.map((wallet) => byName.get(wallet.programName) ?? wallet));
  }, []);

  function update(index: number, milesBalance: number) {
    setWallets((current) =>
      current.map((wallet, i) => (i === index ? { ...wallet, milesBalance } : wallet)),
    );
    setSaved(false);
  }

  function persist() {
    localStorage.setItem(WALLET_KEY, JSON.stringify(wallets));
    setSaved(true);
  }

  return (
    <div className="stack">
      <section className="panel">
        <div className="panel-head">
          <h1>Carteiras de milhas</h1>
          <p>
            Saldos usados pelo motor. Referências de cofre ficam só como identificador — senhas de
            companhia não entram neste app.
          </p>
        </div>
        <ul className="wallets">
          {wallets.map((wallet, index) => (
            <li key={wallet.programName} className="wallet">
              <div>
                <strong>{wallet.programName}</strong>
                <p>
                  {wallet.airline} · {wallet.alliance}
                </p>
                <small>cofre: {wallet.credentialsRef}</small>
              </div>
              <label>
                Saldo
                <input
                  type="number"
                  min={0}
                  step={500}
                  value={wallet.milesBalance}
                  onChange={(event) => update(index, Number(event.target.value))}
                />
              </label>
            </li>
          ))}
        </ul>
        <div className="actions">
          <button type="button" className="primary" onClick={persist}>
            Salvar neste aparelho
          </button>
          <button
            type="button"
            className="ghost"
            onClick={() => {
              setWallets(DEFAULT_WALLETS);
              localStorage.setItem(WALLET_KEY, JSON.stringify(DEFAULT_WALLETS));
              setSaved(true);
            }}
          >
            Restaurar exemplo
          </button>
        </div>
        {saved ? <p className="note success">Carteiras atualizadas. A próxima busca já usa estes saldos.</p> : null}
      </section>
    </div>
  );
}
