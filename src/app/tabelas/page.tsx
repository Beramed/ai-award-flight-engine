import { FIXED_TABLES } from "@/lib/tables";

export default function TabelasPage() {
  return (
    <div className="stack">
      <section className="panel">
        <div className="panel-head">
          <h1>Tabelas fixas</h1>
          <p>Matriz award usada pelo motor. Classes tarifárias: T/U/Z (Oneworld) e X/I (Star Alliance / Iberia).</p>
        </div>
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Programa</th>
                <th>Zonas</th>
                <th>Econômica</th>
                <th>Executiva</th>
                <th>Primeira</th>
                <th>Taxas</th>
              </tr>
            </thead>
            <tbody>
              {FIXED_TABLES.map((table) => (
                <tr key={`${table.program}-${table.originZone}-${table.destinationZone}`}>
                  <td>
                    <strong>{table.program}</strong>
                    <div>{table.partnerAirline}</div>
                  </td>
                  <td>
                    {table.originZone} → {table.destinationZone}
                  </td>
                  <td>{(table.fixedRatesMiles.economy_off_peak ?? table.fixedRatesMiles.economy)?.toLocaleString("pt-BR") ?? "—"}</td>
                  <td>{(table.fixedRatesMiles.business_off_peak ?? table.fixedRatesMiles.business)?.toLocaleString("pt-BR") ?? "—"}</td>
                  <td>{table.fixedRatesMiles.first?.toLocaleString("pt-BR") ?? "—"}</td>
                  <td>US$ {table.taxesEstimatedUsd.toFixed(0)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
