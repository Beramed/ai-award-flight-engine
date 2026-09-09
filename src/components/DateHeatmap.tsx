"use client";

import type { HeatmapCell } from "@/lib/types";

type Props = {
  cells: HeatmapCell[];
  selectedDate?: string;
  onSelect: (date: string) => void;
};

export function DateHeatmap({ cells, selectedDate, onSelect }: Props) {
  if (!cells.length) return null;
  return (
    <section className="panel">
      <div className="panel-head">
        <h2>Calendário award</h2>
        <p>Verde = classe tarifária fixa aberta. Toque numa data para filtrar.</p>
      </div>
      <div className="heat">
        {cells.map((cell) => (
          <button
            key={cell.date}
            type="button"
            className={`heat-cell ${cell.available ? "open" : "closed"} ${selectedDate === cell.date ? "picked" : ""}`}
            onClick={() => onSelect(cell.date)}
          >
            <span>{cell.date.slice(8)}</span>
            <small>
              {cell.available
                ? `${cell.bestProgram} · ${cell.bestCpm?.toFixed(3)}`
                : "fechado"}
            </small>
          </button>
        ))}
      </div>
    </section>
  );
}
