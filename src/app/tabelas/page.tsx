import { FIXED_TABLES } from "@/lib/tables";

function miles(value?: number) {
  return typeof value === "number" ? `${value.toLocaleString("pt-BR")} milhas` : "—";
}

export default function TabelasPage() {
  return (
    <div className="stack">
      <section className="panel">
        <div className="panel-head">
          <h1>Tabelas de milhas</h1>
          <p>
            Os valores de econômica, executiva e primeira são <strong>milhas reais do programa</strong>{" "}
            (ida, por passageiro). A última coluna é <strong>taxa em dólares americanos (USD)</strong>,
            paga em dinheiro no resgate — não é milha.
          </p>
        </div>
        <div className="legend">
          <p>
            <b>Milhas</b> = custo do prêmio no programa (AAdvantage, Smiles, Skywards etc.).
          </p>
          <p>
            <b>US$</b> = taxas de embarque/combustível estimadas em dólar. CPM usa o preço da
            passagem em dinheiro também em USD.
          </p>
        </div>
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Programa / cia</th>
                <th>Rota</th>
                <th>Econômica (milhas)</th>
                <th>Executiva (milhas)</th>
                <th>Primeira (milhas)</th>
                <th>Taxas (USD)</th>
              </tr>
            </thead>
            <tbody>
              {FIXED_TABLES.map((row) => (
                <tr key={`${row.program}-${row.partnerAirline}-${row.originZone}-${row.destinationZone}`}>
                  <td>
                    <strong>{row.program}</strong>
                    <div>{row.partnerAirline}</div>
                    <small>{row.alliance}</small>
                  </td>
                  <td>
                    {row.originZone} → {row.destinationZone}
                  </td>
                  <td>{miles(row.fixedRatesMiles.economy_off_peak ?? row.fixedRatesMiles.economy)}</td>
                  <td>{miles(row.fixedRatesMiles.business_off_peak ?? row.fixedRatesMiles.business)}</td>
                  <td>{miles(row.fixedRatesMiles.first)}</td>
                  <td>US$ {row.taxesEstimatedUsd.toFixed(0)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
