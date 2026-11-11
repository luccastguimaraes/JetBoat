# 0001 — Concorrência das agendas

**Status:** Proposto · **Data:** 11/11/2026 · **Relacionados:** RNF05, RF06, RF07, RF12, RF13, RF15, RF27 · [`MODELO_DADOS.md`](../MODELO_DADOS.md)

## Contexto

Uma mesma embarcação recebe, ao mesmo tempo, quatro tipos de compromisso:

1. **reservas** de aluguel e de passeio exclusivo;
2. **horários de passeio** vendidos por vaga;
3. **usos de cota** agendados por cotistas;
4. **bloqueios** de manutenção e de clima.

Nenhum deles pode se sobrepor a outro na mesma embarcação, mesmo com várias pessoas clicando no mesmo segundo (RNF05). Além disso:
- a venda de cotas não pode passar do total da embarcação (RF12);
- a venda de vagas de um passeio não pode passar da capacidade.

O prompt de desenvolvimento pede uma *exclusion constraint* do PostgreSQL (`btree_gist` + `tstzrange`) por embarcação, mais transação.

## Opções

### A — Exclusion constraint em cada tabela (`bookings`, `share_usages`)
- **Pró:** simples, segue o prompt ao pé da letra.
- **Contra:** uma constraint só enxerga a própria tabela. Um aluguel em `bookings` e um uso de cota em `share_usages` no mesmo dia **não se bloqueiam**. Seria preciso conferir as outras tabelas no código, o que volta a ter corrida entre duas transações.

### B — Tabela única de ocupações com uma exclusion constraint (recomendada)
Toda vez que algo ocupa a embarcação, cria-se uma linha em `ocupacoes(boat_id, periodo, tipo, origem)`:

```sql
CREATE EXTENSION IF NOT EXISTS btree_gist;

ALTER TABLE ocupacoes ADD CONSTRAINT ocupacoes_sem_sobreposicao
  EXCLUDE USING gist (boat_id WITH =, periodo WITH &&) WHERE (ativa);
```

- **Pró:** o banco garante a regra para **todos** os tipos de uma vez, sem corrida. Bloqueios de manutenção e clima ganham um lugar natural.
- **Contra:** uma tabela a mais. A reserva e a ocupação precisam ser gravadas na mesma transação.

### C — Lock pessimista (`SELECT … FOR UPDATE` na embarcação) e conferência no código
- **Pró:** funciona com qualquer modelo.
- **Contra:** serializa todas as reservas da embarcação, mesmo as que não conflitam. Uma conferência esquecida em algum caminho do código deixa passar sobreposição. O banco não protege.

## Decisão (recomendação)

**Opção B**, com estas regras:

1. **Ocupações:** o módulo Bookings é o dono da tabela `ocupacoes`. Reservas, usos de cota (ShareScheduling) e bloqueios (Boats) criam e cancelam ocupações **pelo serviço dele**, dentro da mesma transação da operação de origem.
2. **Conflito vira 409:** se o Postgres recusar a gravação (erro `23P01`, *exclusion_violation*), a API responde **409 Conflict** com Problem Details (`type: /problemas/horario-indisponivel`). O app mostra "Esse horário acabou de ser reservado" e recarrega a disponibilidade (RF06).
3. **Cancelar não apaga:** um cancelamento marca `ativa = false`, o que libera o período e mantém o histórico.
4. **Passeio por vaga:** o horário inteiro é **uma** ocupação (`tipo = horario_passeio`). As vagas são vendidas com um `UPDATE` condicional atômico:
   ```sql
   UPDATE schedules SET vagas_vendidas = vagas_vendidas + $n
   WHERE id = $id AND vagas_vendidas + $n <= vagas_total
   RETURNING id;   -- nenhuma linha = sem vagas → 409
   ```
5. **Venda de cotas:**
   - As N cotas da embarcação são **criadas de uma vez** (`shares` numeradas de 1 a N, `UNIQUE (boat_id, numero)`). Assim é impossível vender mais do que N.
   - Reservar uma cota é um `UPDATE … SET status = 'reservada' WHERE id = $id AND status = 'disponivel'`. Nenhuma linha atualizada significa que a cota já foi pega.
6. **Reservas não pagas:** reservas e cotas "aguardando pagamento" seguram o período até `expira_em`. Um job do worker cancela as vencidas e libera a ocupação.
7. **Isolamento:** o padrão do Postgres (*read committed*) basta, porque as garantias vêm da constraint e dos `UPDATE` condicionais, não de leituras seguidas de escrita.

## Consequências

- **Banco:** a migração inicial cria a extensão `btree_gist`. O Docker Compose da Entrega 3 já sobe o Postgres com ela.
- **Testes:**
  - Teste de concorrência com Testcontainers: 20 reservas simultâneas no mesmo período, só 1 pode passar.
  - Teste de tabela cruzando tipos (aluguel × uso de cota × bloqueio).
- **Painel (RF27):** ao criar um bloqueio, o painel primeiro lista as ocupações em conflito. O bloqueio só é gravado depois que elas forem remarcadas ou canceladas, senão a constraint recusa.
- **Risco:** esquecer de criar a ocupação num caminho novo. **Mitigação:** só o serviço do Bookings escreve em `ocupacoes`, e os outros módulos não acessam a tabela direto (regra verificada em code review e por teste de integração).
