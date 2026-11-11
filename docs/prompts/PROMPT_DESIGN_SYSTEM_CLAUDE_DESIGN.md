# JetBoat — Prompt de Design System (área Design do Claude)

**Onde usar:** cole o conteúdo abaixo da linha na área Design do Claude para gerar as telas do app, a página de apresentação e o painel administrativo. Ele também serve de referência ao pedir código de telas no Projeto, junto com o `JetBoat-Prompt-Sistema-e-Desenvolvimento.md`.

**Fonte da verdade:** `DESIGN_SYSTEM.md`, que descreve o código Flutter atual (a seção 13 dele liga o design system à arquitetura em `ARQUITETURA_C4.md`). Este arquivo reúne os valores dele e os do `PROMPT_DESIGN_SYSTEM_JETBOAT.md`, e acrescenta as telas novas, incluindo as de cotas.

**Manutenção:** os arquivos não se atualizam sozinhos. Quando mudar um token no `DESIGN_SYSTEM.md`, mude também aqui.

**Última revisão:** 11/11/2026 · Trechos entre `[ ]` são decisões ainda abertas.

---

# Design system do JetBoat: "Oceano ao pôr do sol"

Crie os designs do **JetBoat**, plataforma náutica com três linhas de negócio:

- **Passeios** com piloto.
- **Aluguel** de jetski e lancha.
- **Cotas (multipropriedade):** a pessoa compra uma fração de uma embarcação, por exemplo 1/8 de uma lancha. Com isso ganha dias de uso por ano, agenda esses dias pelo app e paga uma taxa mensal. A JetBoat cuida da embarcação, da marina, da manutenção, da agenda e da cobrança.

Use **exatamente** a identidade abaixo, que já está implementada no app Flutter. Não invente cores, fontes, raios, espaçamentos ou durações. Se faltar algo, diga o que falta e proponha um token ou componente, deixando claro que é uma proposta.

Os designs cobrem três produtos:

1. o **app mobile** (Android e iOS);
2. a **página de apresentação**;
3. o **painel administrativo** web.

## 1. Identidade

O visual é sempre escuro. O fundo é um degradê vertical: azul profundo → azul oceano → turquesa. O conteúdo fica em cartões de vidro translúcidos. A ação principal usa o degradê laranja → amarelo do sol.

**Princípios**

1. **Uma ação principal por tela**, sempre com o botão do sol. Se o sol aparece duas vezes, deixa de guiar.
2. **Agrupar em cartões de vidro**, nunca em blocos de cor sólida. O oceano deve continuar visível por trás do conteúdo.
3. **Texto claro sobre fundo escuro.** A hierarquia vem dos tokens de texto, não de transparências escolhidas na hora.
4. **O mesmo visual em Android e iOS.** O app não troca para o estilo Cupertino no iPhone. As diferenças entre plataformas ficam só no comportamento.
5. **Sem tema claro**, sem sombras e sem desfoque.

## 2. Cores

Os nomes dos tokens são os mesmos do código. O formato em Dart é `Color(0xAARRGGBB)`, em que os dois primeiros dígitos são a opacidade.

### 2.1 Paleta base

| Token | Hex | Dart | Uso |
|---|---|---|---|
| `oceanDeep` | `#031B34` | `Color(0xFF031B34)` | fundo; texto sobre o botão principal |
| `oceanBlue` | `#0A4D8C` | `Color(0xFF0A4D8C)` | meio do degradê de fundo |
| `oceanTeal` | `#0FA3B1` | `Color(0xFF0FA3B1)` | fim do degradê de fundo |
| `aqua` | `#4FF0E6` | `Color(0xFF4FF0E6)` | foco, seleção, links, rótulos de seção, cor primária |
| `foam` | `#E6FBFF` | `Color(0xFFE6FBFF)` | base dos textos |
| `sunsetOrange` | `#FF7A3D` | `Color(0xFFFF7A3D)` | início do degradê do botão principal |
| `sunsetYellow` | `#FFC94A` | `Color(0xFFFFC94A)` | fim do degradê do botão; números de destaque; alertas |
| `coral` | `#FF8A80` | `Color(0xFFFF8A80)` | erros |

