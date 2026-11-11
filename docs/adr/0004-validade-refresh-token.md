# 0004 — Validade e formato do refresh token

**Status:** Aceito · **Data:** 11/11/2026 · **Decisor:** responsável pelo produto (escolheu 30 dias) · **Relacionados:** RF02 · [`ARQUITETURA_C4.md`](../ARQUITETURA_C4.md) (A1, A2) · [`MODELO_DADOS.md`](../MODELO_DADOS.md) (`refresh_tokens`)

## Contexto

O app de hoje emite os próprios tokens no aparelho, com refresh de **7 dias**. O prompt de desenvolvimento define, para a API, refresh de **30 dias**, opaco, guardado como hash no banco, com rotação e detecção de reuso.

## Opções

### A — 7 dias (como no app atual)
- **Pró:** uma janela menor para um token roubado.
- **Contra:** quem passa uma semana sem abrir o app (comum fora da temporada) precisa entrar de novo.

### B — 30 dias, com rotação e detecção de reuso
- **Pró:** o cliente quase nunca precisa entrar de novo. A rotação a cada uso, junto com a revogação da família no reuso, limita o estrago de um token roubado: no primeiro uso pelo atacante ou pelo dono legítimo, a família inteira cai.
- **Contra:** um token parado e roubado vale por mais tempo, até ser usado pela primeira vez.

## Decisão

**Opção B: 30 dias.**

| Item | Valor |
|---|---|
| Access token | JWT de **15 min**, assinado com RS256 (ou EdDSA), claims `sub`, `roles`, `iat`, `exp`, `jti` |
| Refresh token | **opaco** (256 bits aleatórios), válido por **30 dias** a partir da emissão |
| Guardado no banco | só o **hash SHA-256** do token (`refresh_tokens.token_hash`) |
| Rotação | a cada `/auth/refresh`, o token usado é marcado (`usado_em`, `substituido_por`) e um novo é emitido na mesma `familia_id` |
| Reuso | se chegar um refresh já usado ou revogado, **toda a família** é revogada e a pessoa precisa entrar de novo |
| Logout | revoga a família da sessão atual |
| No app | `flutter_secure_storage` (como hoje) |
| No painel web | cookie `HttpOnly`, `Secure`, `SameSite=Strict` |

O prazo de 30 dias **não** é renovado a cada rotação: o token novo herda o `expira_em` da família. Depois de 30 dias da última entrada com senha, a pessoa entra de novo.

> **Atenção:** se a regra preferida for uma janela deslizante (30 dias **sem usar** o app), é só trocar "herda o `expira_em`" por "`expira_em` = agora + 30 dias". Essa troca deve ser registrada aqui.

## Consequências

- **No app, até a API existir:** a implementação local (`AutenticacaoLocal`) continua com 7 dias. A mudança acontece na troca por `AutenticacaoApi` (item A2 do `ARQUITETURA_C4.md`).
- **Na API:** o módulo Auth implementa a rotação e o reuso, com testes de roubo (o mesmo refresh usado duas vezes revoga tudo).
- **Painel:** "sair de todos os aparelhos" (revogar todas as famílias do usuário) fica disponível no painel e no app.
