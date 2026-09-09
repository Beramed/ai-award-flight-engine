import { getAirport } from "./airports";
import {
  isAwardSeatOpen,
  officialSearchUrl,
  quoteCashMarket,
  quoteDynamicMiles,
  suggestLayover,
} from "./market";
import { CPM_EXCELLENT_USD, FIXED_TABLES } from "./tables";
import type {
  AwardOption,
  Cabin,
  FixedTable,
  HeatmapCell,
  SearchResponse,
  TripSearch,
  UserAlert,
  Wallet,
} from "./types";

const CABIN_KEYS: Record<Cabin, string[]> = {
  ECONOMY: ["economy_off_peak", "economy"],
  BUSINESS: ["business_off_peak", "business"],
  FIRST: ["first"],
};

function addDays(iso: string, days: number) {
  const date = new Date(`${iso}T12:00:00Z`);
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
}

function eachDate(start: string, end: string) {
  const dates: string[] = [];
  let cursor = start;
  while (cursor <= end) {
    dates.push(cursor);
    cursor = addDays(cursor, 1);
  }
  return dates;
}

function zonesMatch(table: FixedTable, origin: string, destination: string) {
  const from = getAirport(origin);
  const to = getAirport(destination);
  if (!from || !to) return false;
  const originOk = table.originZoneIds.some((zone) => from.zoneIds.includes(zone));
  const destOk = table.destinationZoneIds.some((zone) => to.zoneIds.includes(zone));
  return originOk && destOk;
}

function milesForCabin(table: FixedTable, cabin: Cabin, date: string) {
  const month = Number(date.slice(5, 7));
  const peak = month === 7 || month === 8 || month === 12;
  if (cabin === "BUSINESS" && table.fixedRatesMiles.business_peak && peak) {
    return table.fixedRatesMiles.business_peak;
  }
  for (const key of CABIN_KEYS[cabin]) {
    const value = table.fixedRatesMiles[key];
    if (typeof value === "number") return value;
  }
  return null;
}

function fareClassFor(table: FixedTable, cabin: Cabin) {
  if (cabin === "ECONOMY") return table.awardFareClasses.economy ?? "X";
  if (cabin === "BUSINESS") return table.awardFareClasses.business ?? "I";
  return table.awardFareClasses.first ?? "Z";
}

export function calculateCpm(cashUsd: number, taxesUsd: number, miles: number) {
  if (miles <= 0) return 0;
  return Number(((cashUsd - taxesUsd) / miles).toFixed(4));
}

function scoreOption(option: AwardOption) {
  let score = option.cpm * 1000;
  if (option.decision === "SELECT") score += 500;
  if (option.tableType === "FIXED") score += 80;
  if (option.awardAvailable) score += 200;
  if (option.sufficientBalance) score += 40;
  if (option.cabin === "BUSINESS") score += 12;
  return score;
}

