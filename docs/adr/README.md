# Registros de decisão de arquitetura (ADRs)

Cada ADR registra **uma** decisão importante: o contexto, as opções consideradas, o que foi decidido e as consequências. Decisões não são apagadas: se mudarem, um novo ADR **substitui** o antigo, que fica marcado como "Substituído por 00XX".

## Índice

| ADR | Título | Status |
|---|---|---|
| [0001](0001-concorrencia-das-agendas.md) | Concorrência das agendas (reservas, usos de cota, bloqueios e venda de cotas) | Proposto |
| [0002](0002-rodizio-alta-temporada.md) | Rodízio de cotistas na alta temporada e feriados | Proposto |
| [0003](0003-cobranca-recorrente.md) | Cobrança recorrente das cotas | Proposto |
| [0004](0004-validade-refresh-token.md) | Validade e formato do refresh token | **Aceito** |
| [0005](0005-migracao-contas-locais.md) | Contas que existem só no aparelho | **Aceito** |
| [0006](0006-gerencia-de-estado.md) | Gerência de estado do app Flutter | Proposto |

## Status

- **Proposto:** em discussão; o código ainda não pode depender dele.
- **Aceito:** decidido; o código segue.
- **Substituído por 00XX:** trocado por outra decisão.
- **Rejeitado:** considerado e descartado (fica registrado para não ser discutido de novo).

## Modelo

```markdown
# 00XX — Título curto

**Status:** Proposto · **Data:** dd/mm/aaaa · **Decisores:** … · **Relacionados:** RF/RNF, outros ADRs

## Contexto
O problema e as restrições.

## Opções
### A — …
Prós, contras.

## Decisão
O que foi escolhido (ou a recomendação, se ainda Proposto) e por quê.

## Consequências
O que muda no código, nos dados e nos testes; riscos.
```
