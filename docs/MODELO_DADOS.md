# Modelo de dados — JetBoat

Modelo do banco da API (PostgreSQL 16, migrações pelo Prisma), a partir da lista de tabelas do `docs/prompts/PROMPT_SISTEMA_E_DESENVOLVIMENTO.md` e dos [`REQUISITOS.md`](REQUISITOS.md).

**Última revisão:** 11/11/2026 · **Status:** proposta (nenhuma tabela criada ainda; o banco nasce na Entrega 4) · **Relacionados:** [ADR 0001](adr/0001-concorrencia-das-agendas.md) (concorrência) · [`ARQUITETURA_C4.md`](ARQUITETURA_C4.md) (módulos da API)

**Sumário:** [1. Convenções](#1-convenções) · [2. Conta e acesso](#2-conta-e-acesso) · [3. Frota, passeios e reservas](#3-frota-passeios-e-reservas) · [4. Cotas e financeiro](#4-cotas-e-financeiro) · [5. Restrições e índices](#5-restrições-e-índices-importantes) · [6. Dono de cada tabela](#6-módulo-dono-de-cada-tabela) · [7. Diferenças em relação ao prompt](#7-diferenças-em-relação-à-lista-do-prompt) · [8. Histórico](#8-histórico)

---

## 1. Convenções

| Regra | Como |
|---|---|
| Chave primária | `id uuid` gerado como **UUID v7** (ordenável por tempo) |
| Datas de controle | `created_at`, `updated_at` (`timestamptz`, UTC) em todas as tabelas |
| Exclusão | soft delete (`deleted_at`) em `users`, `boats`, `tours`, `coupons`; o resto é apagado ou só muda de status |
| Dinheiro | sempre **centavos em `integer`** (sufixo `_centavos`), nunca `numeric` com vírgula nem `float` (RNF06) |
| Períodos | `tstzrange` com limite `[início, fim)`; datas de calendário em `daterange` |
| Estados | `enum` do Postgres (listados nos diagramas) |
| Arquivos | só a chave do objeto no S3/MinIO (`*_chave`); o acesso é por URL assinada (RNF03) |
| Nomes | tabelas e colunas em `snake_case`; tabelas em inglês, como no prompt, colunas descritivas |

Nos diagramas abaixo aparecem só as colunas importantes; `created_at` e `updated_at` estão em todas e foram omitidos.

---

## 2. Conta e acesso

```mermaid
erDiagram
  users ||--o{ user_roles : "tem papéis"
  users ||--o{ user_documents : "envia"
  users ||--o{ refresh_tokens : "tem sessões"
  users ||--o{ notifications : "recebe"
  users ||--o{ audit_logs : "faz ações"
  refresh_tokens |o--o| refresh_tokens : "substituído por"

  users {
    uuid id PK
    text nome
    char11 cpf UK "só dígitos"
    date data_nascimento
    text telefone "só dígitos"
    citext email UK "sem diferenciar maiúsculas"
    timestamptz email_verificado_em
    text senha_hash "Argon2id"
    text termos_versao
    timestamptz termos_aceitos_em
    inet termos_ip
    timestamptz deleted_at
  }
  user_roles {
    uuid user_id PK, FK
    papel papel PK "cliente | cotista | piloto | operador | admin"
  }
  user_documents {
    uuid id PK
    uuid user_id FK
    tipo_documento tipo "documento_foto | arrais_amador | motonauta"
    text arquivo_chave
    date validade
    status_documento status "pendente | aprovado | recusado"
    text motivo_recusa
    uuid revisado_por FK
    timestamptz revisado_em
  }
  refresh_tokens {
    uuid id PK
    uuid user_id FK
    uuid familia_id "revoga a família inteira em caso de reuso"
    bytea token_hash UK "SHA-256 do token opaco"
    timestamptz expira_em "30 dias"
    timestamptz usado_em
    timestamptz revogado_em
    uuid substituido_por FK
    inet ip
    text user_agent
  }
  notifications {
    uuid id PK
    uuid user_id FK
    canal canal "push | email"
    text tipo
    text titulo
    text corpo
    timestamptz enviado_em
    timestamptz lido_em
  }
  audit_logs {
    uuid id PK
    uuid ator_id FK
    text acao
    text entidade
    uuid entidade_id
    jsonb antes
    jsonb depois
    inet ip
  }
```

---

## 3. Frota, passeios e reservas

```mermaid
erDiagram
  boats ||--o{ boat_images : "tem fotos"
  boats ||--o{ tours : "faz passeios"
  boats ||--o{ schedules : "tem horários"
  boats ||--o{ ocupacoes : "tem a agenda"
  tours ||--o{ schedules : "acontece em"
  schedules ||--o{ bookings : "vende vagas"
  users ||--o{ bookings : "reserva"
  bookings ||--o{ booking_passengers : "leva"
  bookings ||--o| checkins : "check-in"
  bookings ||--o| reviews : "avaliação"
  coupons |o--o{ bookings : "desconto"
  ocupacoes |o--o| bookings : "ocupa por"
  ocupacoes |o--o| schedules : "ocupa por"
  season_periods }o--o| boats : "vale para"

  boats {
    uuid id PK
    text nome
    categoria categoria "jetski | lancha"
    int capacidade
    text marina
    bool is_fractional
    int total_shares "só se fracionada"
    status_boat status "ativa | manutencao | inativa"
    timestamptz deleted_at
  }
  boat_images {
    uuid id PK
    uuid boat_id FK
    text arquivo_chave
    int ordem
  }
  tours {
    uuid id PK
    uuid boat_id FK
    text titulo
    text descricao
    int duracao_min
    int preco_vaga_centavos
    int preco_exclusivo_centavos
    text local_saida
    jsonb rota
    text regras_seguranca
    timestamptz deleted_at
  }
  schedules {
    uuid id PK
    uuid tour_id FK
    uuid boat_id FK
    tstzrange periodo
    int vagas_total
    int vagas_vendidas "CHECK vagas_vendidas <= vagas_total"
    status_schedule status "aberto | lotado | cancelado"
  }
  bookings {
    uuid id PK
    uuid user_id FK
    uuid boat_id FK
    uuid schedule_id FK "passeio por vaga"
    tipo_booking tipo "passeio_vaga | passeio_exclusivo | aluguel"
    tstzrange periodo
    bool com_piloto
    int passageiros
    int total_centavos
    uuid coupon_id FK
    status_booking status "aguardando_pagamento | confirmada | cancelada | concluida"
    timestamptz expira_em "fim do prazo para pagar"
    text voucher_codigo UK
  }
  booking_passengers {
    uuid id PK
    uuid booking_id FK
    text nome
    text documento
    date data_nascimento
  }
  ocupacoes {
    uuid id PK
    uuid boat_id FK
    tstzrange periodo
    tipo_ocupacao tipo "reserva | horario_passeio | uso_cota | bloqueio"
    uuid booking_id FK
    uuid schedule_id FK
    uuid share_usage_id FK
    text motivo_bloqueio "manutenção ou clima"
    bool ativa "EXCLUDE (boat_id =, periodo &&) WHERE ativa"
  }
  season_periods {
    uuid id PK
    uuid boat_id FK "nulo = vale para toda a frota"
    text nome
    daterange periodo
    tipo_temporada tipo "alta_temporada | feriado"
  }
  checkins {
    uuid id PK
    uuid booking_id FK
    uuid share_usage_id FK
    uuid piloto_id FK
    timestamptz lido_em
  }
  reviews {
    uuid id PK
    uuid user_id FK
    uuid booking_id FK, UK
    smallint nota "1 a 5"
    text comentario
  }
  coupons {
    uuid id PK
    citext codigo UK
    tipo_cupom tipo "percentual | valor"
    int valor
    tstzrange validade
    int usos_max
    int usos
    timestamptz deleted_at
  }
```

---

## 4. Cotas e financeiro

```mermaid
erDiagram
  boats ||--o| share_plans : "plano de cotas"
  boats ||--o{ shares : "dividida em"
  users |o--o{ shares : "cotista"
  shares ||--o{ share_contracts : "contrato"
  shares ||--o{ share_usages : "agenda usos"
  share_usages ||--o| ocupacoes : "ocupa"
  share_usages ||--o{ inspections : "vistorias"
  inspections ||--o{ inspection_photos : "fotos"
  inspections ||--o{ incidents : "gera"
  boats ||--o{ boat_expenses : "despesas"
  boats ||--o{ announcements : "comunicados"
  users ||--o{ invoices : "faturas"
  shares ||--o{ invoices : "taxa mensal"
  invoices ||--o{ invoice_items : "itens"
  invoices ||--o{ payments : "pagamentos"
  bookings ||--o{ payments : "pagamentos"

  share_plans {
    uuid id PK
    uuid boat_id FK, UK
    int preco_cota_centavos
    jsonb condicoes_pagamento "[aberto]"
    int taxa_mensal_centavos
    int dias_uso_ano
    int antecedencia_min_dias
    int antecedencia_max_dias
    int max_agendamentos_futuros
    int limite_dias_alta_temporada
    int prazo_cancelamento_horas
    jsonb regra_ultimo_minuto "[aberto]"
    int diaria_piloto_centavos "[aberto]"
    date vigente_desde
  }
  shares {
    uuid id PK
    uuid boat_id FK
    int numero "UNIQUE (boat_id, numero)"
    uuid cotista_id FK
    status_share status "disponivel | reservada | ativa | suspensa | transferida"
    timestamptz reservada_ate
    timestamptz ativada_em
  }
  share_contracts {
    uuid id PK
    uuid share_id FK
    uuid user_id FK
    text modelo_versao
    timestamptz aceito_em
    inet ip
    text arquivo_chave "PDF assinado"
    bytea hash_documento
  }
  share_usages {
    uuid id PK
    uuid share_id FK
    uuid boat_id FK
    tstzrange periodo
    bool com_piloto
    numeric dias_descontados "0, 0.5 ou 1 por dia"
    status_uso status "agendado | em_uso | concluido | cancelado"
    timestamptz cancelado_em
  }
  inspections {
    uuid id PK
    uuid boat_id FK
    uuid share_usage_id FK
    uuid booking_id FK
    tipo_vistoria tipo "saida | retorno"
    uuid operador_id FK
    smallint combustivel_pct
    numeric horimetro
    jsonb itens_seguranca
    timestamptz confirmado_cotista_em
  }
  inspection_photos {
    uuid id PK
    uuid inspection_id FK
    text arquivo_chave
    text legenda
  }
  incidents {
    uuid id PK
    uuid boat_id FK
    uuid inspection_id FK
    text descricao
    uuid responsavel_id FK
    int custo_centavos
    status_incidente status "aberta | em_analise | resolvida"
  }
  boat_expenses {
    uuid id PK
    uuid boat_id FK
    categoria_despesa categoria "manutencao | seguro | marina | outros"
    text descricao
    int valor_centavos
    date competencia
    text comprovante_chave
  }
  announcements {
    uuid id PK
    uuid boat_id FK
    text titulo
    text corpo
    uuid publicado_por FK
    timestamptz publicado_em
  }
  invoices {
    uuid id PK
    uuid user_id FK
    uuid share_id FK
    date competencia "UNIQUE (share_id, competencia)"
    date vencimento
    int total_centavos
    status_fatura status "aberta | paga | vencida | cancelada"
    text gateway_cobranca_id
  }
  invoice_items {
    uuid id PK
    uuid invoice_id FK
    tipo_item tipo "taxa_mensal | combustivel | diaria_piloto | dano | parcela_cota | outros"
    text descricao
    int valor_centavos
    uuid share_usage_id FK
    uuid incident_id FK
  }
  payments {
    uuid id PK
    uuid user_id FK
    uuid booking_id FK
    uuid invoice_id FK
    metodo metodo "pix | cartao | boleto"
    int valor_centavos
    status_pagamento status "pendente | aprovado | recusado | estornado"
    text gateway_id UK "idempotência do webhook"
    jsonb payload_webhook
    timestamptz pago_em
  }
```

---

## 5. Restrições e índices importantes

| Onde | Regra | Por quê |
|---|---|---|
| `ocupacoes` | `EXCLUDE USING gist (boat_id WITH =, periodo WITH &&) WHERE (ativa)` (extensão `btree_gist`) | nenhuma reserva, horário de passeio, uso de cota ou bloqueio se sobrepõe na mesma embarcação ([ADR 0001](adr/0001-concorrencia-das-agendas.md), RNF05) |
| `ocupacoes` | `CHECK` de que exatamente uma das referências (`booking_id`, `schedule_id`, `share_usage_id`) está preenchida, ou nenhuma quando `tipo = bloqueio` | cada ocupação tem uma origem clara |
| `schedules` | `CHECK (vagas_vendidas <= vagas_total)`; venda por `UPDATE … SET vagas_vendidas = vagas_vendidas + n WHERE vagas_vendidas + n <= vagas_total` | duas reservas por vaga nunca passam da capacidade |
| `shares` | `UNIQUE (boat_id, numero)`; as N cotas são criadas de uma vez com o plano | é impossível vender mais cotas que o total (RF12) |
| `shares` | reservar = `UPDATE … SET status = 'reservada' WHERE id = ? AND status = 'disponivel'` | duas pessoas não reservam a mesma cota |
| `invoices` | `UNIQUE (share_id, competencia)` | o job mensal pode rodar de novo sem duplicar faturas |
| `payments` | `UNIQUE (gateway_id)` | o mesmo webhook processado duas vezes não paga duas vezes |
| `users` | `UNIQUE (cpf)`, `UNIQUE (email)` com `citext`, só entre não excluídos | mesma regra de unicidade do app de hoje |
| `refresh_tokens` | índice em `familia_id`; `UNIQUE (token_hash)` | revogar a família inteira no reuso ([ADR 0004](adr/0004-validade-refresh-token.md)) |
| `bookings` | índice parcial em `expira_em WHERE status = 'aguardando_pagamento'` | o worker cancela reservas não pagas |
| `ocupacoes`, `share_usages`, `schedules` | índice GiST em `(boat_id, periodo)` | calendário e disponibilidade rápidos (RNF04) |

---

## 6. Módulo dono de cada tabela

Só o módulo dono escreve na tabela; os outros leem pelo serviço dele.

| Módulo da API | Tabelas |
|---|---|
| Auth | `refresh_tokens` |
| Users | `users`, `user_roles` |
| Documents | `user_documents` |
| Boats | `boats`, `boat_images`, `season_periods` |
| Tours e Schedules | `tours`, `schedules` |
| Bookings e Check-in | `bookings`, `booking_passengers`, `checkins`, `ocupacoes` (dono da agenda: todos os outros módulos reservam espaço na agenda por ele) |
| Shares | `share_plans`, `shares`, `share_contracts` |
| ShareScheduling | `share_usages` |
| Inspections | `inspections`, `inspection_photos`, `incidents` |
| Billing e Payments | `invoices`, `invoice_items`, `payments`, `coupons` |
| Expenses | `boat_expenses` |
| Notifications, Reviews, Reports | `notifications`, `announcements`, `reviews` |
| Audit | `audit_logs` |

---

## 7. Diferenças em relação à lista do prompt

| Mudança | Motivo |
|---|---|
| **Nova tabela `ocupacoes`** | O prompt pede uma exclusion constraint por embarcação em reservas e em usos de cota. Como elas ficam em tabelas diferentes, o Postgres não impediria uma reserva de aluguel de cair em cima de um dia de cotista. Uma tabela única de ocupações resolve isso ([ADR 0001](adr/0001-concorrencia-das-agendas.md)) e também guarda os bloqueios de manutenção e clima (RF15, RF27), que não tinham tabela. |
| `invoice_items.tipo` inclui `parcela_cota` | Para o caso de compra de cota parcelada [aberto], as parcelas viram itens de fatura. |
| `share_usages.dias_descontados` | Guarda quanto cada uso consumiu do saldo (regra de "último minuto" pode descontar meio dia). |

---

## 8. Histórico

| Data | Mudança |
|---|---|
| 11/11/2026 | Criado (Entrega 1): diagrama ER em três partes, convenções, restrições, módulo dono e a tabela nova `ocupacoes`. |
