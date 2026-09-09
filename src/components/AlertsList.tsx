"use client";

import type { AwardOption } from "@/lib/types";
import { useEffect, useState } from "react";

type StoredAlert = {
  id: string;
  createdAt: string;
  approved: boolean;
  script: string;
  option: AwardOption;
};

export function AlertsList() {
  const [items, setItems] = useState<StoredAlert[]>([]);

  useEffect(() => {
    const stored = localStorage.getItem("award-engine-alerts");
    if (stored) setItems(JSON.parse(stored) as StoredAlert[]);
  }, []);

  function clearAll() {
    localStorage.removeItem("award-engine-alerts");
    setItems([]);
  }

  return (
    <div className="stack">
      <section className="panel">
        <div className="panel-head">
          <h1>Alertas e scripts</h1>
          <p>Emissões que você aprovou ficam neste aparelho para ligar ao call center ou reabrir o portal.</p>
        </div>
        {items.length ? (
          <>
            <ul className="option-list">
              {items.map((item) => (
                <li key={item.id} className="option alternative">
                  <div>
                    <strong>
                      {item.option.program} · {item.option.cabin} · {item.option.outboundDate}
                    </strong>
                    <p>{item.script}</p>
                    <small>{new Date(item.createdAt).toLocaleString("pt-BR")}</small>
                  </div>
                </li>
              ))}
            </ul>
            <button type="button" className="ghost" onClick={clearAll}>
              Limpar alertas
            </button>
          </>
        ) : (
          <p className="note">Nenhum alerta ainda. Rode uma busca e aprove uma emissão.</p>
        )}
      </section>
    </div>
  );
}
