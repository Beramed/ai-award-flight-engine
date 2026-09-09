"use client";

import type { AwardOption, SearchResponse } from "@/lib/types";

const CABIN_LABEL: Record<string, string> = {
  ECONOMY: "Econômica",
  BUSINESS: "Executiva",
  FIRST: "Primeira",
};

type Props = {
  result: SearchResponse;
  dateFilter: string | null;
  onPick: (option: AwardOption) => void;
};

export function ResultsBoard({ result, dateFilter, onPick }: Props) {
  const options = dateFilter
    ? result.options.filter((option) => option.outboundDate === dateFilter)
    : result.options.slice(0, 12);

  return (
    <section className="panel">
      <div className="panel-head">
        <h2>Decisão do motor</h2>
        <p>
          CPM = (preço em dinheiro − taxas) / milhas. Limiar de excelência:{" "}
          {result.cpmThresholdUsd.toFixed(3)} USD por milha.
        </p>
      </div>

      {result.recommendation ? (
        <article className="ticket featured">
          <div>
            <p className="eyebrow">Recomendação</p>
            <h3>
              {result.recommendation.program} · {CABIN_LABEL[result.recommendation.cabin]}
            </h3>
            <p>
              {result.recommendation.outboundDate} → {result.recommendation.inboundDate} · classe{" "}
              {result.recommendation.fareClass} · {result.recommendation.tableType === "FIXED" ? "Tabela fixa" : "Dinâmica"}
            </p>
          </div>
          <dl className="metrics">
            <div>
              <dt>Milhas</dt>
              <dd>{result.recommendation.miles.toLocaleString("pt-BR")}</dd>
            </div>
            <div>
              <dt>CPM</dt>
              <dd>{result.recommendation.cpm.toFixed(3)}</dd>
            </div>
            <div>
              <dt>Taxas</dt>
              <dd>US$ {result.recommendation.taxesUsd.toFixed(0)}</dd>
            </div>
          </dl>
          <button type="button" className="primary" onClick={() => onPick(result.recommendation!)}>
            Preparar emissão
          </button>
        </article>
      ) : null}

      <ul className="option-list">
        {options.map((option) => (
          <li key={option.id} className={`option ${option.decision.toLowerCase()}`}>
            <div>
              <strong>
                {option.program} · {CABIN_LABEL[option.cabin]}
              </strong>
              <p>
                {option.outboundDate} / {option.inboundDate} · {option.miles.toLocaleString("pt-BR")}{" "}
                milhas · CPM {option.cpm.toFixed(3)} · {option.awardAvailable ? "vaga aberta" : "fechado"}
              </p>
              <p className="reason">{option.reasons[0]}</p>
            </div>
            <button type="button" className="ghost" onClick={() => onPick(option)}>
              Emitir
            </button>
          </li>
        ))}
      </ul>
    </section>
  );
}
