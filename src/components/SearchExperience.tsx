"use client";

import { SearchForm } from "@/components/SearchForm";
import { DateHeatmap } from "@/components/DateHeatmap";
import { ResultsBoard } from "@/components/ResultsBoard";
import { BookingPanel } from "@/components/BookingPanel";
import { DEFAULT_SEARCH } from "@/lib/engine";
import { DEFAULT_WALLETS } from "@/lib/tables";
import type { AwardOption, SearchResponse, TripSearch, Wallet } from "@/lib/types";
import { useEffect, useState } from "react";

const SEARCH_KEY = "award-engine-search";
const WALLET_KEY = "award-engine-wallets";

export function SearchExperience() {
  const [search, setSearch] = useState<TripSearch>(DEFAULT_SEARCH);
  const [wallets, setWallets] = useState<Wallet[]>(DEFAULT_WALLETS);
  const [result, setResult] = useState<SearchResponse | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [dateFilter, setDateFilter] = useState<string | null>(null);
  const [picked, setPicked] = useState<AwardOption | null>(null);

  useEffect(() => {
    const storedSearch = localStorage.getItem(SEARCH_KEY);
    const storedWallets = localStorage.getItem(WALLET_KEY);
    if (storedSearch) setSearch(JSON.parse(storedSearch) as TripSearch);
    if (storedWallets) setWallets(JSON.parse(storedWallets) as Wallet[]);
  }, []);

  async function runSearch() {
    setLoading(true);
    setError(null);
    setPicked(null);
    localStorage.setItem(SEARCH_KEY, JSON.stringify(search));
    try {
      const response = await fetch("/api/search", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ ...search, wallets }),
      });
      if (!response.ok) throw new Error("Falha ao consultar o motor");
      const data = (await response.json()) as SearchResponse;
      setResult(data);
      setDateFilter(data.recommendation?.outboundDate ?? null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erro inesperado");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="desk">
      <SearchForm value={search} onChange={setSearch} onSubmit={runSearch} loading={loading} />
      <div className="stack">
        {error ? <p className="banner error">{error}</p> : null}
        {result ? (
          <>
            <div className="alerts">
              {result.alerts.map((alert) => (
                <p key={alert.id} className={`banner ${alert.level}`}>
                  <strong>{alert.title}.</strong> {alert.message}
                </p>
              ))}
            </div>
            <DateHeatmap
              cells={result.heatmap}
              selectedDate={dateFilter ?? undefined}
              onSelect={(date) => setDateFilter(date)}
            />
            <ResultsBoard result={result} dateFilter={dateFilter} onPick={setPicked} />
            <section className="panel quotes">
              <h2>Preço em dinheiro</h2>
              <ul>
                {result.cashQuotes.map((quote) => (
                  <li key={quote.cabin}>
                    {quote.cabin}: US$ {quote.priceUsd.toLocaleString("pt-BR")} ({quote.source})
                  </li>
                ))}
              </ul>
            </section>
          </>
        ) : (
          <section className="panel idle">
            <h2>Pronto para comparar</h2>
            <p>
              Carteiras ativas: {wallets.map((wallet) => `${wallet.programName} ${wallet.milesBalance.toLocaleString("pt-BR")}`).join(" · ")}
            </p>
          </section>
        )}
      </div>
      {picked ? <BookingPanel option={picked} search={search} onClose={() => setPicked(null)} /> : null}
    </div>
  );
}
