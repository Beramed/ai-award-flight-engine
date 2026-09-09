export type Cabin = "ECONOMY" | "BUSINESS" | "FIRST";
export type Alliance = "Oneworld" | "Star Alliance" | "SkyTeam";
export type TableType = "FIXED" | "DYNAMIC";
export type Decision = "SELECT" | "ALTERNATIVE" | "UNAVAILABLE";

export type TripSearch = {
  origin: string;
  destination: string;
  flexible: boolean;
  dateStart: string;
  dateEnd: string;
  stayDays: number;
  adults: number;
  children: number;
  infants: number;
  cabins: Cabin[];
  allowLayovers: boolean;
  maxLayoverHours: number;
};

export type Wallet = {
  programName: string;
  airline: string;
  alliance: Alliance;
  milesBalance: number;
  credentialsRef: string;
};

export type AwardFareClasses = Partial<Record<Cabin | "ECONOMY_OFF_PEAK" | "BUSINESS_OFF_PEAK" | "BUSINESS_PEAK", string>>;

export type FixedTable = {
  program: string;
  partnerAirline: string;
  originZone: string;
  destinationZone: string;
  originZoneIds: string[];
  destinationZoneIds: string[];
  fixedRatesMiles: Record<string, number>;
  awardFareClasses: Record<string, string>;
  taxesEstimatedUsd: number;
  alliance: Alliance;
  searchEngines: string[];
};

export type CashQuote = {
  source: string;
  cabin: Cabin;
  priceUsd: number;
  taxesUsd: number;
  currency: "USD";
};

export type DynamicMilesQuote = {
  program: string;
  cabin: Cabin;
  miles: number;
  taxesUsd: number;
  source: string;
};

export type AwardOption = {
  id: string;
  program: string;
  tableType: TableType;
  cabin: Cabin;
  outboundDate: string;
  inboundDate: string;
  miles: number;
  taxesUsd: number;
  cashPriceUsd: number;
  cpm: number;
  awardAvailable: boolean;
  fareClass: string;
  partnerAirline: string;
  alliance: Alliance;
  searchEngine: string;
  layover?: { airport: string; hours: number };
  decision: Decision;
  reasons: string[];
  officialUrl: string;
  sufficientBalance: boolean;
  milesShortfall: number;
};

export type HeatmapCell = {
  date: string;
  available: boolean;
  bestCpm: number | null;
  bestProgram: string | null;
  cabin: Cabin | null;
};

export type UserAlert = {
  id: string;
  level: "info" | "warning" | "success";
  title: string;
  message: string;
  optionId?: string;
};

export type BookingKit = {
  option: AwardOption;
  callCenterScript: string;
  whatsappText: string;
  checklist: string[];
  officialSearchUrl: string;
  requiresPhone: boolean;
};

export type SearchResponse = {
  query: TripSearch;
  generatedAt: string;
  cashQuotes: CashQuote[];
  dynamicQuotes: DynamicMilesQuote[];
  options: AwardOption[];
  recommendation: AwardOption | null;
  heatmap: HeatmapCell[];
  alerts: UserAlert[];
  cpmThresholdUsd: number;
};
