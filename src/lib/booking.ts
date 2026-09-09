import { programPortalUrl } from "./market";
import type { AwardOption, BookingKit, TripSearch } from "./types";

export function buildBookingKit(option: AwardOption, search: TripSearch): BookingKit {
  const requiresPhone = option.partnerAirline.toLowerCase().includes("latam") || option.alliance === "Star Alliance";
  const passengers = `${search.adults} adulto(s)` +
    (search.children ? `, ${search.children} criança(s)` : "") +
    (search.infants ? `, ${search.infants} bebê(s)` : "");

  const callCenterScript = [
    `Olá, gostaria de emitir um award ${option.tableType === "FIXED" ? "de tabela fixa" : "dinâmico"}.`,
    `Programa: ${option.program}.`,
    `Rota: ${search.origin} → ${search.destination}${option.layover ? ` via ${option.layover.airport}` : ""}.`,
    `Ida: ${option.outboundDate}. Volta: ${option.inboundDate}.`,
    `Cabine: ${option.cabin}. Classe tarifária award: ${option.fareClass}.`,
    `Companhia operadora / parceira: ${option.partnerAirline}.`,
    `Passageiros: ${passengers}.`,
    `Milhas a debitar: ${option.miles.toLocaleString("pt-BR")}. Taxas estimadas: US$ ${option.taxesUsd.toFixed(2)}.`,
    "Por favor confirme disponibilidade da classe informada antes de emitir. Não autorize cobrança extra sem minha confirmação.",
  ].join(" ");

  const whatsappText = encodeURIComponent(
    `Award Engine · emissão pendente de aprovação\n${search.origin}→${search.destination} ${option.outboundDate}/${option.inboundDate}\n${option.program} · ${option.cabin} · classe ${option.fareClass}\n${option.miles.toLocaleString("pt-BR")} milhas + US$ ${option.taxesUsd.toFixed(2)} taxas\nCPM ${option.cpm.toFixed(3)} USD\nPortal: ${programPortalUrl(option.program)}`,
  );

  const checklist = [
    "Confira origem, destino, datas e cabine nesta tela.",
    "Abra o portal oficial do programa (link abaixo) — o app não faz login nem paga sozinho.",
    `Busque o voo e selecione a classe tarifária ${option.fareClass}.`,
    "Revise milhas + taxas antes de qualquer pagamento.",
    "Se o parceiro exigir telefone, use o script do call center.",
    "Só avance no pagamento das taxas depois de marcar a aprovação humana.",
  ];

  return {
    option,
    callCenterScript,
    whatsappText,
    checklist,
    officialSearchUrl: programPortalUrl(option.program),
    requiresPhone,
  };
}