### 2.2 Degradês

| Degradê | Direção | Cores | Onde |
|---|---|---|---|
| `fundoOceano` | vertical (topo → base) | `oceanDeep` 0% → `oceanBlue` 55% → `oceanTeal` 100% | fundo de toda tela, ocupando a altura inteira |
| Sol | horizontal (esquerda → direita) | `sunsetOrange` → `sunsetYellow` | só no botão principal |
| Marca "JetBoat" | diagonal (↘) | `foam` → `aqua` → `sunsetYellow` | só no logotipo |

### 2.3 Superfícies de vidro

São todas branco translúcido sobre o fundo, sem desfoque e sem sombra.

| Token | Opacidade | Dart | Uso |
|---|---|---|---|
| `glassField` | branco 5% | `Color(0x0DFFFFFF)` | campo em repouso |
| `glassFieldFocused` | branco 8% | `Color(0x14FFFFFF)` | campo com foco |
| `glassSurface` | branco 10% | `Color(0x1AFFFFFF)` | cartões |
| `glassWhite` | branco 15% | `Color(0x26FFFFFF)` | selos, botão voltar, barras vazias |
| `glassBorder` | branco 25% | `Color(0x40FFFFFF)` | bordas |

### 2.4 Texto

| Token | Valor | Uso |
|---|---|---|
| `textPrimary` | branco | títulos, valores, texto digitado |
| `textSecondary` | `foam` 85% | subtítulos, corpo |
| `textMuted` | `foam` 70% | legendas, rótulos em repouso |
| `textHint` | `foam` 40% | placeholders |

### 2.5 Qual cor usar

| Preciso de… | Use |
|---|---|
| Fundo de tela | `fundoOceano` (já aplicado pela tela base) |
| Agrupar conteúdo | cartão de vidro (`glassSurface` + `glassBorder`) |
| Foco ou seleção | `aqua` |
| Destacar um número (preço, total, saldo de dias) | `sunsetYellow` com `titleLarge` |
| Erro | `coral` |
| Alerta que não é erro | `sunsetYellow` |
| Texto sobre o botão principal | `oceanDeep` |

### 2.6 Contraste medido (obrigatório respeitar)

Razão de contraste WCAG 2.1 do texto sobre um cartão de vidro, em cada ponto do degradê. O mínimo AA é **4,5** para texto normal e **3,0** para texto grande (≥ 18 pt, ou ≥ 14 pt em negrito).

| Texto | sobre `oceanDeep` | sobre `oceanBlue` | sobre `oceanTeal` |
|---|---|---|---|
| `textPrimary` | 13,2 ✅ | 6,7 ✅ | 2,7 ❌ |
| `textSecondary` | 9,3 ✅ | 5,0 ✅ | 2,2 ❌ |
| `textMuted` | 6,9 ✅ | 4,0 ⚠️ só grande | 2,0 ❌ |
| `textHint` | 3,3 ⚠️ só grande | 2,3 ❌ | 1,5 ❌ |
| `aqua` | 9,4 ✅ | 4,7 ✅ | 1,9 ❌ |
| `sunsetYellow` | 8,6 ✅ | 4,4 ⚠️ só grande | 1,8 ❌ |
| `coral` | 5,8 ✅ | 2,9 ❌ | 1,2 ❌ |

O botão principal passa: `oceanDeep` sobre `sunsetOrange` dá 6,7 e sobre `sunsetYellow` dá 11,3.

**Na prática:**

- Não coloque texto no trecho turquesa do fundo.
- Mantenha erros em `coral` na parte escura da tela.
- Não use `textHint` em informação importante.
- Em telas longas, garanta que o conteúdo que rola continue dentro de cartões.

