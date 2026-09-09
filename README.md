# Award Engine

App web para PC e celular (PWA) que compara **tabela fixa** e **tabela dinâmica**, calcula **CPM** e prepara a emissão de passagens com milhas.

Produção: após o deploy, o Vercel imprime a URL do projeto.

## O que o motor faz

1. Coleta origem, destino, datas flexíveis, cabine e carteiras de milhas.
2. Estima preço em dinheiro (modelo de mercado equivalente a Google Flights / ITA Matrix).
3. Cruza a matriz de tabela fixa (AAdvantage, Iberia Plus, TAP Miles&Go).
4. Marca disponibilidade award por classe tarifária (T/U/Z ou X/I) de forma determinística para o intervalo.
5. Calcula `CPM = (preço em dinheiro − taxas) / milhas`.
6. Escolhe tabela fixa quando a vaga está aberta e o custo em milhas é melhor que a dinâmica, ou quando o CPM supera 0,015 USD.
7. Gera checklist, link do portal oficial e script de call center. **Pagamento só com aprovação humana.**

O app **não** faz login em companhias, **não** guarda senha de programa e **não** raspa sites de terceiros. Confirme sempre no portal oficial antes de emitir.

## Contas

- GitHub: repositório criado na organização/conta conectada ao `gh`.
- Vercel: projeto na conta `messias.jau@hotmail.com`.

## Desenvolvimento

```bash
npm install
npm run dev
```

Abra `http://localhost:3000`. No celular, use o mesmo Wi-Fi e o IP da máquina, ou instale o PWA a partir da URL de produção.
