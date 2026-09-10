"use client";

import { airportLabel } from "@/lib/airports";
import { searchPlaces, type AirportHit, type PlaceHit } from "@/lib/places";
import { useEffect, useId, useMemo, useRef, useState } from "react";

type Props = {
  label: string;
  value: string;
  onChange: (code: string) => void;
  originCode?: string;
  placeholder: string;
  showRoutes?: boolean;
};

export function PlaceSearch({ label, value, onChange, originCode, placeholder, showRoutes }: Props) {
  const listId = useId();
  const rootRef = useRef<HTMLDivElement>(null);
  const [query, setQuery] = useState("");
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState(false);

  const results = useMemo(
    () => searchPlaces(editing ? query : "", { originCode, role: showRoutes ? "destination" : "origin" }),
    [editing, query, originCode, showRoutes],
  );

  useEffect(() => {
    function onDoc(event: MouseEvent) {
      if (!rootRef.current?.contains(event.target as Node)) {
        setOpen(false);
        setEditing(false);
      }
    }
    document.addEventListener("mousedown", onDoc);
    return () => document.removeEventListener("mousedown", onDoc);
  }, []);

  function pickAirport(code: string) {
    onChange(code);
    setQuery("");
    setEditing(false);
    setOpen(false);
  }

  const display = editing ? query : airportLabel(value);

  return (
    <div className="place-search" ref={rootRef}>
      <label>
        {label}
        <input
          role="combobox"
          aria-expanded={open}
          aria-controls={listId}
          aria-autocomplete="list"
          autoComplete="off"
          placeholder={placeholder}
          value={display}
          onChange={(event) => {
            setEditing(true);
            setQuery(event.target.value);
            setOpen(true);
          }}
          onFocus={() => {
            setOpen(true);
            setEditing(true);
            setQuery("");
          }}
        />
      </label>

      {open ? (
        <div className="suggest" id={listId} role="listbox">
          {showRoutes && results.routes.length ? (
            <p className="suggest-label">Trajetos sugeridos</p>
          ) : null}
          {showRoutes
            ? results.routes.map((route) => (
                <button
                  type="button"
                  key={`${route.origin.code}-${route.destination.code}`}
                  className="suggest-item"
                  role="option"
                  onClick={() => pickAirport(route.destination.code)}
                >
                  <strong>
                    {route.origin.code} → {route.destination.code}
                  </strong>
                  <span>
                    {route.destination.city} · {route.km.toLocaleString("pt-BR")} km
                    {route.via ? ` · via ${route.via}` : ""}
                  </span>
                </button>
              ))
            : null}

          {results.places.length ? <p className="suggest-label">Lugares e aeroportos próximos</p> : null}
          {results.places.map((hit) => (
            <PlaceOptions key={hit.place.id} hit={hit} onPick={pickAirport} />
          ))}

          {results.airports.length ? <p className="suggest-label">Aeroportos</p> : null}
          {results.airports.map((hit) => (
            <AirportOption key={hit.airport.code} hit={hit} onPick={pickAirport} />
          ))}

          {!results.places.length && !results.airports.length ? (
            <p className="suggest-empty">Nenhum lugar encontrado. Tente a cidade, o ponto turístico ou o código IATA.</p>
          ) : null}
        </div>
      ) : null}
    </div>
  );
}

function PlaceOptions({ hit, onPick }: { hit: PlaceHit; onPick: (code: string) => void }) {
  return (
    <div className="suggest-place">
      <p>
        <strong>{hit.place.name}</strong>
        <span> · {hit.place.region}</span>
      </p>
      {hit.airports.map((item) => (
        <button
          type="button"
          key={item.airport.code}
          className="suggest-item nested"
          role="option"
          onClick={() => onPick(item.airport.code)}
        >
          <strong>
            {item.airport.code} · {item.airport.name}
          </strong>
          <span>
            {item.km} km de {hit.place.name}
          </span>
        </button>
      ))}
    </div>
  );
}

function AirportOption({ hit, onPick }: { hit: AirportHit; onPick: (code: string) => void }) {
  return (
    <button
      type="button"
      className="suggest-item"
      role="option"
      onClick={() => onPick(hit.airport.code)}
    >
      <strong>
        {hit.airport.code} · {hit.airport.city}
      </strong>
      <span>{hit.airport.name}</span>
    </button>
  );
}
