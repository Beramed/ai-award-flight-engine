import { AIRPORTS, airportsNear, fold, getAirport, haversineKm, type Airport } from "./airports";
import { suggestLayover } from "./market";

export type Place = {
  id: string;
  name: string;
  region: string;
  aliases: string[];
  lat: number;
  lng: number;
  airportCodes: string[];
};

export type PlaceHit = {
  kind: "place";
  place: Place;
  score: number;
  airports: { airport: Airport; km: number }[];
};

export type AirportHit = {
  kind: "airport";
  airport: Airport;
  score: number;
  kmFromPlace?: number;
};

export type RouteHit = {
  kind: "route";
  origin: Airport;
  destination: Airport;
  km: number;
  via?: string;
  reason: string;
};

export const PLACES: Place[] = [
  { id: "sp", name: "São Paulo", region: "Brasil", aliases: ["sp", "sampa", "paulista", "guarulhos", "congonhas"], lat: -23.5505, lng: -46.6333, airportCodes: ["GRU", "CGH", "VCP"] },
  { id: "bsb", name: "Brasília", region: "Brasil", aliases: ["brasilia", "df", "capital"], lat: -15.7975, lng: -47.8919, airportCodes: ["BSB"] },
  { id: "rio", name: "Rio de Janeiro", region: "Brasil", aliases: ["rio", "copacabana", "ipanema", "cristo", "pao de acucar", "cidade maravilhosa"], lat: -22.9068, lng: -43.1729, airportCodes: ["GIG", "SDU"] },
  { id: "nyc", name: "Nova York", region: "Estados Unidos", aliases: ["new york", "manhattan", "brooklyn", "times square", "nyc", "ny", "estatua da liberdade", "central park"], lat: 40.7128, lng: -74.006, airportCodes: ["JFK", "EWR", "LGA"] },
  { id: "orlando", name: "Orlando", region: "Flórida", aliases: ["disney", "walt disney", "universal", "magic kingdom", "epcot"], lat: 28.3852, lng: -81.5639, airportCodes: ["MCO"] },
  { id: "miami", name: "Miami", region: "Flórida", aliases: ["south beach", "miami beach", "wynwood"], lat: 25.7617, lng: -80.1918, airportCodes: ["MIA", "FLL"] },
  { id: "florida", name: "Flórida", region: "Estados Unidos", aliases: ["florida", "eua sul"], lat: 27.6648, lng: -81.5158, airportCodes: ["MCO", "MIA", "FLL"] },
  { id: "la", name: "Los Angeles", region: "Califórnia", aliases: ["hollywood", "california", "la"], lat: 34.0522, lng: -118.2437, airportCodes: ["LAX"] },
  { id: "sf", name: "São Francisco", region: "Califórnia", aliases: ["san francisco", "golden gate"], lat: 37.7749, lng: -122.4194, airportCodes: ["SFO"] },
  { id: "vegas", name: "Las Vegas", region: "Estados Unidos", aliases: ["vegas", "las vegas", "strip"], lat: 36.1699, lng: -115.1398, airportCodes: ["LAS"] },
  { id: "lisboa", name: "Lisboa", region: "Portugal", aliases: ["lisbon", "belem", "alfama", "lx"], lat: 38.7223, lng: -9.1393, airportCodes: ["LIS"] },
  { id: "porto", name: "Porto", region: "Portugal", aliases: ["ribeira", "oporto"], lat: 41.1579, lng: -8.6291, airportCodes: ["OPO"] },
  { id: "algarve", name: "Algarve", region: "Portugal", aliases: ["faro", "albufeira", "lagos", "portugal sul"], lat: 37.0179, lng: -7.9304, airportCodes: ["FAO", "LIS"] },
  { id: "portugal", name: "Portugal", region: "Europa", aliases: ["pt"], lat: 39.3999, lng: -8.2245, airportCodes: ["LIS", "OPO", "FAO"] },
  { id: "madrid", name: "Madri", region: "Espanha", aliases: ["madrid", "prado"], lat: 40.4168, lng: -3.7038, airportCodes: ["MAD"] },
  { id: "bcn", name: "Barcelona", region: "Espanha", aliases: ["sagrada familia", "gaudi"], lat: 41.3874, lng: 2.1686, airportCodes: ["BCN"] },
  { id: "paris", name: "Paris", region: "França", aliases: ["torre eiffel", "eiffel", "louvre"], lat: 48.8566, lng: 2.3522, airportCodes: ["CDG", "ORY"] },
  { id: "london", name: "Londres", region: "Reino Unido", aliases: ["london", "big ben", "uk"], lat: 51.5074, lng: -0.1278, airportCodes: ["LHR", "LGW"] },
  { id: "rome", name: "Roma", region: "Itália", aliases: ["roma", "coliseu", "vaticano"], lat: 41.9028, lng: 12.4964, airportCodes: ["FCO"] },
  { id: "milan", name: "Milão", region: "Itália", aliases: ["milao", "milan", "duomo"], lat: 45.4642, lng: 9.19, airportCodes: ["MXP"] },
  { id: "venice", name: "Veneza", region: "Itália", aliases: ["venice", "veneza"], lat: 45.4408, lng: 12.3155, airportCodes: ["VCE"] },
  { id: "cancun", name: "Cancún", region: "México", aliases: ["cancun", "riviera maya", "playa del carmen", "tulum"], lat: 21.1619, lng: -86.8515, airportCodes: ["CUN"] },
  { id: "bsas", name: "Buenos Aires", region: "Argentina", aliases: ["baires", "palermo", "argentina"], lat: -34.6037, lng: -58.3816, airportCodes: ["EZE"] },
  { id: "nordeste", name: "Nordeste", region: "Brasil", aliases: ["praia", "nordeste brasileiro"], lat: -8.0476, lng: -34.877, airportCodes: ["REC", "SSA", "FOR", "NAT"] },
];