## 3. Tipografia

A fonte é a do sistema: Roboto no Android, San Francisco no iOS e uma sans do sistema no web. Os tamanhos estão em pixels lógicos e respeitam a fonte grande do sistema. A altura de linha só separa as linhas: não acrescenta espaço acima da primeira nem abaixo da última.

| Estilo | Tamanho / linha / peso | Uso |
|---|---|---|
| `displayLarge` | 52 / 58 / 900, espaçamento −1 | marca "JetBoat" |
| `headlineLarge` | 30 / 36 / 900 | título de tela |
| `titleLarge` | 20 / 26 / 800 | números de destaque, título de diálogo |
| `titleMedium` | 17 / 22 / 700 | nome ou título dentro de cartão |
| `bodyLarge` | 16 / 23 / 400 | subtítulo de tela, texto corrido |
| `bodyMedium` | 14 / 20 / 400 | apoio, links, avisos |
| `bodySmall` | 12 / 16 / 400 | legendas, mensagens de erro |
| `labelLarge` | 17 / 22 / 800 | texto de botão |
| `labelMedium` | 12 / 16 / 700, espaçamento 1,2, CAIXA ALTA | rótulo de seção |
| `labelSmall` | 11 / 14 / 500 | microtexto |

**Combinações padrão**

| Elemento | Estilo | Cor |
|---|---|---|
| Título de tela | `headlineLarge` | `textPrimary` |
| Subtítulo de tela | `bodyLarge` | `textSecondary` |
| Título dentro de cartão | `titleMedium` | `textPrimary` |
| Corpo | `bodyMedium` | `textSecondary` |
| Legenda | `bodySmall` | `textMuted` |
| Rótulo de seção | `labelMedium` | `aqua` |
| Número de destaque | `titleLarge` | `sunsetYellow` |

O rótulo flutuante dos campos aparece em 12 (equivalente a `bodySmall`).

## 4. Espaçamento, formas e medidas

### 4.1 Espaçamento (`Espacamento`, base 4)

| Token | Valor | Uso típico |
|---|---|---|
| `xs` | 4 | ícone ↔ texto; entre itens de um cartão |
| `sm` | 8 | entre itens de uma lista curta; acima de cada campo |
| `md` | 12 | entre campos de formulário |
| `lg` | 16 | entre blocos dentro de um cartão |
| `xl` | 24 | entre seções da tela |
| `xxl` | 32 | antes de um bloco final isolado |
| `margemTela` | 20 | margem lateral de toda tela |
| `margemVerticalTela` | 12 | margem superior e inferior |
| `paddingCartao` | 16 | padding interno dos cartões |

### 4.2 Formas (`Formas`)

O raio cresce com o tamanho do elemento: campo < botão < cartão.

| Token | Raio | Uso |
|---|---|---|
| `campo` | 14 | campos, avisos |
| `botao` | 18 | botões |
| `cartao` | 22 | cartões de vidro |
| `pilula` | 999 | selos (o botão voltar é um círculo) |

### 4.3 Medidas (`Medidas`)

| Token | Valor | Uso |
|---|---|---|
| `alturaBotao` | 58 | botão principal e secundário |
| `botaoIcone` | 44 | botão voltar e botões só de ícone |
| `borda` | 1 | bordas de vidro em repouso |
| `bordaDestaque` | 1,5 | contorno do botão secundário e do círculo do logo |

Nos campos, a borda com foco ou com erro tem 2. As bordas de cartão e de aviso são desenhadas por cima do conteúdo, sem ocupar espaço.

## 5. Elevação

**Não há sombras.** A profundidade vem das camadas de vidro:

| Nível | Superfície | Token |
|---|---|---|
| 0 | fundo | `fundoOceano` |
| 1 | campo em repouso | `glassField` (5%) |
| 2 | campo com foco | `glassFieldFocused` (8%) |
| 3 | cartão | `glassSurface` (10%) |
| 4 | selo, botão voltar | `glassWhite` (15%) |
| exceção | cartão de categoria clicável | degradê de branco 20% → 8% |

