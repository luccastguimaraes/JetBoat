# 0002 — Rodízio de cotistas na alta temporada e feriados

**Status:** Proposto · **Data:** 11/11/2026 · **Relacionados:** RF14, RF15, RNF08, RNF11 · [ADR 0001](0001-concorrencia-das-agendas.md)

> ⚖️ A regra escolhida entra no regulamento de uso e no contrato da cota. Precisa de validação jurídica antes de produção (RNF11).

## Contexto

Uma lancha dividida em 8 cotas tem poucos dias de alta temporada e feriados para muitos interessados. Se valer "quem agenda primeiro", os mesmos cotistas pegam sempre os melhores dias, o que gera reclamação e risco de contrato. O prompt pede um **limite de dias em alta temporada e feriados, com rodízio justo entre cotistas**.

Os períodos especiais ficam em `season_periods`, e cada cota tem um limite anual (`share_plans.limite_dias_alta_temporada`).

## Opções

### A — Ordem de chegada, com limite por cotista
Abre a agenda numa data e cada um agenda até o limite.
- **Pró:** simples de entender e implementar.
- **Contra:** premia quem está online na hora em que abre; os mesmos ganham todo ano.

### B — Sorteio por temporada
Os cotistas pedem dias numa janela e o sistema sorteia.
- **Pró:** igualdade de chance a cada temporada.
- **Contra:** não tem memória: alguém pode perder vários anos seguidos.

### C — Janela de pedidos + escolha em rodadas com ordem rotativa (recomendada)
1. **Janela de pedidos:** antes de cada temporada (ex.: 45 dias antes), abre uma janela de [aberto: 7] dias em que cada cotista **lista os dias que quer, em ordem de preferência**.
2. **Ordem da rodada 1:** quem ficou com **menos dias especiais no ciclo anterior** escolhe primeiro. No primeiro ano, a ordem é sorteada.
3. **Alocação em rodadas (estilo "draft serpentina"):** na rodada 1, cada cotista recebe o primeiro dia da sua lista que ainda estiver livre; na rodada 2 a ordem inverte (o último escolhe primeiro), e assim por diante, até acabar o limite de cada um ou os dias.
4. **Depois da janela:** os dias que sobrarem viram agendamento normal por ordem de chegada, respeitando o limite anual.
5. **Transparência:** o resultado e a ordem ficam visíveis para todos os cotistas da embarcação.

- **Pró:** justo ao longo do tempo (compensa quem ficou com menos), previsível e auditável. Não depende de estar online num horário.
- **Contra:** mais complexo; exige uma tela de pedidos por preferência e um job do worker que roda ao fechar a janela.

## Decisão (recomendação)

**Opção C.** A alocação roda como uma única transação no worker ao fechar a janela, gravando os usos e as ocupações ([ADR 0001](0001-concorrencia-das-agendas.md)). Depois de fechada, não há corrida.

Em aberto, para decidir junto com o regulamento:
- quantos dias antes abre a janela e quanto tempo ela dura;
- se feriados e alta temporada contam no mesmo limite ou em limites separados;
- o que acontece com um dia especial cancelado fora do prazo (perde o dia e conta no histórico?).

## Consequências

- **Testes de tabela** (RNF08) com: empate na ordem, cotista sem saldo, cotista inadimplente (não participa, RF19), pedidos iguais de todos, dia bloqueado por manutenção durante a janela.
- **Histórico de alocação:** precisa de uma tabela `alocacoes_temporada` (ou de colunas em `share_usages`) para calcular "quem ficou com menos". Ela entra no `MODELO_DADOS.md` quando o ADR for aceito.
- **App:** uma tela nova de pedidos, com a lista ordenada de dias e a posição na fila.