function scoreText(query: string, ...parts: string[]) {
  const hay = fold(parts.filter(Boolean).join(" "));
  if (!query) return 0;
  if (hay === query) return 100;
  if (hay.startsWith(query)) return 88;
  if (hay.includes(` ${query}`) || hay.includes(query)) return 70;
  return 0;
}

function uniqueAirports(codes: string[], lat: number, lng: number) {
  const nearby = airportsNear(lat, lng, 5, 140).map((item) => item.airport.code);
  const ordered = [...codes, ...nearby];
  const seen = new Set<string>();
  const result: { airport: Airport; km: number }[] = [];
  for (const code of ordered) {
    if (seen.has(code)) continue;
    const airport = getAirport(code);
    if (!airport) continue;
    seen.add(code);
    result.push({ airport, km: Math.round(haversineKm({ lat, lng }, airport)) });
  }
  return result.slice(0, 4);
}

export function searchPlaces(
  queryRaw: string,
  options: { originCode?: string; role?: "origin" | "destination" } = {},
) {
  const query = fold(queryRaw);
  const origin = options.originCode ? getAirport(options.originCode) : undefined;
  const places: PlaceHit[] = [];
  const airports: AirportHit[] = [];
  const popularIds =
    options.role === "origin"
      ? ["sp", "rio", "bsb", "nordeste"]
      : ["nyc", "orlando", "lisboa", "paris", "miami", "london"];

  if (!query) {
    for (const id of popularIds) {
      const place = PLACES.find((item) => item.id === id);
      if (!place) continue;
      places.push({
        kind: "place",
        place,
        score: 1,
        airports: uniqueAirports(place.airportCodes, place.lat, place.lng),
      });
    }
  } else {
    for (const place of PLACES) {
      const score = Math.max(
        scoreText(query, place.name),
        scoreText(query, place.region),
        ...place.aliases.map((alias) => scoreText(query, alias)),
      );
      if (score <= 0) continue;
      places.push({
        kind: "place",
        place,
        score,
        airports: uniqueAirports(place.airportCodes, place.lat, place.lng),
      });
    }

    for (const airport of AIRPORTS) {
      const score = Math.max(
        airport.code.toLowerCase() === query ? 110 : 0,
        scoreText(query, airport.code),
        scoreText(query, airport.city),
        scoreText(query, airport.name),
        scoreText(query, airport.country),
      );
      if (score <= 0) continue;
      airports.push({ kind: "airport", airport, score });
    }
  }

  places.sort((a, b) => b.score - a.score);
  airports.sort((a, b) => b.score - a.score);

  const destAirports = [
    ...places.flatMap((place) => place.airports.map((item) => item.airport)),
    ...airports.map((item) => item.airport),
  ];
  const seen = new Set<string>();
  const routes: RouteHit[] = [];
  if (origin) {
    for (const destination of destAirports) {
      if (seen.has(destination.code) || destination.code === origin.code) continue;
      seen.add(destination.code);
      const layover = suggestLayover(origin.code, destination.code, 8);
      routes.push({
        kind: "route",
        origin,
        destination,
        km: Math.round(haversineKm(origin, destination)),
        via: layover?.airport,
        reason: layover
          ? `conexão típica via ${layover.airport}`
          : `aeroporto mais próximo para ${destination.city}`,
      });
      if (routes.length >= 4) break;
    }
  }

  return {
    places: places.slice(0, 5),
    airports: airports.slice(0, 5),
    routes,
  };
}
