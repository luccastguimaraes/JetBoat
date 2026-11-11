# 0003 — Cobrança recorrente das cotas

**Status:** Proposto · **Data:** 11/11/2026 · **Relacionados:** RF08, RF13, RF18, RF19, RF28, RNF06 · [`MODELO_DADOS.md`](../MODELO_DADOS.md) (`invoices`, `invoice_items`, `payments`)

## Contexto

Todo mês, cada cota ativa gera uma fatura com:

- a **taxa mensal** fixa da cota (marina, manutenção, seguro, gestão);
- os **custos de uso** do mês, que **variam**: combustível, diária de piloto e danos (RF18);
- se a compra da cota for parcelada [aberto], a **parcela** do mês.

A fatura precisa de lembrete antes do vencimento e baixa por webhook. Se houver inadimplência acima de [aberto: X dias], o cotista fica bloqueado para novos agendamentos (RF19).

O gateway de pagamento ainda não foi escolhido [aberto].

## Opções

### A — Assinatura recorrente no gateway
O gateway cobra a taxa fixa todo mês sozinho.
- **Pró:** menos código; cobrança automática no cartão.
- **Contra:**
  - Os custos de uso mudam todo mês e não cabem numa assinatura de valor fixo. Viram uma segunda cobrança, e o cotista recebe duas contas.
  - A regra de negócio (o que entra na fatura) fica dividida entre o nosso sistema e o gateway.
  - Trocar de gateway exige migrar as assinaturas.

### B — Faturas geradas pelo nosso worker e cobranças avulsas no gateway (recomendada)
1. **Geração:** um job do worker (BullMQ) roda no dia [aberto: 1º] de cada mês e, para cada cota ativa, cria a fatura da competência com todos os itens. A restrição `UNIQUE (share_id, competencia)` deixa o job rodar de novo sem duplicar.
2. **Cobrança:** para cada fatura, cria **uma** cobrança no gateway (Pix com QR Code, boleto e, se o gateway permitir, cartão salvo do cotista), guardando `gateway_cobranca_id`.
3. **Baixa:** o webhook confirma o pagamento:
   - a assinatura do webhook é conferida;
   - `payments.gateway_id` é único, então um webhook repetido não paga duas vezes;
   - a fatura vira "paga".
4. **Lembretes:** jobs agendados mandam lembrete [aberto: 3] dias antes e no dia do vencimento (RF24).
5. **Inadimplência:** um job diário marca as faturas vencidas e, passado o prazo [aberto], suspende novos agendamentos do cotista.

- **Pró:** uma fatura só por mês com tudo; a regra fica no nosso código e é testável; trocar de gateway mexe só no módulo Payments.
- **Contra:** mais código no worker; o cartão recorrente depende de o gateway permitir cobrar um cartão salvo (tokenizado).

## Decisão (recomendação)

**Opção B.** Os valores são sempre em centavos (RNF06), e a competência é calculada no fuso America/Bahia.

### Critérios para escolher o gateway (decisão em aberto)

| Critério | Peso |
|---|---|
| Pix com QR Code dinâmico e webhook | obrigatório |
| Boleto | desejável |
| Cobrança em cartão salvo (tokenização) para a fatura mensal | desejável |
| Webhook assinado, com reenvio automático | obrigatório |
| Estorno via API (RF09) | obrigatório |
| Ambiente de testes (sandbox) | obrigatório |
| Taxas por transação | comparar |

Candidatos a avaliar: Asaas, Mercado Pago, Pagar.me e Stripe. A escolha vira um ADR próprio.

## Consequências

- **Módulo Payments:** expõe uma interface `GatewayPagamento` (criar cobrança, estornar, validar webhook). O gateway escolhido é só uma implementação dela; nos testes, usa-se uma implementação falsa.
- **Testes:**
  - Job mensal idempotente (rodar 2 vezes = mesmas faturas).
  - Webhook repetido.
  - Webhook com assinatura inválida.
  - Fatura com custos de uso.
  - Bloqueio por inadimplência no limite exato de dias.
- **Risco:** um webhook perdido deixa uma fatura paga como "aberta". **Mitigação:** um job diário de conciliação consulta no gateway as cobranças abertas há mais de 1 dia.
