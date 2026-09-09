export type Airport = {
  code: string;
  city: string;
  name: string;
  country: string;
  zoneIds: string[];
};

export const AIRPORTS: Airport[] = [
  { code: "GRU", city: "São Paulo", name: "Guarulhos", country: "BR", zoneIds: ["SA2", "BR"] },
  { code: "CGH", city: "São Paulo", name: "Congonhas", country: "BR", zoneIds: ["SA2", "BR"] },
  { code: "GIG", city: "Rio de Janeiro", name: "Galeão", country: "BR", zoneIds: ["SA2", "BR"] },
  { code: "BSB", city: "Brasília", name: "Presidente Juscelino", country: "BR", zoneIds: ["SA2", "BR"] },
  { code: "CNF", city: "Belo Horizonte", name: "Confins", country: "BR", zoneIds: ["SA2", "BR"] },
  { code: "POA", city: "Porto Alegre", name: "Salgado Filho", country: "BR", zoneIds: ["SA2", "BR"] },
  { code: "CWB", city: "Curitiba", name: "Afonso Pena", country: "BR", zoneIds: ["SA2", "BR"] },
  { code: "REC", city: "Recife", name: "Guararapes", country: "BR", zoneIds: ["SA2", "BR"] },
  { code: "SSA", city: "Salvador", name: "Deputado Luís Eduardo Magalhães", country: "BR", zoneIds: ["SA2", "BR"] },
  { code: "FOR", city: "Fortaleza", name: "Pinto Martins", country: "BR", zoneIds: ["SA2", "BR"] },
  { code: "JFK", city: "Nova York", name: "John F. Kennedy", country: "US", zoneIds: ["NA"] },
  { code: "EWR", city: "Newark", name: "Newark Liberty", country: "US", zoneIds: ["NA"] },
  { code: "MIA", city: "Miami", name: "Miami International", country: "US", zoneIds: ["NA"] },
  { code: "MCO", city: "Orlando", name: "Orlando International", country: "US", zoneIds: ["NA"] },
  { code: "LAX", city: "Los Angeles", name: "Los Angeles International", country: "US", zoneIds: ["NA"] },
  { code: "ORD", city: "Chicago", name: "O'Hare", country: "US", zoneIds: ["NA"] },
  { code: "DFW", city: "Dallas", name: "Dallas/Fort Worth", country: "US", zoneIds: ["NA"] },
  { code: "IAD", city: "Washington", name: "Dulles", country: "US", zoneIds: ["NA"] },
  { code: "BOS", city: "Boston", name: "Logan", country: "US", zoneIds: ["NA"] },
  { code: "YYZ", city: "Toronto", name: "Pearson", country: "CA", zoneIds: ["NA"] },
  { code: "MAD", city: "Madri", name: "Barajas", country: "ES", zoneIds: ["EU"] },
  { code: "BCN", city: "Barcelona", name: "El Prat", country: "ES", zoneIds: ["EU"] },
  { code: "LIS", city: "Lisboa", name: "Humberto Delgado", country: "PT", zoneIds: ["EU"] },
  { code: "OPO", city: "Porto", name: "Francisco Sá Carneiro", country: "PT", zoneIds: ["EU"] },
  { code: "LHR", city: "Londres", name: "Heathrow", country: "GB", zoneIds: ["EU"] },
  { code: "CDG", city: "Paris", name: "Charles de Gaulle", country: "FR", zoneIds: ["EU"] },
  { code: "FCO", city: "Roma", name: "Fiumicino", country: "IT", zoneIds: ["EU"] },
  { code: "AMS", city: "Amsterdã", name: "Schiphol", country: "NL", zoneIds: ["EU"] },
  { code: "FRA", city: "Frankfurt", name: "Frankfurt am Main", country: "DE", zoneIds: ["EU"] },
  { code: "MEX", city: "Cidade do México", name: "Benito Juárez", country: "MX", zoneIds: ["NA"] },
  { code: "SCL", city: "Santiago", name: "Arturo Merino Benítez", country: "CL", zoneIds: ["SA2"] },
  { code: "EZE", city: "Buenos Aires", name: "Ezeiza", country: "AR", zoneIds: ["SA2"] },
  { code: "BOG", city: "Bogotá", name: "El Dorado", country: "CO", zoneIds: ["SA2"] },
  { code: "LIM", city: "Lima", name: "Jorge Chávez", country: "PE", zoneIds: ["SA2"] },
];

export function getAirport(code: string) {
  return AIRPORTS.find((airport) => airport.code === code.toUpperCase());
}

export function airportLabel(code: string) {
  const airport = getAirport(code);
  if (!airport) return code.toUpperCase();
  return `${airport.code} · ${airport.city}`;
}
