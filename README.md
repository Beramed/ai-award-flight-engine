# Voando com Tati

App próprio (PC + celular) para buscar destinos pelo nome, comparar **milhas** e **taxas em dólar**, e emitir com aprovação humana.

Pasta: `D:\Cursor projetos\voando-com-tati` (depois da migração).

Produção: https://ai-award-flight-engine.vercel.app

## Números das tabelas

- **Econômica / executiva / primeira** = milhas do programa, por passageiro, na ida.
- **Taxas (USD)** = dinheiro em dólar pago no resgate. Não é milha.

## Acesso

- Cadastro com nome completo, como quer ser chamado, CPF único, país, telefone, e-mail, endereço e senha (8–16, com minúscula, maiúscula e número).
- Login com nome de tratamento ou e-mail + senha.
- Master: usuário `Tati`, senha `0602`, painel em `/master` para prazos (indefinido, 7 dias, 1 mês, 6 meses, 1 ano).
- Apagar conta reserva o CPF naquele nome; o mesmo CPF em outro nome é recusado; no mesmo nome pergunta se deseja recuperar.

## Desenvolvimento

```bash
npm install
npm run dev
```
