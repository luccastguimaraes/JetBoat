# 0005 — Contas que existem só no aparelho

**Status:** Aceito · **Data:** 11/11/2026 · **Decisor:** responsável pelo produto (escolheu pedir novo cadastro) · **Relacionados:** RF01, RNF02, RNF03 · [`ARQUITETURA_C4.md`](../ARQUITETURA_C4.md) (A5)

## Contexto

Hoje cada conta existe **só no celular** onde foi criada:
- os dados ficam em `files/usuarios.json`, com hash PBKDF2-SHA1;
- a sessão usa uma chave HMAC no Keystore/Keychain.

Quando a API entrar (Entrega 4), as contas passam a ficar no PostgreSQL, com Argon2id. Não dá para levar a senha: o hash PBKDF2 não pode ser convertido em Argon2id, e o servidor nunca viu essas contas. Até agora só existem **contas de teste**.

## Opções

### A — Pedir novo cadastro
Na atualização, o app apaga os dados locais e a pessoa cria a conta na API.
- **Pró:** simples e seguro. Nenhum endpoint temporário, nenhuma senha trafegando para "migrar".
- **Contra:** quem já tinha conta cadastra de novo (hoje, só contas de teste).

### B — Migrar no primeiro login
No primeiro login após a atualização, o app confere a senha localmente e a envia para um endpoint de migração, que cria a conta com Argon2id.
- **Pró:** transparente para quem já usava o app.
- **Contra:**
  - Exige um endpoint temporário que aceita "criar conta + senha" fora do fluxo normal: mais superfície de ataque e mais código para remover depois.
  - A conta migrada não teria e-mail verificado (RF01).

## Decisão

**Opção A: pedir novo cadastro.**

## Consequências

Implementação na troca por `AutenticacaoApi` (item A5 do `ARQUITETURA_C4.md`):

1. **Limpeza na primeira abertura:** na primeira abertura da versão com API, o app apaga, uma única vez, o `usuarios.json`, a chave HMAC (`jetboat_jwt_hmac`) e os tokens locais do armazenamento seguro. Um marcador no armazenamento seguro garante que isso roda uma vez só.
2. **Mensagem:** se havia uma conta local, a tela inicial mostra uma única vez: "Atualizamos o JetBoat. Crie sua conta novamente para continuar."
3. **Código que sai do app:** `RepositorioUsuariosArquivo`, `Senha`, `Jwt`, `AssinadorHmac` e os testes deles. Os testes de compatibilidade com a versão Kotlin deixam de fazer sentido e saem junto.
4. **README e `ARQUITETURA_C4.md`:** atualizados no mesmo PR (item C3).
5. **CPF e e-mail reaproveitados:** como as contas antigas não existem no servidor, os mesmos CPF e e-mail podem ser usados no novo cadastro.