## 6. Iconografia e imagens

- **Emojis como ícones.** Tamanhos: 54 no logo, ≈ 44 no cabeçalho de tela e 32 nos cartões de categoria.
  - 🚤 logo, Jetski e login
  - 🛥️ Lancha
  - 🔑 Cotas
  - 🌊 botão "Começar a navegar"
  - ⚓ cadastro
  - 👋 painel
  - 🎉 conta criada
  - 💪 senha forte
  - ★ avaliação
- **Seta de voltar desenhada:** 18 × 18, traço de 2,2, pontas arredondadas, cor `foam`, dentro de um círculo de vidro a 15%.
- **Ponto de status:** círculo de 8 em `aqua`.
- **Checkbox:**
  - marcada: `aqua`, com o visto em `oceanDeep`;
  - borda: `textMuted` (`coral` com erro).
- **Ilustração da tela inicial:**
  - ondas em 3 camadas;
  - brilho do sol pulsando;
  - barco do logo balançando, com uma aura pulsante;
  - marca no degradê da marca.
- **Fotos de embarcações e passeios:** dentro de cartões, com o raio do cartão. Texto sobre foto só com uma faixa de `oceanDeep` translúcido por trás [proposta].
- **Ícones para o painel admin ou para itens sem emoji:** proponha Material Icons na variante arredondada, sempre como proposta.

## 7. Movimento

Curva padrão: `fastOutSlowIn`, que acelera e desacelera no fim.

| Token | Valor | Uso |
|---|---|---|
| `curta` | 250 ms | mudanças pequenas de estado (barras de força da senha, aviso aparecendo) |
| `media` | 600 ms | entrada de um bloco de conteúdo |
| `escalonamento` | 150 ms | atraso entre blocos que entram em sequência |
| `transicaoTela` | 700 ms | troca de tela em fade cruzado |
| `brilhoBotao` | 2600 ms, contínuo | faixa de brilho do botão principal |
| `balancoBarco` | 1800 ms, vai e volta | barco do logo: ±6 de altura e ±4,8° |
| `pulsoAura` | 2200 ms, vai e volta | aura do logo: escala 0,9 → 1,15 |
| `pulsoSol` | 3000 ms, vai e volta | brilho do sol: escala 0,95 → 1,08 |
| `ondas` | 4000 ms, contínuo | 3 camadas de ondas, em velocidades ×1, ×−1,5 e ×2 |

Na entrada da tela inicial, cada bloco aparece com fade e sobe ⅓ da própria altura, em `media`, com `escalonamento` entre um bloco e o próximo.

## 8. Componentes existentes (use antes de criar novos)

| Componente | Visual | Parâmetros no código |
|---|---|---|
| `TelaBase` | fundo em degradê na tela inteira, áreas seguras, rolagem, margem lateral de 20 | `children`, `rolavel`, `paddingVertical` |
| `BotaoPrincipal` | degradê do sol, altura 58, raio 18, texto `labelLarge` em `oceanDeep`, faixa de brilho animada; estado "carregando" com indicador de 26 em `oceanDeep` | `texto`, `onPressed`, `carregando` |
| `BotaoSecundario` | contorno de 1,5, altura 58, raio 18 | `texto`, `onPressed` |
| `BotaoVoltar` | círculo de vidro de 44 com a seta desenhada | `onPressed` |
| `CabecalhoTela` | emoji opcional + título `headlineLarge` + subtítulo `bodyLarge` | `titulo`, `subtitulo`, `emoji` |
| `CartaoVidro` | vidro a 10%, borda a 25%, raio 22, padding 16, itens a 4 de distância; título opcional como rótulo de seção | `titulo`, `children` |
| `RotuloSecao` | caixa alta, `labelMedium`, `aqua` | `texto` |
| `Aviso` | faixa com raio 14; `coral` para erro, `sunsetYellow` para alerta | `texto`, `cor` |
| `mostrarMensagem` | mensagem rápida (snackbar) | `context`, `texto` |
| `CampoTexto` | vidro a 5% (8% com foco), raio 14, rótulo flutuante, foco `aqua`, erro `coral` com borda de 2; estados repouso, foco, erro e desabilitado; máscaras de CPF, data e telefone | `controller`, `rotulo`, `erro`, `onChanged`, `teclado`, `acao`, `formatadores`, `capitalizacao`, `dica`, `sufixo`, `onSubmitted`, `ocultar`, `habilitado` |
| `CampoSenha` | campo com "Mostrar/Ocultar" e barrinhas de força (raio 3, altura 5, espaço 6) | `controller`, `rotulo`, `erro`, `onChanged`, `acao`, `onSubmitted`, `habilitado` |
| Cartão de categoria | emoji de 32 + nome, com o degradê de vidro mais claro | (exceção de arte) |

