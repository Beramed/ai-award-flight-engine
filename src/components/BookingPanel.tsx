"use client";

import { buildBookingKit } from "@/lib/booking";
import type { AwardOption, TripSearch } from "@/lib/types";
import { useMemo, useState } from "react";

type Props = {
  option: AwardOption;
  search: TripSearch;
  onClose: () => void;
};

const ALERTS_KEY = "award-engine-alerts";

export function BookingPanel({ option, search, onClose }: Props) {
  const [approved, setApproved] = useState(false);
  const [saved, setSaved] = useState(false);
  const kit = useMemo(() => buildBookingKit(option, search), [option, search]);

  function persistAlert() {
    const payload = {
      id: `${option.id}-${Date.now()}`,
      createdAt: new Date().toISOString(),
      option,
      script: kit.callCenterScript,
      approved,
    };
    const current = JSON.parse(localStorage.getItem(ALERTS_KEY) ?? "[]") as unknown[];
    localStorage.setItem(ALERTS_KEY, JSON.stringify([payload, ...current].slice(0, 30)));
    setSaved(true);
  }

  return (
    <aside className="drawer" role="dialog" aria-labelledby="emit-title">
      <div className="drawer-bar">
        <h2 id="emit-title">Fluxo de emissão</h2>
        <button type="button" className="ghost" onClick={onClose}>
          Fechar
        </button>
      </div>
      <p className="eyebrow">
        {option.program} · classe {option.fareClass} · {option.tableType === "FIXED" ? "fixa" : "dinâmica"}
      </p>
      <p>
        {search.origin} → {search.destination}
        {option.layover ? ` via ${option.layover.airport} (${option.layover.hours}h)` : ""} ·{" "}
        {option.outboundDate} / {option.inboundDate}
      </p>

      <ol className="checks">
        {kit.checklist.map((item) => (
          <li key={item}>{item}</li>
        ))}
      </ol>

      <label className="check approve">
        <input
          type="checkbox"
          checked={approved}
          onChange={(event) => setApproved(event.target.checked)}
        />
        Aprovo esta emissão. O app não cobra cartão sozinho — taxas são pagas no portal oficial.
      </label>

      <div className="actions wrap">
        <a className={`primary ${approved ? "" : "disabled"}`} href={approved ? kit.officialSearchUrl : undefined} target="_blank" rel="noreferrer">
          Abrir portal oficial
        </a>
        <a
          className={approved ? "ghost" : "ghost disabled"}
          href={approved ? `https://wa.me/?text=${kit.whatsappText}` : undefined}
          target="_blank"
          rel="noreferrer"
        >
          WhatsApp
        </a>
        <button type="button" className="ghost" onClick={persistAlert} disabled={!approved}>
          Guardar alerta
        </button>
      </div>

      {kit.requiresPhone ? (
        <section className="script">
          <h3>Script call center</h3>
          <p>{kit.callCenterScript}</p>
        </section>
      ) : (
        <p className="note">Emissão web no programa. Confira a classe {option.fareClass} antes de confirmar.</p>
      )}

      {saved ? <p className="note success">Alerta salvo em Alertas neste aparelho.</p> : null}
    </aside>
  );
}
