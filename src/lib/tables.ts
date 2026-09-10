import type { Alliance, FixedTable } from "./types";

export const CPM_EXCELLENT_USD = 0.015;

export const DEFAULT_WALLETS = [
  { programName: "AAdvantage", airline: "American Airlines", alliance: "Oneworld" as Alliance, milesBalance: 150000, credentialsRef: "env_aadvantage_vault_id" },
  { programName: "MileagePlus", airline: "United Airlines", alliance: "Star Alliance" as Alliance, milesBalance: 0, credentialsRef: "env_united_vault_id" },
  { programName: "Flying Blue", airline: "Air France / KLM", alliance: "SkyTeam" as Alliance, milesBalance: 0, credentialsRef: "env_af_vault_id" },
  { programName: "LATAM Pass", airline: "LATAM", alliance: "Independent" as Alliance, milesBalance: 0, credentialsRef: "env_latam_vault_id" },
  { programName: "Smiles", airline: "GOL", alliance: "Independent" as Alliance, milesBalance: 0, credentialsRef: "env_smiles_vault_id" },
  { programName: "TudoAzul", airline: "Azul", alliance: "Independent" as Alliance, milesBalance: 0, credentialsRef: "env_azul_vault_id" },
  { programName: "Privilege Club", airline: "Qatar Airways", alliance: "Oneworld" as Alliance, milesBalance: 0, credentialsRef: "env_qatar_vault_id" },
  { programName: "Skywards", airline: "Emirates", alliance: "Independent" as Alliance, milesBalance: 0, credentialsRef: "env_emirates_vault_id" },
  { programName: "Iberia Plus", airline: "Iberia", alliance: "Oneworld" as Alliance, milesBalance: 90000, credentialsRef: "env_iberia_vault_id" },
  { programName: "TAP Miles&Go", airline: "TAP Air Portugal", alliance: "Star Alliance" as Alliance, milesBalance: 120000, credentialsRef: "env_tap_vault_id" },
];

function table(
  program: string,
  partnerAirline: string,
  originZone: string,
  destinationZone: string,
  originZoneIds: string[],
  destinationZoneIds: string[],
  miles: Record<string, number>,
  classes: Record<string, string>,
  taxesEstimatedUsd: number,
  alliance: Alliance,
  searchEngines: string[],
): FixedTable {
  return {
    program,
    partnerAirline,
    originZone,
    destinationZone,
    originZoneIds,
    destinationZoneIds,
    fixedRatesMiles: miles,
    awardFareClasses: classes,
    taxesEstimatedUsd,
    alliance,
    searchEngines,
  };
}