**Estrutura de uma tela, de cima para baixo:** voltar → cabeçalho → cartões → ação principal → ação secundária (opcional). Use 24 (`xl`) entre as seções. Numa tela sem rolagem, a ação fica presa embaixo.

**Exceções permitidas** (são arte, não componentes):
- as ilustrações da tela inicial;
- o cartão de categoria clicável;
- as barrinhas de força da senha.

Qualquer exceção nova precisa ser aprovada e entrar nesta lista.

## 9. Android e iOS

- Barra de status com ícones claros nas duas plataformas.
- Conteúdo sempre dentro das áreas seguras (notch, Dynamic Island, recorte da câmera, barra de início), nunca com margem fixa no topo.
- O botão voltar aparece em toda tela, porque o gesto de arrastar do iOS não funciona hoje.
- Mensagens rápidas em snackbar nas duas plataformas, sem Toast.
- Com o teclado aberto, o conteúdo sobe e rola.
- Cada plataforma mantém o próprio efeito de rolagem: esticar no Android, quicar no iOS.
- A área mínima de toque é 44 hoje (o Material pede 48).

## 10. Checklist de cada tela entregue

- [ ] Só tokens desta lista, ou propostas marcadas como tal
- [ ] Fundo em degradê com o conteúdo em cartões de vidro
- [ ] No máximo um botão do sol
- [ ] Estilos e cores das combinações padrão
- [ ] Nenhum texto sobre o trecho turquesa do fundo
- [ ] Ordem voltar → cabeçalho → cartões → ação principal → ação secundária
- [ ] Layout funciona com a fonte do sistema no tamanho máximo, sem texto cortado
- [ ] Considerado o teclado aberto, em telas com campos
- [ ] Áreas seguras de iPhone com notch ou Dynamic Island respeitadas
- [ ] Textos em português do Brasil

## 11. O que ainda não tem padrão

Para estes itens, proponha uma solução e marque como proposta. Use só os tokens existentes: vidro, raios 14/18/22/999, base 4 e sem sombras.

**Prioridade alta (afetam uso e acessibilidade)**
- **Estado desabilitado e pressionado dos botões.**
  - Desabilitado: degradê com opacidade reduzida e texto `textMuted`.
  - Pressionado: degradê levemente mais escuro.
- **Área de toque de 48 no botão voltar:** manter o desenho em 44.
- **Contraste do fim do degradê, de `textHint` e de `coral`:**
  - escurecer o fim do degradê ou limitar o turquesa à parte sem conteúdo;
  - subir `textHint` para pelo menos 55%;
  - testar um `coral` mais claro.

