"use client";

import { PlaceSearch } from "@/components/PlaceSearch";
import { DEFAULT_SEARCH } from "@/lib/engine";
import type { Cabin, TripSearch } from "@/lib/types";

const CABIN_OPTIONS: { id: Cabin; label: string }[] = [
  { id: "ECONOMY", label: "Econômica" },
  { id: "BUSINESS", label: "Executiva" },
  { id: "FIRST", label: "Primeira" },
];

type Props = {
  value: TripSearch;
  onChange: (next: TripSearch) => void;
  onSubmit: () => void;
  loading: boolean;
};

export function SearchForm({ value, onChange, onSubmit, loading }: Props) {
  function patch(partial: Partial<TripSearch>) {
    onChange({ ...value, ...partial });
  }

  function toggleCabin(cabin: Cabin) {
    const exists = value.cabins.includes(cabin);
    const cabins = exists ? value.cabins.filter((item) => item !== cabin) : [...value.cabins, cabin];
    patch({ cabins: cabins.length ? cabins : ["ECONOMY"] });
  }

  return (
    <form
      className="search-card"
      onSubmit={(event) => {
        event.preventDefault();
        onSubmit();
      }}
    >
      <div className="search-head">
        <h1>Voando com Tati</h1>
        <p>
          Digite o nome do lugar. A gente sugere os aeroportos mais próximos e os trajetos a partir
          da sua origem, compara milhas e prepara a emissão.
        </p>
      </div>

      <PlaceSearch
        label="Origem"
        value={value.origin}
        onChange={(origin) => patch({ origin })}
        placeholder="Cidade, bairro ou aeroporto"
      />

      <PlaceSearch
        label="Destino"
        value={value.destination}
        originCode={value.origin}
        showRoutes
        onChange={(destination) => patch({ destination })}
        placeholder="Ex.: Disney, Lisboa, Manhattan"
      />

      <label className="check">
        <input
          type="checkbox"
          checked={value.flexible}
          onChange={(event) => patch({ flexible: event.target.checked })}
        />
        Datas flexíveis no intervalo
      </label>

      <div className="grid-3">
        <label>
          Início
          <input
            type="date"
            value={value.dateStart}
            onChange={(event) => patch({ dateStart: event.target.value })}
          />
        </label>
        <label>
          Fim
          <input
            type="date"
            value={value.dateEnd}
            onChange={(event) => patch({ dateEnd: event.target.value })}
          />
        </label>
        <label>
          Noites
          <input
            type="number"
            min={1}
            max={30}
            value={value.stayDays}
            onChange={(event) => patch({ stayDays: Number(event.target.value) })}
          />
        </label>
      </div>

      <div className="grid-3">
        <label>
          Adultos
          <input
            type="number"
            min={1}
            max={9}
            value={value.adults}
            onChange={(event) => patch({ adults: Number(event.target.value) })}
          />
        </label>
        <label>
          Crianças
          <input
            type="number"
            min={0}
            max={8}
            value={value.children}
            onChange={(event) => patch({ children: Number(event.target.value) })}
          />
        </label>
        <label>
          Bebês
          <input
            type="number"
            min={0}
            max={4}
            value={value.infants}
            onChange={(event) => patch({ infants: Number(event.target.value) })}
          />
        </label>
      </div>

      <fieldset>
        <legend>Cabine</legend>
        <div className="pills">
          {CABIN_OPTIONS.map((cabin) => (
            <button
              type="button"
              key={cabin.id}
              className={value.cabins.includes(cabin.id) ? "pill on" : "pill"}
              onClick={() => toggleCabin(cabin.id)}
            >
              {cabin.label}
            </button>
          ))}
        </div>
      </fieldset>

      <div className="grid-2">
        <label className="check">
          <input
            type="checkbox"
            checked={value.allowLayovers}
            onChange={(event) => patch({ allowLayovers: event.target.checked })}
          />
          Permitir conexão
        </label>
        <label>
          Conexão máx. (h)
          <input
            type="number"
            min={1}
            max={24}
            value={value.maxLayoverHours}
            onChange={(event) => patch({ maxLayoverHours: Number(event.target.value) })}
          />
        </label>
      </div>

      <div className="actions">
        <button type="submit" className="primary" disabled={loading}>
          {loading ? "Calculando rotas…" : "Buscar passagens"}
        </button>
        <button type="button" className="ghost" onClick={() => onChange(DEFAULT_SEARCH)}>
          São Paulo → Nova York
        </button>
      </div>
    </form>
  );
}