export const FIXED_TABLES: FixedTable[] = [
  table("AAdvantage", "American Airlines", "América do Sul 2", "América do Norte", ["SA2"], ["NA"], { economy: 35000, business: 60000, first: 85000 }, { economy: "T", business: "U", first: "Z" }, 50, "Oneworld", ["American Airlines"]),
  table("AAdvantage", "American Airlines / LATAM", "América do Sul 2", "Europa", ["SA2"], ["EU"], { economy: 40000, business: 70000, first: 110000 }, { economy: "T", business: "U", first: "Z" }, 180, "Oneworld", ["American Airlines", "British Airways"]),
  table("MileagePlus", "United Airlines", "Brasil", "América do Norte", ["SA2", "BR"], ["NA"], { economy: 40000, business: 80000, first: 140000 }, { economy: "X", business: "I", first: "O" }, 70, "Star Alliance", ["United Airlines"]),
  table("MileagePlus", "United / Lufthansa / TAP", "Brasil", "Europa", ["SA2", "BR"], ["EU"], { economy: 40000, business: 80000, first: 140000 }, { economy: "X", business: "I", first: "O" }, 120, "Star Alliance", ["United Airlines", "Air Canada Aeroplan"]),
  table("Flying Blue", "Air France / KLM", "Brasil", "Europa", ["SA2", "BR"], ["EU"], { economy: 30000, business: 75000 }, { economy: "X", business: "I" }, 110, "SkyTeam", ["Air France-KLM Flying Blue"]),
  table("Flying Blue", "Air France / KLM / Delta", "Brasil", "América do Norte", ["SA2", "BR"], ["NA"], { economy: 25000, business: 79000 }, { economy: "X", business: "I" }, 80, "SkyTeam", ["Air France-KLM Flying Blue"]),
  table("LATAM Pass", "LATAM", "Brasil", "América do Norte", ["SA2", "BR"], ["NA"], { economy: 55000, business: 99000 }, { economy: "X", business: "J" }, 65, "Independent", ["LATAM Pass"]),
  table("LATAM Pass", "LATAM", "Brasil", "Europa", ["SA2", "BR"], ["EU"], { economy: 70000, business: 126000 }, { economy: "X", business: "J" }, 140, "Independent", ["LATAM Pass"]),
  table("Smiles", "GOL / parceiras", "Brasil", "América do Norte", ["SA2", "BR"], ["NA"], { economy: 62000, business: 108000 }, { economy: "G", business: "C" }, 60, "Independent", ["Smiles"]),
  table("Smiles", "GOL / Air France / KLM", "Brasil", "Europa", ["SA2", "BR"], ["EU"], { economy: 72000, business: 126000 }, { economy: "G", business: "C" }, 130, "Independent", ["Smiles"]),
  table("TudoAzul", "Azul", "Brasil", "América do Norte", ["SA2", "BR"], ["NA"], { economy: 69000, business: 118000 }, { economy: "T", business: "C" }, 55, "Independent", ["TudoAzul"]),
  table("TudoAzul", "Azul / United / TAP", "Brasil", "Europa", ["SA2", "BR"], ["EU"], { economy: 78000, business: 135000 }, { economy: "T", business: "C" }, 125, "Independent", ["TudoAzul"]),
  table("Privilege Club", "Qatar Airways", "Brasil", "Europa (via DOH)", ["SA2", "BR"], ["EU"], { economy: 40000, business: 80000, first: 120000 }, { economy: "N", business: "I", first: "P" }, 160, "Oneworld", ["Qatar Airways"]),
  table("Privilege Club", "Qatar Airways", "Brasil", "América do Norte (via DOH)", ["SA2", "BR"], ["NA"], { economy: 45000, business: 90000, first: 135000 }, { economy: "N", business: "I", first: "P" }, 90, "Oneworld", ["Qatar Airways"]),
  table("Skywards", "Emirates", "Brasil", "Europa (via DXB)", ["SA2", "BR"], ["EU"], { economy: 42500, business: 85000, first: 127500 }, { economy: "Q", business: "O", first: "F" }, 170, "Independent", ["Emirates Skywards"]),
  table("Skywards", "Emirates", "Brasil", "América do Norte (via DXB)", ["SA2", "BR"], ["NA"], { economy: 47500, business: 95000, first: 142500 }, { economy: "Q", business: "O", first: "F" }, 95, "Independent", ["Emirates Skywards"]),
  table("Iberia Plus", "Iberia", "Zona 6 (BR–MAD)", "Europa", ["SA2", "BR"], ["EU"], { economy_off_peak: 21250, economy: 25500, business_off_peak: 42500, business: 42500, business_peak: 62500 }, { economy: "X", business: "I" }, 130, "Oneworld", ["Iberia", "British Airways"]),
  table("TAP Miles&Go", "TAP Air Portugal", "Brasil", "Europa", ["SA2", "BR"], ["EU"], { economy: 45000, business: 77900 }, { economy: "X", business: "I" }, 95, "Star Alliance", ["TAP Miles&Go"]),
  table("TAP Miles&Go", "United / Air Canada", "Brasil", "América do Norte", ["SA2", "BR"], ["NA"], { economy: 54000, business: 99000 }, { economy: "X", business: "I" }, 70, "Star Alliance", ["United Airlines", "Air Canada Aeroplan"]),
];

export const DYNAMIC_PROGRAMS = [
  { program: "Smiles", airline: "GOL", alliance: "Independent" as const },
  { program: "TudoAzul", airline: "Azul", alliance: "Independent" as const },
  { program: "LATAM Pass", airline: "LATAM", alliance: "Independent" as const },
  { program: "Flying Blue", airline: "Air France / KLM", alliance: "SkyTeam" as const },
];

export const ALLIANCE_ENGINES = {
  "Star Alliance": ["United Airlines", "Air Canada Aeroplan"],
  Oneworld: ["American Airlines", "British Airways", "Qatar Airways"],
  SkyTeam: ["Air France-KLM Flying Blue", "Delta SkyMiles"],
  Independent: ["LATAM Pass", "Smiles", "TudoAzul", "Emirates Skywards"],
} as const;
