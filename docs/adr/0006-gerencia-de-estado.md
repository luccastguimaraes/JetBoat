# 0006 — Gerência de estado do app Flutter

**Status:** Proposto (decidir antes da Entrega 7: listagem, detalhes, reserva e voucher) · **Data:** 11/11/2026 · **Relacionados:** [`ARQUITETURA_C4.md`](../ARQUITETURA_C4.md) (seções 4, 6 e 7)

## Contexto

Hoje o app tem 4 telas com pouco estado.
- **Como funciona:** cada tela é um `StatefulWidget` que recebe a interface `Autenticacao` e callbacks pelo construtor. O `dependencias.dart` monta os objetos e o `app.dart` decide a navegação.
- **Por que funciona bem:** é simples, não tem biblioteca extra, e as regras de arquitetura (telas só com o domínio) são verificadas por teste.

As próximas entregas trazem muito mais estado, que precisa ser **compartilhado entre telas** e **atualizado** quando muda:
- lista de ofertas com filtros e paginação;
- disponibilidade;
- carrinho da reserva;
- faturas;
- saldo de dias da cota;
- agenda.

## Opções

### A — Manter `StatefulWidget` + callbacks (+ `ChangeNotifier` onde precisar)
- **Pró:** nenhuma dependência nova; o time já conhece; os testes atuais continuam iguais.
- **Contra:**
  - O estado compartilhado precisa ser passado "na mão" por vários construtores.
  - Cache, recarregamento e cancelamento de requisições ficam espalhados.
  - Cada tela reinventa "carregando / erro / dados".

### B — Riverpod (recomendada para a Entrega 7)
- **Pró:**
  - Estado assíncrono com "carregando / erro / dados" pronto (`AsyncValue`), cache e invalidação ("a reserva mudou, recarregue a disponibilidade").
  - Os providers substituem a passagem manual de dependências.
  - Nos testes, um provider pode ser sobrescrito por uma implementação falsa, como a `AutenticacaoFalsa` de hoje.
  - Não depende do `BuildContext` para ler o estado.
- **Contra:**
  - Uma dependência a mais e uma curva de aprendizado.
  - O `dependencias.dart` vira um conjunto de providers.
  - O teste de arquitetura precisa liberar `package:flutter_riverpod` para as telas.

### C — Bloc/Cubit
- **Pró:** muito estruturado e explícito.
- **Contra:** mais código cerimonial (eventos, estados) para um time pequeno; ganho parecido com o do Riverpod.

## Recomendação

**Manter a Opção A até a Entrega 6** e **adotar a Opção B (Riverpod) no início da Entrega 7**, quando aparecem as primeiras telas com estado compartilhado. A migração das 4 telas atuais é pequena e pode ser feita no mesmo PR.

Se for aceito, a adoção deve seguir estas regras:
1. **Domínio intacto:** o `lib/domain/` continua em Dart puro, sem Riverpod.
2. **Onde ficam os providers:** os de dados ficam junto do shell (`lib/dependencias.dart`, ou uma pasta `lib/providers/`, acrescentada ao `ARQUITETURA_C4.md` e ao teste de arquitetura). As telas leem providers, e nunca as implementações de `data/`.
3. **Navegação:** continua no `app.dart` com callbacks. Trocar para `go_router` é outra decisão, com outro ADR.

## Consequências (se aceito)

- Nova dependência `flutter_riverpod`.
- Atualizar `ARQUITETURA_C4.md` (seções 4, 6 e 7), `test/arquitetura_test.dart` e `DESIGN_SYSTEM.md` (estrutura padrão de tela).
- Testes de tela passam a usar `ProviderScope(overrides: [...])` com implementações falsas.
