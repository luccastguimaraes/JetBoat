# Requisitos — JetBoat

Requisitos refinados a partir do `docs/prompts/PROMPT_SISTEMA_E_DESENVOLVIMENTO.md`. Cada requisito tem critérios de aceite no formato **dado / quando / então**, prioridade, dependências e a situação no código de hoje.

**Última revisão:** 11/11/2026 · **Relacionados:** [`MODELO_DADOS.md`](MODELO_DADOS.md) (tabelas) · [`ARQUITETURA_C4.md`](ARQUITETURA_C4.md) (containers e módulos) · [`adr/`](adr/) (decisões)

> **Como ler:**
> - **Prioridade:** **MVP** = entra na primeira versão publicada. **Fase 2** = depois do MVP. O recorte é uma **proposta** (seção 4) para você aprovar.
> - **Situação:** ✅ feito · 🟡 parcial · ⬜ não iniciado.
> - **[aberto]:** decisão ainda não tomada. Está listada na seção 5 e não deve ser assumida no código.

**Sumário:** [1. Perfis](#1-perfis-de-usuário) · [2. Funcionais](#2-requisitos-funcionais) · [3. Não funcionais](#3-requisitos-não-funcionais) · [4. Recorte do MVP](#4-recorte-do-mvp-proposta) · [5. Decisões em aberto](#5-decisões-em-aberto) · [6. Histórico](#6-histórico)

---

## 1. Perfis de usuário

| Perfil | Papel no sistema (`user_roles.papel`) | Onde usa |
|---|---|---|
| Cliente | `cliente` (todo usuário cadastrado) | app |
| Cotista | `cotista` (ganho ao ativar a primeira cota) | app |
| Piloto (marinheiro) | `piloto` | app, modo piloto |
| Operador de marina | `operador` | app, modo operador |
| Administrador | `admin` | painel |

Um usuário pode ter vários papéis. Papéis diferentes de `cliente` só são dados por um admin (RF32), exceto `cotista`, que o sistema concede ao ativar uma cota (RF13).

---

## 2. Requisitos funcionais

### 2.1 Conta e acesso

#### RF01 — Cadastro · MVP · 🟡 parcial
Nome, CPF, data de nascimento, telefone, e-mail, senha (com indicador de força) e aceite de termos, com verificação de e-mail e recuperação de senha.

- **Dado** um formulário válido, **quando** a pessoa toca em Cadastrar, **então** a conta é criada, a sessão é aberta e ela vai para o painel.
- **Dado** um CPF ou e-mail já usado (e-mail sem diferenciar maiúsculas; CPF só pelos dígitos), **quando** cadastra, **então** o campo mostra "CPF já cadastrado" / "E-mail já cadastrado" e nada é criado.
- **Dado** menos de 18 anos, CPF com dígito verificador errado, celular sem 9 após o DDD ou senha sem letras e números, **então** o campo mostra o erro e o servidor não é chamado.
- **Dado** um cadastro novo, **quando** a conta é criada, **então** um e-mail de verificação é enviado; até verificar, a pessoa pode navegar, mas **não** pode reservar nem comprar cota.
- **Dado** "Esqueci minha senha", **quando** a pessoa informa o e-mail, **então** recebe um link de uso único válido por [aberto: 30 ou 60 min], e a resposta é a mesma exista ou não o e-mail.
- O aceite de termos guarda a versão dos termos, a data e o IP.

**Depende de:** API Auth (A1). **Hoje:** cadastro, validações e unicidade feitos no aparelho; faltam verificação de e-mail, recuperação de senha e a API.

#### RF02 — Login · MVP · 🟡 parcial
Login por e-mail e senha. Login social (Google, Apple) na Fase 2.

- **Dado** e-mail e senha corretos, **então** a sessão abre (access 15 min + refresh 30 dias, [ADR 0004](adr/0004-validade-refresh-token.md)).
- **Dado** e-mail inexistente ou senha errada, **então** a mensagem é genérica ("E-mail ou senha incorretos") e o tempo de resposta é parecido nos dois casos.
- **Dado** 5 erros seguidos para o mesmo e-mail, **então** a API responde 429 com `Retry-After`, e o app mostra a contagem no botão.
- **Dado** o app reaberto com refresh válido, **então** a pessoa entra direto no painel; com refresh vencido ou revogado, volta ao login com "Sua sessão expirou".

**Depende de:** A1, A2, A3. **Hoje:** tudo isso funciona no aparelho (bloqueio em memória, refresh de 7 dias); falta levar para a API.

#### RF03 — Perfil e documentos · MVP · ⬜
Envio de documento com foto e habilitação náutica (Arrais-Amador para lancha, Motonauta para jetski), com validade e aprovação do admin.

- **Dado** um documento enviado, **então** ele fica "pendente" até um admin aprovar ou recusar (com motivo).
- **Dado** uma habilitação vencida ou recusada, **então** aluguel e uso de cota **sem piloto** ficam bloqueados (RF07, RF16).
- Arquivos ficam em bucket privado, acessados só por URL assinada que expira (RNF03).
- **Dado** uma habilitação a [aberto: 30] dias de vencer, **então** a pessoa é avisada (RF24).

**Depende de:** RF01, S3/MinIO, RF26.

### 2.2 Passeios e aluguel

#### RF04 — Listar ofertas · MVP · ⬜
Por categoria (Jetski, Lancha, Passeios), com filtros de data, duração, preço e local de saída.

- **Dado** uma categoria tocada na tela inicial, **então** abre a lista daquela categoria (hoje mostra só uma mensagem).
- **Dado** filtros aplicados, **então** só aparecem ofertas com disponibilidade no período.
- Preços em reais a partir de centavos (RNF06); lista paginada.

#### RF05 — Detalhes da oferta · MVP · ⬜
Fotos, rota, duração, capacidade, regras de segurança e avaliação média.

- **Dado** uma oferta sem avaliações, **então** a nota não aparece (nada de "0 estrelas").

#### RF06 — Disponibilidade em tempo real · MVP · ⬜
Por horário e embarcação.

- **Dado** que outra pessoa reservou o último horário, **quando** eu tento reservar, **então** recebo "Esse horário acabou de ser reservado" (HTTP 409) e a lista é atualizada ([ADR 0001](adr/0001-concorrencia-das-agendas.md)).

#### RF07 — Reserva · MVP · ⬜
Número de passageiros e dados de cada um.

- **Dado** mais passageiros que a capacidade ou que as vagas restantes, **então** a reserva é recusada.
- **Dado** aluguel sem piloto, **então** é exigida habilitação aprovada e válida na data do aluguel e compatível com a categoria (RF03).
- **Dado** uma reserva criada, **então** ela fica "aguardando pagamento" e segura a vaga por [aberto: 15 min]; sem pagamento nesse prazo, é cancelada e a vaga volta.

#### RF08 — Pagamento online · MVP · ⬜
[aberto: Pix e cartão; gateway a definir — [ADR 0003](adr/0003-cobranca-recorrente.md)], com confirmação por webhook.

- **Dado** o webhook de pagamento aprovado, **então** a reserva vira "confirmada" e o voucher é emitido. O app nunca confirma sozinho.
- **Dado** o mesmo webhook recebido duas vezes, **então** o efeito acontece uma vez só (idempotência pelo id do gateway).
- **Dado** um webhook sem assinatura válida, **então** ele é rejeitado.

#### RF09 — Cancelamento e reembolso · MVP · ⬜
Conforme política configurável por tipo de oferta. ⚖️ Depende de validação jurídica (RNF11).

- **Dado** um cancelamento dentro do prazo da política, **então** o reembolso é integral; fora do prazo, segue a tabela da política.
- **Dado** um cancelamento pela JetBoat (clima, manutenção), **então** o reembolso é sempre integral, ou a pessoa remarca.

#### RF10 — Voucher e check-in · MVP · ⬜
- **Dado** uma reserva confirmada, **então** o app mostra um voucher com QR Code que funciona sem internet.
- **Dado** que o piloto lê o QR Code, **então** o check-in é registrado com hora e piloto; um segundo check-in do mesmo voucher é recusado.

#### RF11 — Avaliação · Fase 2 · ⬜
- **Dado** uma reserva concluída, **então** a pessoa pode avaliar (1 a 5 e comentário) uma única vez.

### 2.3 Cotas (multipropriedade)

> ⚖️ Todo o bloco depende do contrato de multipropriedade, da política de cancelamento e do regulamento de uso validados por advogado antes de produção (RNF11).

#### RF12 — Oferta de cotas · MVP · ⬜
O admin cadastra a embarcação fracionada com total de cotas, preço, condições de pagamento [aberto: à vista, entrada + parcelas], taxa mensal, dias de uso por ano e regras de agenda (RF14).

- **Dado** uma embarcação com 8 cotas, **então** o sistema cria as cotas numeradas de 1 a 8 de uma vez; a venda nunca passa do total ([ADR 0001](adr/0001-concorrencia-das-agendas.md)).
- **Dado** uma mudança de preço ou de regra, **então** ela vale para novas vendas; quem já é cotista segue o contrato que assinou.

#### RF13 — Compra de cota · MVP · ⬜
Simulação → proposta → aceite do contrato digital (versão, data, hora, IP) → pagamento.

- **Dado** a proposta aceita, **então** a cota fica "reservada" até [aberto: prazo] para pagar; sem pagamento, volta a "disponível".
- **Dado** o pagamento confirmado por webhook, **então** a cota vira "ativa" e o usuário ganha o papel `cotista`.
- **Dado** duas pessoas tentando a última cota ao mesmo tempo, **então** só uma consegue; a outra recebe "Cota indisponível".
- O contrato aceito é guardado em PDF com hash, e não é apagado junto com a conta (RNF03).

#### RF14 — Regras de agenda · MVP · ⬜
Configuráveis por embarcação: dias de uso por ano; antecedência mínima e máxima; máximo de agendamentos futuros; limite em alta temporada e feriados com rodízio justo ([ADR 0002](adr/0002-rodizio-alta-temporada.md)); prazo de cancelamento sem perder o dia; "último minuto" (dias livres em até [aberto: 48 h] não descontam ou descontam metade).

- Cada regra tem teste de tabela com casos de borda: saldo zerado, alta temporada no limite, cancelamento um minuto antes e um minuto depois do prazo, inadimplente (RNF08).

#### RF15 — Agendamento de uso · MVP · ⬜
Calendário com dias livres, ocupados, bloqueados (manutenção ou clima) e do próprio cotista, mais o saldo de dias do ano.

- **Dado** um dia ocupado por reserva de passeio, aluguel, outro cotista ou bloqueio, **então** ele não pode ser agendado. Nada se sobrepõe, nem entre tipos diferentes ([ADR 0001](adr/0001-concorrencia-das-agendas.md)).
- **Dado** saldo zerado, **então** só dias de "último minuto" podem ser agendados.
- **Dado** cancelamento dentro do prazo, **então** o dia volta ao saldo; fora do prazo, é descontado.

#### RF16 — Uso com ou sem piloto · MVP · ⬜
- **Dado** uso sem piloto, **então** exige habilitação válida (RF03).
- **Dado** uso com piloto, **então** a diária [aberto: valor] vai para o extrato (RF18).

#### RF17 — Check-out e check-in com vistoria · MVP · ⬜
- **Dado** saída e retorno, **então** o operador registra fotos, combustível, horímetro e itens de segurança, e o cotista confirma no app.
- **Dado** diferença entre saída e retorno (dano, item faltando), **então** é aberta uma ocorrência (RF29).

#### RF18 — Custos de uso · MVP · ⬜
- **Dado** um uso concluído, **então** combustível consumido, diária de piloto e danos lançados viram itens do extrato do cotista e entram na próxima fatura (RF19).

#### RF19 — Cobrança recorrente · MVP · ⬜
Fatura mensal da taxa da cota + custos de uso, com lembrete antes do vencimento ([ADR 0003](adr/0003-cobranca-recorrente.md)).

- **Dado** o dia [aberto: 1º do mês?], **então** a fatura de cada cota ativa é gerada uma vez só (o job pode rodar de novo sem duplicar).
- **Dado** uma fatura vencida há mais de [aberto: X] dias, **então** o cotista não consegue fazer novos agendamentos até pagar; os já feitos [aberto: são mantidos?].

#### RF20 — Prestação de contas · Fase 2 · ⬜
- **Dado** um cotista, **então** ele vê as despesas da embarcação (RF30) e o histórico de uso.

#### RF21 — Documentos da cota · MVP · ⬜
- Contrato, regulamento de uso, apólice de seguro e faturas disponíveis no app, por URL assinada.

#### RF22 — Transferência ou revenda · Fase 2 · ⬜
Com aprovação do admin e novo contrato.

#### RF23 — Comunicados · Fase 2 · ⬜
- **Dado** um comunicado para uma embarcação, **então** todos os cotistas dela recebem push e o veem no app.

### 2.4 Notificações

#### RF24 — Push e e-mail · MVP (parcial) · ⬜
- **MVP:** confirmação de reserva e pagamento, lembrete 24 h antes, mudança por clima, fatura a vencer, verificação de e-mail e recuperação de senha.
- **Fase 2:** vistoria pendente, comunicados (RF23), habilitação a vencer.
- **Dado** que a pessoa desligou push, **então** os avisos obrigatórios (pagamento, mudança por clima) seguem por e-mail.

### 2.5 Painel administrativo

| Requisito | Prioridade | Critério principal |
|---|---|---|
| **RF25** — CRUD de embarcações (marcando as fracionadas), passeios, horários, preços, cupons e regras de cota | MVP | Uma embarcação com reservas futuras não pode ser apagada, só desativada |
| **RF26** — Gestão de cotistas: cotas, situação financeira, uso no ano, documentos, aprovação de habilitação | MVP | Aprovar ou recusar documento grava quem, quando e o motivo |
| **RF27** — Agenda da frota com bloqueio de manutenção e clima | MVP | Ao bloquear um período, o painel lista as reservas e usos afetados antes de confirmar, e as pessoas afetadas são avisadas |
| **RF28** — Faturamento: geração mensal, baixa por webhook, inadimplência | MVP | A baixa só acontece por webhook ou por ação manual auditada |
| **RF29** — Vistorias e ocorrências com fotos e responsável | MVP | Ocorrência tem status (aberta, em análise, resolvida) |
| **RF30** — Despesas por embarcação | Fase 2 | Base da prestação de contas (RF20) |
| **RF31** — Dashboard (ocupação, receita por linha, cotas, inadimplência, cancelamentos, nota) | Fase 2 | — |
| **RF32** — Usuários, papéis e auditoria de toda ação administrativa | MVP | Toda ação de admin gera um registro em `audit_logs` com antes e depois |

---

## 3. Requisitos não funcionais

| Requisito | Critério verificável | Situação |
|---|---|---|
| **RNF01** — API REST `/api/v1` com OpenAPI | Swagger publicado em `/api/docs` em dev; todo endpoint documentado | ⬜ |
| **RNF02** — Argon2id; HTTPS em produção | Nenhuma senha em log; produção recusa HTTP | ⬜ (hoje PBKDF2 no aparelho) |
| **RNF03** — LGPD | Consentimento registrado; exportação e exclusão de dados pelo app; documentos em bucket privado com URL assinada; contratos e dados financeiros guardados pelo prazo legal mesmo após a exclusão | ⬜ |
| **RNF04** — p95 < 300 ms nas leituras | Medido em teste de carga das rotas de listagem e detalhe | ⬜ |
| **RNF05** — Sem sobreposição | Exclusion constraint no Postgres + teste de concorrência com reservas simultâneas ([ADR 0001](adr/0001-concorrencia-das-agendas.md)) | ⬜ |
| **RNF06** — Dinheiro e datas | Valores em centavos (`integer`); datas em UTC (`timestamptz`), exibidas em America/Bahia | ⬜ |
| **RNF07** — Observabilidade | Logs estruturados (pino) com request-id; `/health` e `/ready` | ⬜ |
| **RNF08** — Testes | ≥ 80% de cobertura nos serviços de domínio; testes de tabela das regras de cota | 🟡 o app tem 64 testes no computador e 7 no aparelho |
| **RNF09** — pt-BR | Todos os textos em pt-BR; `.arb` quando a tradução for priorizada | 🟡 textos em pt-BR, ainda no código |
| **RNF10** — WCAG 2.1 AA | Contraste conforme a seção 2.6 do `DESIGN_SYSTEM.md`; textos legíveis com fonte grande do sistema | 🟡 pendências de contraste no "A definir" do design system |
| **RNF11** — Validação jurídica | Contrato de cota, política de cancelamento e regulamento validados antes de produção | ⬜ |

---

## 4. Recorte do MVP (proposta)

**Proposta para você aprovar.** O MVP é o menor conjunto em que as três linhas de negócio funcionam de ponta a ponta com dinheiro de verdade.

| Bloco | No MVP | Fica para a Fase 2 |
|---|---|---|
| Conta | RF01, RF02, RF03 | login social |
| Passeios e aluguel | RF04 a RF10 | RF11 (avaliação) |
| Cotas | RF12 a RF19, RF21 | RF20, RF22, RF23 |
| Notificações | RF24 (parte MVP) | RF24 (parte Fase 2) |
| Painel | RF25 a RF29, RF32 | RF30, RF31 |

**Por que RF20 e RF30 ficam fora:** a prestação de contas é importante para a confiança do cotista, mas não bloqueia agendar, usar e pagar. Pode entrar logo após o MVP.

---

## 5. Decisões em aberto

Itens marcados com `[ ]` no prompt de desenvolvimento. Não devem ser assumidos no código.

| Decisão | Onde aparece | Observação |
|---|---|---|
| Gateway de pagamento e métodos (Pix, cartão, boleto) | RF08, RF19 | critérios e candidatos no [ADR 0003](adr/0003-cobranca-recorrente.md) |
| Condições de pagamento da cota (à vista, entrada + parcelas) | RF12, RF13 | define se a compra vira várias faturas |
| Prazo para pagar uma cota reservada | RF13 | sugestão: 48 h |
| Regra de "último minuto" (48 h? desconta 0 ou meio dia?) | RF14 | |
| Dias de inadimplência para bloquear agendamentos, e o que acontece com os já feitos | RF19 | |
| Valor da diária do piloto | RF16, RF18 | por embarcação ou fixo |
| Assinatura eletrônica do contrato (aceite no app basta?) | RF13 | ⚖️ jurídico |
| Tempo que uma reserva segura a vaga sem pagamento | RF07 | sugestão: 15 min |
| Validade do link de recuperação de senha | RF01 | sugestão: 30 min |
| Recorte do MVP (seção 4) | — | proposta |
| Algoritmo do rodízio de alta temporada | RF14 | proposta no [ADR 0002](adr/0002-rodizio-alta-temporada.md) |
| Gerência de estado do app | — | [ADR 0006](adr/0006-gerencia-de-estado.md), proposto |

---

## 6. Histórico

| Data | Mudança |
|---|---|
| 11/11/2026 | Criado (Entrega 1): requisitos refinados com critérios de aceite, prioridade, situação atual, recorte do MVP proposto e decisões em aberto. |
