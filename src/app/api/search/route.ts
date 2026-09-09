import { DEFAULT_SEARCH, runAwardSearch } from "@/lib/engine";
import { DEFAULT_WALLETS } from "@/lib/tables";
import type { TripSearch, Wallet } from "@/lib/types";

function asString(value: unknown, fallback: string) {
  return typeof value === "string" && value.trim() ? value.trim().toUpperCase() : fallback;
}

function asNumber(value: unknown, fallback: number) {
  const parsed = typeof value === "number" ? value : Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function parseSearch(body: Record<string, unknown>): TripSearch {
  const cabinsRaw = Array.isArray(body.cabins) ? body.cabins : DEFAULT_SEARCH.cabins;
  const cabins = cabinsRaw.filter(
    (cabin): cabin is TripSearch["cabins"][number] =>
      cabin === "ECONOMY" || cabin === "BUSINESS" || cabin === "FIRST",
  );
  return {
    origin: asString(body.origin, DEFAULT_SEARCH.origin),
    destination: asString(body.destination, DEFAULT_SEARCH.destination),
    flexible: body.flexible !== false,
    dateStart: typeof body.dateStart === "string" ? body.dateStart : DEFAULT_SEARCH.dateStart,
    dateEnd: typeof body.dateEnd === "string" ? body.dateEnd : DEFAULT_SEARCH.dateEnd,
    stayDays: Math.max(1, asNumber(body.stayDays, DEFAULT_SEARCH.stayDays)),
    adults: Math.max(1, asNumber(body.adults, 1)),
    children: Math.max(0, asNumber(body.children, 0)),
    infants: Math.max(0, asNumber(body.infants, 0)),
    cabins: cabins.length ? cabins : DEFAULT_SEARCH.cabins,
    allowLayovers: body.allowLayovers !== false,
    maxLayoverHours: Math.max(1, asNumber(body.maxLayoverHours, 8)),
  };
}

function parseWallets(body: Record<string, unknown>): Wallet[] {
  if (!Array.isArray(body.wallets) || body.wallets.length === 0) return DEFAULT_WALLETS;
  return body.wallets
    .map((item) => {
      if (!item || typeof item !== "object") return null;
      const wallet = item as Record<string, unknown>;
      const alliance =
        wallet.alliance === "Star Alliance" || wallet.alliance === "SkyTeam"
          ? wallet.alliance
          : "Oneworld";
      return {
        programName: String(wallet.programName ?? ""),
        airline: String(wallet.airline ?? ""),
        alliance,
        milesBalance: asNumber(wallet.milesBalance, 0),
        credentialsRef: String(wallet.credentialsRef ?? ""),
      } satisfies Wallet;
    })
    .filter((wallet): wallet is Wallet => Boolean(wallet?.programName));
}

export async function POST(request: Request) {
  const body = (await request.json().catch(() => ({}))) as Record<string, unknown>;
  const search = parseSearch(body);
  const wallets = parseWallets(body);
  const result = runAwardSearch(search, wallets);
  return Response.json(result);
}