**Prioridade média**
- Cores de sucesso (sugestão: um verde-água) e de informação (sugestão: `aqua`)
- Diálogo padrão em vidro
- Snackbar em vidro
- Componente de link (sugestão: `bodyMedium` + `aqua`)
- Controles: switch, rádio, abas, chips de filtro, seletor de data e horário, stepper de passageiros
- Badges de status de reserva: pendente, confirmada, cancelada, concluída
- Badges de status de cota: disponível, reservada, ativa, suspensa
- Badges de status de fatura: em aberto, paga, vencida
- Calendário de uso de cotas (proposta de estados):
  - livre: contorno `glassBorder`;
  - meu agendamento: preenchido em `aqua` com texto `oceanDeep`;
  - ocupado por outro cotista: `glassWhite` com texto `textMuted`;
  - bloqueado (manutenção ou clima): contorno `sunsetYellow`;
  - alta temporada: ponto `sunsetYellow`.
- Tabela de dados, gráficos e cards de KPI para o painel
- Fonte da marca
- Ícone do app
- Tela de abertura do iOS em `oceanDeep`

**Prioridade baixa**
- Biblioteca de ícones
- Layout para tablet e telas largas (limitar a largura do conteúdo)
- Desfoque no vidro

## 12. Entregas

### 12.1 App mobile

**Telas que já existem** (recrie fiéis ao código):
- **Tela inicial:**
  - marca animada, ondas e sol;
  - selo;
  - cartões de categoria 🚤 Jetski, 🛥️ Lancha e 🔑 Cotas;
  - botão "Começar a navegar" 🌊.
- **Cadastro ⚓:**
  - dados pessoais com CPF, data de nascimento e telefone;
  - senha com barrinhas de força 💪;
  - aceite de termos;
  - diálogo "Conta criada" 🎉.
- **Login 🚤.**
- **Painel 👋**, com "Sair da conta" preso embaixo.

**Passeios e aluguel**
- Lista de ofertas por categoria, com filtros
- Detalhes da oferta:
  - galeria e rota no mapa;
  - duração e capacidade;
  - regras de segurança;
  - avaliação ★;
  - preço em `sunsetYellow`.
- Fluxo de reserva: horário → passageiros → pagamento → confirmação, com o total em destaque
- Minhas reservas e voucher com QR Code
- Avaliação depois do passeio

**Cotas (multipropriedade)**
- **Vitrine de cotas:** embarcações fracionadas, com:
  - cotas disponíveis (ex.: "3 de 8");
  - preço da cota;
  - taxa mensal;
  - dias de uso por ano.
- **Detalhes da embarcação fracionada:**
  - fotos e ficha técnica;
  - marina;
  - o que a taxa mensal cobre;
  - regras de uso;
  - simulação de pagamento.
- **Compra da cota:** simulação → leitura e aceite do contrato → pagamento → "Cota ativa" 🔑.
- **Minhas cotas:**
  - um cartão por cota, com a embarcação e a fração;
  - saldo de dias no ano, em `sunsetYellow`;
  - próximo uso;
  - situação da fatura.
- **Calendário de uso** com os estados da seção 11, legenda e saldo de dias.
- **Agendar uso:**
  - data;
  - com ou sem piloto (sem piloto exige habilitação válida);
  - resumo dos custos;
  - confirmação.
- **Check-out e check-in:** vistoria com fotos, combustível, horímetro e confirmação do cotista.
- **Extrato e faturas:**
  - taxa mensal;
  - combustível, piloto e danos;
  - status da fatura;
  - pagamento por Pix ou cartão.
- **Prestação de contas** da embarcação (despesas do mês) e documentos (contrato, regulamento, seguro).
- **Aviso de inadimplência:** `Aviso` em `sunsetYellow` informando que novos agendamentos estão bloqueados.

**Perfil e documentos**
- Dados pessoais
- Envio de documento com foto e de habilitação náutica (Arrais-Amador ou Motonauta), com status de aprovação

**Modo piloto e operador**
- Agenda do dia
- Leitor de QR Code para check-in
- Lista de passageiros
- Vistoria de saída e de retorno
- Registro de ocorrência