export function runAwardSearch(search: TripSearch, wallets: Wallet[]): SearchResponse {
  const cabins = search.cabins.length ? search.cabins : (["ECONOMY", "BUSINESS"] as Cabin[]);
  const lastOutbound = search.flexible
    ? addDays(search.dateEnd, -search.stayDays)
    : search.dateStart;
  const outboundDates = search.flexible
    ? eachDate(search.dateStart, lastOutbound < search.dateStart ? search.dateStart : lastOutbound)
    : [search.dateStart];

  const cashQuotes = cabins.map((cabin) => quoteCashMarket(search, cabin, outboundDates[0]));
  const dynamicQuotes = cabins.flatMap((cabin) => quoteDynamicMiles(search, cabin, outboundDates[0]));

  const matchingTables = FIXED_TABLES.filter((table) =>
    zonesMatch(table, search.origin, search.destination),
  );

  const options: AwardOption[] = [];

  for (const date of outboundDates) {
    const inbound = addDays(date, search.stayDays);
    for (const cabin of cabins) {
      const cash = quoteCashMarket(search, cabin, date);
      const dynamics = quoteDynamicMiles(search, cabin, date);
      const cheapestDynamic = [...dynamics].sort((a, b) => a.miles - b.miles)[0];

      for (const table of matchingTables) {
        const miles = milesForCabin(table, cabin, date);
        if (!miles) continue;
        const wallet = wallets.find((item) => item.programName === table.program);
        const available = isAwardSeatOpen({
          program: table.program,
          cabin,
          date,
          origin: search.origin,
          destination: search.destination,
        });
        const cpm = calculateCpm(cash.priceUsd, table.taxesEstimatedUsd, miles);
        const reasons: string[] = [];
        let decision: AwardOption["decision"] = "UNAVAILABLE";

        if (available && cheapestDynamic && miles < cheapestDynamic.miles) {
          decision = "SELECT";
          reasons.push(
            `Vaga award aberta e tabela fixa (${miles.toLocaleString("pt-BR")} milhas) é menor que a dinâmica (${cheapestDynamic.miles.toLocaleString("pt-BR")} em ${cheapestDynamic.program}).`,
          );
        }
        if (available && cpm > CPM_EXCELLENT_USD) {
          decision = "SELECT";
          reasons.push(
            `CPM ${cpm.toFixed(3)} USD/milha acima do limiar de excelência (${CPM_EXCELLENT_USD}). Priorizar tabela fixa.`,
          );
        }
        if (!available) {
          decision = "UNAVAILABLE";
          reasons.push(
            "Classe tarifária award não aparece aberta nesta data. Verificar alternativa no intervalo flexível.",
          );
        } else if (decision !== "SELECT") {
          decision = "ALTERNATIVE";
          reasons.push("Vaga aberta, mas a eficiência não supera a tabela dinâmica neste recorte.");
        }

        const shortfall = Math.max(0, miles - (wallet?.milesBalance ?? 0));
        options.push({
          id: `${table.program}-${cabin}-${date}`,
          program: table.program,
          tableType: "FIXED",
          cabin,
          outboundDate: date,
          inboundDate: inbound,
          miles,
          taxesUsd: table.taxesEstimatedUsd,
          cashPriceUsd: cash.priceUsd,
          cpm,
          awardAvailable: available,
          fareClass: fareClassFor(table, cabin),
          partnerAirline: table.partnerAirline,
          alliance: table.alliance,
          searchEngine: table.searchEngines[0],
          layover: search.allowLayovers
            ? suggestLayover(search.origin, search.destination, search.maxLayoverHours)
            : undefined,
          decision,
          reasons,
          officialUrl: officialSearchUrl(search.origin, search.destination, date),
          sufficientBalance: shortfall === 0,
          milesShortfall: shortfall,
        });
      }

      if (cheapestDynamic) {
        const cpm = calculateCpm(cash.priceUsd, cheapestDynamic.taxesUsd, cheapestDynamic.miles);
        options.push({
          id: `dyn-${cheapestDynamic.program}-${cabin}-${date}`,
          program: cheapestDynamic.program,
          tableType: "DYNAMIC",
          cabin,
          outboundDate: date,
          inboundDate: inbound,
          miles: cheapestDynamic.miles,
          taxesUsd: cheapestDynamic.taxesUsd,
          cashPriceUsd: cash.priceUsd,
          cpm,
          awardAvailable: true,
          fareClass: "—",
          partnerAirline: cheapestDynamic.program,
          alliance: "SkyTeam",
          searchEngine: cheapestDynamic.program,
          decision: "ALTERNATIVE",
          reasons: [
            "Cotação dinâmica de mercado. Usar se não houver vaga de tabela fixa no intervalo.",
          ],
          officialUrl: officialSearchUrl(search.origin, search.destination, date),
          sufficientBalance: true,
          milesShortfall: 0,
        });
      }
    }
  }

  const heatmap: HeatmapCell[] = outboundDates.map((date) => {
    const dayOptions = options.filter((option) => option.outboundDate === date && option.awardAvailable);
    const best = [...dayOptions].sort((a, b) => b.cpm - a.cpm)[0];
    return {
      date,
      available: Boolean(best && best.tableType === "FIXED"),
      bestCpm: best?.cpm ?? null,
      bestProgram: best?.program ?? null,
      cabin: best?.cabin ?? null,
    };
  });

  const selectable = options
    .filter((option) => option.decision === "SELECT" && option.sufficientBalance)
    .sort((a, b) => scoreOption(b) - scoreOption(a));

  const fallback = options
    .filter((option) => option.awardAvailable)
    .sort((a, b) => scoreOption(b) - scoreOption(a));

  const recommendation = selectable[0] ?? fallback[0] ?? null;

  const alerts: UserAlert[] = [];
  if (!matchingTables.length) {
    alerts.push({
      id: "no-table",
      level: "warning",
      title: "Sem matriz fixa para este par",
      message:
        "Não há tabela fixa cadastrada para origem/destino. Compare só a tabela dinâmica e o preço em dinheiro.",
    });
  }
  if (!options.some((option) => option.tableType === "FIXED" && option.awardAvailable)) {
    alerts.push({
      id: "no-award",
      level: "warning",
      title: "Award de tabela fixa indisponível",
      message:
        "Nenhuma classe tarifária fixa aparece aberta no intervalo. O motor recomenda datas alternativas ou emissão dinâmica.",
    });
  }
  if (recommendation?.decision === "SELECT") {
    alerts.push({
      id: "best",
      level: "success",
      title: `Melhor opção: ${recommendation.program}`,
      message: `${recommendation.cabin} em ${recommendation.outboundDate} · ${recommendation.miles.toLocaleString("pt-BR")} milhas · CPM ${recommendation.cpm.toFixed(3)}.`,
      optionId: recommendation.id,
    });
  }
  const shortWallets = options.filter(
    (option) => option.awardAvailable && option.tableType === "FIXED" && !option.sufficientBalance,
  );
  if (shortWallets.length) {
    alerts.push({
      id: "balance",
      level: "info",
      title: "Saldo insuficiente em alguns programas",
      message: "Há vagas boas cujo saldo da carteira não cobre o resgate. Complete milhas ou escolha outro programa.",
    });
  }

  return {
    query: search,
    generatedAt: new Date().toISOString(),
    cashQuotes,
    dynamicQuotes,
    options: options.sort((a, b) => scoreOption(b) - scoreOption(a)),
    recommendation,
    heatmap,
    alerts,
    cpmThresholdUsd: CPM_EXCELLENT_USD,
  };
}

export const DEFAULT_SEARCH: TripSearch = {
  origin: "GRU",
  destination: "JFK",
  flexible: true,
  dateStart: "2026-11-01",
  dateEnd: "2026-11-15",
  stayDays: 7,
  adults: 1,
  children: 0,
  infants: 0,
  cabins: ["BUSINESS", "ECONOMY"],
  allowLayovers: true,
  maxLayoverHours: 8,
};
