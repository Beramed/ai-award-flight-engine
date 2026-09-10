export type Airport = {
  code: string;
  city: string;
  name: string;
  country: string;
  zoneIds: string[];
  lat: number;
  lng: number;
};

export const AIRPORTS: Airport[] = [
  { code: "GRU", city: "São Paulo", name: "Guarulhos", country: "BR", zoneIds: ["SA2", "BR"], lat: -23.4356, lng: -46.4731 },
  { code: "CGH", city: "São Paulo", name: "Congonhas", country: "BR", zoneIds: ["SA2", "BR"], lat: -23.6261, lng: -46.6564 },
  { code: "VCP", city: "Campinas", name: "Viracopos", country: "BR", zoneIds: ["SA2", "BR"], lat: -23.0074, lng: -47.1345 },
  { code: "GIG", city: "Rio de Janeiro", name: "Galeão", country: "BR", zoneIds: ["SA2", "BR"], lat: -22.809, lng: -43.2506 },
  { code: "SDU", city: "Rio de Janeiro", name: "Santos Dumont", country: "BR", zoneIds: ["SA2", "BR"], lat: -22.9104, lng: -43.1631 },
  { code: "BSB", city: "Brasília", name: "Presidente Juscelino", country: "BR", zoneIds: ["SA2", "BR"], lat: -15.8697, lng: -47.9208 },
  { code: "CNF", city: "Belo Horizonte", name: "Confins", country: "BR", zoneIds: ["SA2", "BR"], lat: -19.6244, lng: -43.9719 },
  { code: "POA", city: "Porto Alegre", name: "Salgado Filho", country: "BR", zoneIds: ["SA2", "BR"], lat: -29.9939, lng: -51.1714 },
  { code: "CWB", city: "Curitiba", name: "Afonso Pena", country: "BR", zoneIds: ["SA2", "BR"], lat: -25.5285, lng: -49.1758 },
  { code: "FLN", city: "Florianópolis", name: "Hercílio Luz", country: "BR", zoneIds: ["SA2", "BR"], lat: -27.6703, lng: -48.5525 },
  { code: "REC", city: "Recife", name: "Guararapes", country: "BR", zoneIds: ["SA2", "BR"], lat: -8.1268, lng: -34.9236 },
  { code: "SSA", city: "Salvador", name: "Deputado Luís Eduardo Magalhães", country: "BR", zoneIds: ["SA2", "BR"], lat: -12.9086, lng: -38.3225 },
  { code: "FOR", city: "Fortaleza", name: "Pinto Martins", country: "BR", zoneIds: ["SA2", "BR"], lat: -3.7763, lng: -38.5326 },
  { code: "NAT", city: "Natal", name: "Aluízio Alves", country: "BR", zoneIds: ["SA2", "BR"], lat: -5.9114, lng: -35.2475 },
  { code: "JFK", city: "Nova York", name: "John F. Kennedy", country: "US", zoneIds: ["NA"], lat: 40.6413, lng: -73.7781 },
  { code: "EWR", city: "Newark", name: "Newark Liberty", country: "US", zoneIds: ["NA"], lat: 40.6895, lng: -74.1745 },
  { code: "LGA", city: "Nova York", name: "LaGuardia", country: "US", zoneIds: ["NA"], lat: 40.7769, lng: -73.874 },
  { code: "MIA", city: "Miami", name: "Miami International", country: "US", zoneIds: ["NA"], lat: 25.7959, lng: -80.287 },
  { code: "FLL", city: "Fort Lauderdale", name: "Hollywood", country: "US", zoneIds: ["NA"], lat: 26.0726, lng: -80.1527 },
  { code: "MCO", city: "Orlando", name: "Orlando International", country: "US", zoneIds: ["NA"], lat: 28.4312, lng: -81.3081 },
  { code: "LAX", city: "Los Angeles", name: "Los Angeles International", country: "US", zoneIds: ["NA"], lat: 33.9416, lng: -118.4085 },
  { code: "SFO", city: "São Francisco", name: "San Francisco International", country: "US", zoneIds: ["NA"], lat: 37.6213, lng: -122.379 },
  { code: "LAS", city: "Las Vegas", name: "Harry Reid", country: "US", zoneIds: ["NA"], lat: 36.084, lng: -115.1537 },
  { code: "ORD", city: "Chicago", name: "O'Hare", country: "US", zoneIds: ["NA"], lat: 41.9742, lng: -87.9073 },
  { code: "DFW", city: "Dallas", name: "Dallas/Fort Worth", country: "US", zoneIds: ["NA"], lat: 32.8998, lng: -97.0403 },
  { code: "IAD", city: "Washington", name: "Dulles", country: "US", zoneIds: ["NA"], lat: 38.9531, lng: -77.4565 },
  { code: "BOS", city: "Boston", name: "Logan", country: "US", zoneIds: ["NA"], lat: 42.3656, lng: -71.0096 },
  { code: "YYZ", city: "Toronto", name: "Pearson", country: "CA", zoneIds: ["NA"], lat: 43.6777, lng: -79.6248 },
  { code: "CUN", city: "Cancún", name: "Cancún International", country: "MX", zoneIds: ["NA"], lat: 21.0365, lng: -86.8771 },
  { code: "MEX", city: "Cidade do México", name: "Benito Juárez", country: "MX", zoneIds: ["NA"], lat: 19.4363, lng: -99.0721 },
  { code: "MAD", city: "Madri", name: "Barajas", country: "ES", zoneIds: ["EU"], lat: 40.4983, lng: -3.5676 },
  { code: "BCN", city: "Barcelona", name: "El Prat", country: "ES", zoneIds: ["EU"], lat: 41.2974, lng: 2.0833 },
  { code: "LIS", city: "Lisboa", name: "Humberto Delgado", country: "PT", zoneIds: ["EU"], lat: 38.7756, lng: -9.1354 },
  { code: "OPO", city: "Porto", name: "Francisco Sá Carneiro", country: "PT", zoneIds: ["EU"], lat: 41.2421, lng: -8.6787 },
  { code: "FAO", city: "Faro", name: "Faro", country: "PT", zoneIds: ["EU"], lat: 37.0144, lng: -7.9658 },
  { code: "LHR", city: "Londres", name: "Heathrow", country: "GB", zoneIds: ["EU"], lat: 51.47, lng: -0.4543 },
  { code: "LGW", city: "Londres", name: "Gatwick", country: "GB", zoneIds: ["EU"], lat: 51.1537, lng: -0.1821 },
  { code: "CDG", city: "Paris", name: "Charles de Gaulle", country: "FR", zoneIds: ["EU"], lat: 49.0097, lng: 2.5479 },
  { code: "ORY", city: "Paris", name: "Orly", country: "FR", zoneIds: ["EU"], lat: 48.7233, lng: 2.3794 },
  { code: "FCO", city: "Roma", name: "Fiumicino", country: "IT", zoneIds: ["EU"], lat: 41.8003, lng: 12.2389 },
  { code: "MXP", city: "Milão", name: "Malpensa", country: "IT", zoneIds: ["EU"], lat: 45.6306, lng: 8.7281 },
  { code: "VCE", city: "Veneza", name: "Marco Polo", country: "IT", zoneIds: ["EU"], lat: 45.5053, lng: 12.3519 },
  { code: "AMS", city: "Amsterdã", name: "Schiphol", country: "NL", zoneIds: ["EU"], lat: 52.3105, lng: 4.7683 },
  { code: "FRA", city: "Frankfurt", name: "Frankfurt am Main", country: "DE", zoneIds: ["EU"], lat: 50.0379, lng: 8.5622 },
  { code: "SCL", city: "Santiago", name: "Arturo Merino Benítez", country: "CL", zoneIds: ["SA2"], lat: -33.393, lng: -70.7858 },
  { code: "EZE", city: "Buenos Aires", name: "Ezeiza", country: "AR", zoneIds: ["SA2"], lat: -34.8222, lng: -58.5358 },
  { code: "BOG", city: "Bogotá", name: "El Dorado", country: "CO", zoneIds: ["SA2"], lat: 4.7016, lng: -74.1469 },
  { code: "LIM", city: "Lima", name: "Jorge Chávez", country: "PE", zoneIds: ["SA2"], lat: -12.0219, lng: -77.1143 },
];

export function fold(text: string) {
  return text
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim();
}

export function haversineKm(from: { lat: number; lng: number }, to: { lat: number; lng: number }) {
  const toRad = (value: number) => (value * Math.PI) / 180;
  const dLat = toRad(to.lat - from.lat);
  const dLng = toRad(to.lng - from.lng);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(from.lat)) * Math.cos(toRad(to.lat)) * Math.sin(dLng / 2) ** 2;
  return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

export function getAirport(code: string) {
  return AIRPORTS.find((airport) => airport.code === code.toUpperCase());
}

export function airportLabel(code: string) {
  const airport = getAirport(code);
  if (!airport) return code.toUpperCase();
  return `${airport.city} · ${airport.code}`;
}

export function airportsNear(lat: number, lng: number, limit = 4, maxKm = 280) {
  return AIRPORTS.map((airport) => ({
    airport,
    km: Math.round(haversineKm({ lat, lng }, airport)),
  }))
    .sort((a, b) => a.km - b.km)
    .filter((item, index) => index === 0 || item.km <= maxKm)
    .slice(0, limit);
}