### 12.2 Página de apresentação (web, responsiva, priorizando mobile)

- **Hero:**
  - mesmo fundo em degradê, com a ilustração de ondas e sol;
  - marca "JetBoat" no degradê da marca;
  - um único CTA do sol ("Reservar agora" ou "Baixar o app").
- **Seções em cartões de vidro:**
  - como funciona (3 passos);
  - categorias (Jetski, Lancha, Cotas);
  - passeios em destaque;
  - **seção de multipropriedade:** como funciona a cota, o que a JetBoat cuida, dias de uso, taxa mensal, simulação e CTA secundário "Quero ser cotista";
  - segurança e equipamentos;
  - depoimentos;
  - galeria;
  - FAQ (incluindo dúvidas sobre cotas);
  - download do app;
  - rodapé.
- **Fundo em páginas longas:** repita o degradê por seção ou use `oceanDeep` como base, para o texto nunca cair sobre o turquesa.

### 12.3 Painel administrativo (web)

**Layout**
- Mesmos tokens, com densidade maior.
- Sidebar em vidro.
- Conteúdo sobre `oceanDeep`, ou sobre um degradê suave que não chegue ao turquesa atrás de tabelas.
- KPIs com os números em `sunsetYellow`.
- Tabelas dentro de cartões de vidro.
- Um botão do sol por tela (ex.: "Nova embarcação"); as demais ações usam botão secundário.

**Telas**
- Login
- Dashboard: ocupação, receita por linha de negócio, cotas vendidas e disponíveis, inadimplência, reservas do dia, cancelamentos e nota média
- Agenda geral da frota, com bloqueio de manutenção e de clima
- Embarcações (marcando as fracionadas) e planos de cota (preço, taxa, dias por ano, regras)
- Cotistas (cotas, situação financeira, uso, documentos) e aprovação de habilitações
- Faturamento e inadimplência
- Vistorias e ocorrências, com fotos
- Despesas por embarcação
- Passeios, reservas, cupons, comunicados, usuários e papéis, relatórios e log de auditoria

## 13. Lugar na arquitetura (C4)

O design system é um componente da arquitetura C4 do JetBoat (detalhes em `docs/ARQUITETURA_C4.md` e na seção 13 do `DESIGN_SYSTEM.md`):

- **Nível 2 (containers):** é uma biblioteca compartilhada por três containers, que recebem os mesmos tokens pelo pacote `design_tokens`:
  - o app mobile;
  - o painel admin;
  - a página de apresentação.
- **Nível 3 (componentes do app):**
  - **Tokens** ficam em `lib/ui/theme/`.
  - **Widgets** ficam em `lib/ui/components/`.
  - As **Telas** usam os dois e recebem dados prontos do **Domínio**.

O que isso muda nos designs:

1. **Componentes são visuais, sem regra de negócio.** Um componente recebe textos, valores, estados e ações. Por exemplo, o campo mostra o erro, mas quem decide se o CPF é válido é a regra do domínio.
2. **Todo componente novo é desenhado para servir app, painel e site.** Indique quais variações cada produto usa.
3. **Cada componente novo é documentado** com nome, variações, estados e os dados que recebe. Isso vira a interface do widget no código.
4. **Estados que vêm do servidor** precisam de design:
   - carregando;
   - vazio;
   - erro de conexão;
   - sessão expirada;
   - bloqueio temporário por muitas tentativas (com o tempo restante).
   Faça isso em toda tela que busca dados, porque o app vai passar a depender da API.

## 14. Ao entregar

- Documente cada componente novo com variações, estados e regras de uso.
- Liste todo token novo proposto.
- Exporte os tokens em formato que possa ser convertido para Dart (`lib/ui/theme/`) e CSS, com os mesmos nomes (`oceanDeep`, `aqua`, `glassSurface`, `Espacamento.lg`, `Formas.cartao`…).
- Textos da interface em português do Brasil.
