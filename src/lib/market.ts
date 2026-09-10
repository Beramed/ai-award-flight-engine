import { getAirport, haversineKm } from "./airports";
import { DYNAMIC_PROGRAMS } from "./tables";
import type { Cabin, CashQuote, DynamicMilesQuote, TripSearch } from "./types";

function fnv(text: string) {
  let hash = 2166136261;
  for (let i = 0; i < text.length; i += 1) {
    hash ^= text.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

function unit(seed: string) {
  return (fnv(seed) % 10000) / 10000;
}

const DISTANCE_KM: Record<string, number> = {
  "GRU-JFK": 7680,
  "GRU-MIA": 6560,
  "GRU-MCO": 6780,
  "GRU-LAX": 9880,
  "GRU-MAD": 8390,
  "GRU-LIS": 7920,
  "GRU-LHR": 9450,
  "GRU-CDG": 9400,
  "GRU-EWR": 7680,
  "GIG-JFK": 7730,
  "GIG-LIS": 7750,
  "GIG-MAD": 8140,
};

function pairKey(origin: string, destination: string) {
  return `${origin}-${destination}`;
}

export function estimateDistanceKm(origin: string, destination: string) {
  const from = getAirport(origin);
  const to = getAirport(destination);
  if (from && to) return Math.round(haversineKm(from, to));
  const direct = DISTANCE_KM[pairKey(origin, destination)];
  if (direct) return direct;
  const reverse = DISTANCE_KM[pairKey(destination, origin)];
  if (reverse) return reverse;
  return 6500;
}

function cabinCashMultiplier(cabin: Cabin) {
  if (cabin === "FIRST") return 4.6;
  if (cabin === "BUSINESS") return 3.35;
  return 1;
}

export function quoteCashMarket(search: TripSearch, cabin: Cabin, date: string): CashQuote {
  const km = estimateDistanceKm(search.origin, search.destination);
  const base = 0.09 * km;
  const season = 0.92 + unit(`season|${date}|${cabin}`) * 0.28;
  const demand = 0.9 + unit(`demand|${search.origin}|${search.destination}|${date}`) * 0.35;
  const priceUsd = Math.round(base * cabinCashMultiplier(cabin) * season * demand);
  const taxesUsd = cabin === "ECONOMY" ? 48 + Math.round(km * 0.004) : 72 + Math.round(km * 0.006);
  return {
    source: "Modelo de mercado (equivalente Google Flights / ITA Matrix)",
    cabin,
    priceUsd,
    taxesUsd,
    currency: "USD",
  };
}

export function quoteDynamicMiles(search: TripSearch, cabin: Cabin, date: string): DynamicMilesQuote[] {
  const km = estimateDistanceKm(search.origin, search.destination);
  const cabinFactor = cabin === "FIRST" ? 2.8 : cabin === "BUSINESS" ? 1.9 : 1;
  return DYNAMIC_PROGRAMS.map((program) => {
    const jitter = 0.85 + unit(`${program.program}|${date}|${cabin}|${search.origin}`) * 0.55;
    const miles = Math.round((km * 8.4 * cabinFactor * jitter) / 500) * 500;
    return {
      program: program.program,
      cabin,
      miles,
      taxesUsd: 40 + Math.round(km * 0.003),
      source: "Estimativa de tabela dinâmica (Smiles / TudoAzul / LATAM Pass)",
    };
  });
}

export function isAwardSeatOpen(params: {
  program: string;
  cabin: Cabin;
  date: string;
  origin: string;
  destination: string;
}) {
  const roll = unit(
    `award|${params.program}|${params.cabin}|${params.date}|${params.origin}|${params.destination}`,
  );
  if (params.cabin === "FIRST") return roll < 0.16;
  if (params.cabin === "BUSINESS") return roll < 0.28;
  return roll < 0.46;
}

export function suggestLayover(origin: string, destination: string, maxHours: number) {
  const from = getAirport(origin);
  const to = getAirport(destination);
  if (!from || !to) return undefined;
  if (from.zoneIds.includes("SA2") && to.zoneIds.includes("NA")) {
    return { airport: "MIA", hours: Math.min(4.5, maxHours) };
  }
  if (from.zoneIds.includes("SA2") && to.zoneIds.includes("EU")) {
    return { airport: destination === "LIS" ? "OPO" : "LIS", hours: Math.min(3.5, maxHours) };
  }
  return undefined;
}

export function officialSearchUrl(origin: string, destination: string, date: string) {
  const query = encodeURIComponent(`Flights from ${origin} to ${destination} on ${date}`);
  return `https://www.google.com/travel/flights?q=${query}`;
}

export function programPortalUrl(program: string) {
  const map: Record<string, string> = {
    AAdvantage: "https://www.aa.com/loyalty/award-travel",
    "Iberia Plus": "https://www.iberia.com/br/iberiaplus/",
    "TAP Miles&Go": "https://www.flytap.com/pt-br/milesandgo",
    Smiles: "https://www.smiles.com.br",
    TudoAzul: "https://tudoazul.voeazul.com.br",
    "LATAM Pass": "https://latampass.latam.com",
  };
  return map[program] ?? "https://www.google.com/travel/flights";
}
