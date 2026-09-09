import type { Alliance, FixedTable } from "./types";

export const CPM_EXCELLENT_USD = 0.015;

export const DEFAULT_WALLETS = [
  {
    programName: "AAdvantage",
    airline: "American Airlines",
    alliance: "Oneworld" as Alliance,
    milesBalance: 150000,
    credentialsRef: "env_aadvantage_vault_id",
  },
  {
    programName: "Iberia Plus",
    airline: "Iberia",
    alliance: "Oneworld" as Alliance,
    milesBalance: 90000,
    credentialsRef: "env_iberia_vault_id",
  },
  {
    programName: "TAP Miles&Go",
    airline: "TAP Air Portugal",
    alliance: "Star Alliance" as Alliance,
    milesBalance: 120000,
    credentialsRef: "env_tap_vault_id",
  },
];

export const FIXED_TABLES: FixedTable[] = [
  {
    program: "AAdvantage",
    partnerAirline: "American Airlines / LATAM",
    originZone: "South America Region 2",
    destinationZone: "North America",
    originZoneIds: ["SA2"],
    destinationZoneIds: ["NA"],
    fixedRatesMiles: { economy: 35000, business: 60000, first: 85000 },
    awardFareClasses: { economy: "T", business: "U", first: "Z" },
    taxesEstimatedUsd: 50,
    alliance: "Oneworld",
    searchEngines: ["American Airlines", "British Airways"],
  },
  {
    program: "AAdvantage",
    partnerAirline: "Iberia / British Airways",
    originZone: "South America Region 2",
    destinationZone: "Europe",
    originZoneIds: ["SA2"],
    destinationZoneIds: ["EU"],
    fixedRatesMiles: { economy: 40000, business: 70000, first: 110000 },
    awardFareClasses: { economy: "T", business: "U", first: "Z" },
    taxesEstimatedUsd: 180,
    alliance: "Oneworld",
    searchEngines: ["American Airlines", "British Airways"],
  },
  {
    program: "Iberia Plus",
    partnerAirline: "Iberia",
    originZone: "Zone 6 (ex: BR-MAD)",
    destinationZone: "Europe",
    originZoneIds: ["SA2", "BR"],
    destinationZoneIds: ["EU"],
    fixedRatesMiles: {
      economy_off_peak: 21250,
      business_off_peak: 42500,
      business_peak: 62500,
      economy: 25500,
      business: 42500,
    },
    awardFareClasses: { economy: "X", business: "I" },
    taxesEstimatedUsd: 130,
    alliance: "Oneworld",
    searchEngines: ["Iberia", "British Airways"],
  },
  {
    program: "TAP Miles&Go",
    partnerAirline: "TAP Air Portugal",
    originZone: "Brasil",
    destinationZone: "Europa",
    originZoneIds: ["SA2", "BR"],
    destinationZoneIds: ["EU"],
    fixedRatesMiles: { economy: 45000, business: 77900 },
    awardFareClasses: { economy: "X", business: "I" },
    taxesEstimatedUsd: 95,
    alliance: "Star Alliance",
    searchEngines: ["TAP Miles&Go", "Air Canada Aeroplan", "United Airlines"],
  },
  {
    program: "TAP Miles&Go",
    partnerAirline: "United / Air Canada",
    originZone: "Brasil",
    destinationZone: "América do Norte",
    originZoneIds: ["SA2", "BR"],
    destinationZoneIds: ["NA"],
    fixedRatesMiles: { economy: 54000, business: 99000 },
    awardFareClasses: { economy: "X", business: "I" },
    taxesEstimatedUsd: 70,
    alliance: "Star Alliance",
    searchEngines: ["Air Canada Aeroplan", "United Airlines"],
  },
];

export const DYNAMIC_PROGRAMS = [
  { program: "Smiles", airline: "GOL", alliance: "none" as const },
  { program: "TudoAzul", airline: "Azul", alliance: "none" as const },
  { program: "LATAM Pass", airline: "LATAM", alliance: "none" as const },
];

export const ALLIANCE_ENGINES = {
  "Star Alliance": ["Air Canada Aeroplan", "United Airlines"],
  Oneworld: ["American Airlines", "British Airways"],
  SkyTeam: ["Air France-KLM Flying Blue", "Delta SkyMiles"],
} as const;
