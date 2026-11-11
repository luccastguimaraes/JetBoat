> **Observação:** Os dois arquivos (`DESIGN_SYSTEM.md` e `PROMPT_DESIGN_SYSTEM_JETBOAT.md`) não se atualizam sozinhos. Quando mudar um token no `DESIGN_SYSTEM.md`, mude também no prompt, senão o Claude vai trabalhar com valores antigos.

Você vai me ajudar a criar e revisar telas do app **JetBoat** em **Flutter + Dart** (Material 3), que roda em **Android e iOS**. Siga à risca o design system abaixo, que descreve o código que já existe no projeto. Se algo que eu pedir não estiver coberto por ele, não invente valores: diga qual token ou widget está faltando e proponha um, deixando claro que é uma proposta.

## Regra principal

Nunca escreva cor, fonte, raio de canto, espaçamento ou duração à mão fora de `lib/ui/theme/` (`Color(0x…)`, `.withValues(alpha: …)`, `EdgeInsets.all(16)`, `SizedBox(height: 24)`, `fontSize: 17`, `BorderRadius.circular(22)`, `Duration(milliseconds: 250)`). Use sempre os tokens e widgets abaixo. As únicas exceções estão na seção "Exceções permitidas".

## Arquivos do projeto

- Cores: `lib/ui/theme/cores.dart` (constantes de nível superior, sem classe: `aqua`, `textSecondary`…)
- Tipografia e tema: `lib/ui/theme/tema.dart` (`tipografia`, o `TextTheme`; e `temaJetBoat`, o `ThemeData` com `useMaterial3: true`, `Brightness.dark`, `primary: aqua`, `error: coral`, `scaffoldBackgroundColor: oceanDeep`)
- Espaçamentos, formas e medidas: `lib/ui/theme/dimens.dart` (classes `Espacamento`, `Formas`, `Medidas`)
- Movimento: `lib/ui/theme/movimento.dart` (classe `Movimento`)
- Widgets gerais: `lib/ui/components/componentes.dart` (inclui `fundoOceano`, `TelaBase`, `mostrarMensagem` e o atalho `context.texto`)
- Campos de formulário: `lib/ui/components/campos.dart`
- Máscaras: `lib/ui/components/mascara.dart`
- App, rotas e transição de tela: `lib/app.dart`; composição dos objetos: `lib/dependencias.dart`
- Domínio da conta (Dart puro): `lib/domain/conta/` (`Perfil`, interface `Autenticacao`, resultados, `ValidadorCadastro`)
- Implementações (arquivo, JWT, armazenamento seguro): `lib/data/` — as telas nunca importam daqui
- Arquitetura completa (C4): `docs/ARQUITETURA_C4.md`
- Telas: uma pasta por tela em `lib/ui/` (`home`, `cadastro`, `login`, `painel`)
- Tela de abertura: Android em `android/app/src/main/res/` (já em `oceanDeep`); iOS em `ios/Runner/Base.lproj/LaunchScreen.storyboard` (ainda branca). Se `oceanDeep` mudar, as duas precisam mudar também.

## Identidade

"Oceano ao pôr do sol." O app é sempre escuro, com fundo em degradê azul profundo → azul oceano → turquesa (`fundoOceano`). O conteúdo fica em cartões de vidro translúcidos, e a ação principal usa o degradê laranja → amarelo do sol (dentro do `BotaoPrincipal`).

1. Uma ação principal por tela, sempre com `BotaoPrincipal`.
2. Agrupe o conteúdo em `CartaoVidro`, nunca em blocos de cor sólida.
3. Texto claro sobre fundo escuro, com a hierarquia dada pelos tokens de texto.
4. O mesmo visual em Android e iOS. Não troque para widgets Cupertino no iPhone.

## Cores

Constantes de nível superior em `cores.dart`, no formato `Color(0xAARRGGBB)`. Use `aqua`, não `Cores.aqua`. Atenção: `textSecondary`, `textMuted` e `textHint` são `final` (calculados com `withValues`), então não podem ser usados dentro de `const`.

Paleta base:

| Token | Dart | Uso |
|---|---|---|
| `oceanDeep` | `Color(0xFF031B34)` | fundo; texto sobre o botão principal |
| `oceanBlue` | `Color(0xFF0A4D8C)` | meio do degradê de fundo |
| `oceanTeal` | `Color(0xFF0FA3B1)` | fim do degradê de fundo |
| `aqua` | `Color(0xFF4FF0E6)` | foco, links, rótulos de seção, cor primária do tema |
| `foam` | `Color(0xFFE6FBFF)` | base dos textos |
| `sunsetOrange` | `Color(0xFFFF7A3D)` | início do degradê do botão principal |
| `sunsetYellow` | `Color(0xFFFFC94A)` | fim do degradê do botão; números de destaque; alertas |
| `coral` | `Color(0xFFFF8A80)` | erros |

Degradês: `fundoOceano` (`componentes.dart`, vertical: oceanDeep 0% → oceanBlue 55% → oceanTeal 100%). O degradê do sol (sunsetOrange → sunsetYellow, horizontal) fica dentro do `BotaoPrincipal` e não é usado em outro lugar.

Superfícies de vidro (sem desfoque):

| Token | Dart | Uso |
|---|---|---|
| `glassField` | `Color(0x0DFFFFFF)` (branco 5%) | campo em repouso |
| `glassFieldFocused` | `Color(0x14FFFFFF)` (branco 8%) | campo com foco |
| `glassSurface` | `Color(0x1AFFFFFF)` (branco 10%) | cartões |
| `glassWhite` | `Color(0x26FFFFFF)` (branco 15%) | selos, botão voltar, barras vazias |
| `glassBorder` | `Color(0x40FFFFFF)` (branco 25%) | bordas |

Texto:

| Token | Dart | Uso |
|---|---|---|
| `textPrimary` | `Colors.white` | títulos, valores, texto digitado |
| `textSecondary` | `foam.withValues(alpha: 0.85)` | subtítulos, corpo |
| `textMuted` | `foam.withValues(alpha: 0.7)` | legendas, rótulos em repouso |
| `textHint` | `foam.withValues(alpha: 0.4)` | placeholders |

Qual cor usar:

| Preciso de… | Use |
|---|---|
| fundo de tela | `TelaBase` (já aplica `fundoOceano`) |
| agrupar conteúdo | `CartaoVidro` |
| foco ou seleção | `aqua` |
| número de destaque | `sunsetYellow` + `titleLarge` |
| erro | `coral`, via `Aviso` ou o erro do `CampoTexto` |
| alerta que não é erro | `sunsetYellow`, via `Aviso` |
| texto sobre o botão principal | `oceanDeep` |

**Atenção ao contraste.** Medido sobre um `CartaoVidro`, todo texto claro fica abaixo do mínimo WCAG AA (4,5) no trecho turquesa do fundo (`oceanTeal`); até o branco chega só a 2,7. Sobre `oceanBlue`, falham `textHint` (2,3) e `coral` (2,9), e `textMuted` (4,0) e `sunsetYellow` (4,4) só servem para texto grande. Por isso, não coloque texto no trecho turquesa do fundo e evite `textHint` em texto importante. O botão principal passa: `oceanDeep` sobre o degradê do sol dá entre 6,7 e 11,3.

## Tipografia

Use sempre `context.texto.<estilo>` (atalho para `Theme.of(context).textTheme`). A fonte é a padrão do sistema (Roboto no Android, San Francisco no iOS). Os tamanhos estão em pixels lógicos. O app aplica `DefaultTextHeightBehavior` sem espaço extra acima da primeira linha nem abaixo da última, como no Compose.

| Estilo | Tamanho / linha / peso | Uso |
|---|---|---|
| `displayLarge` | 52 / 58 / `w900`, `letterSpacing: -1` | marca "JetBoat" |
| `headlineLarge` | 30 / 36 / `w900` | título de tela |
| `titleLarge` | 20 / 26 / `w800` | números de destaque, título de diálogo |
| `titleMedium` | 17 / 22 / `w700` | título dentro de cartão |
| `bodyLarge` | 16 / 23 | subtítulo de tela, texto corrido |
| `bodyMedium` | 14 / 20 | apoio, links, avisos |
| `bodySmall` | 12 / 16 | legendas, mensagens de erro |
| `labelLarge` | 17 / 22 / `w800` | texto de botão |
| `labelMedium` | 12 / 16 / `w700`, `letterSpacing: 1.2` | rótulo de seção, em CAIXA ALTA via `texto.toUpperCase()` no `RotuloSecao` |
| `labelSmall` | 11 / 14 / `w500` | microtexto |

Combinações padrão:

| Elemento | Estilo | Cor |
|---|---|---|
| título de tela | `headlineLarge` | `textPrimary` |
| subtítulo de tela | `bodyLarge` | `textSecondary` |
| título em cartão | `titleMedium` | `textPrimary` |
| corpo | `bodyMedium` | `textSecondary` |
| legenda | `bodySmall` | `textMuted` |
| rótulo de seção | `labelMedium` | `aqua` |
| número de destaque | `titleLarge` | `sunsetYellow` |

## Espaçamento, formas e medidas

`Espacamento` (`static const double`, base de 4): `xs` 4 · `sm` 8 · `md` 12 · `lg` 16 · `xl` 24 (entre seções) · `xxl` 32 · `margemTela` 20 (margem lateral de toda tela) · `margemVerticalTela` 12 · `paddingCartao` 16.

`Formas` (`BorderRadius`): `campo` raio 14 (campos, avisos) · `botao` raio 18 · `cartao` raio 22 · `pilula` raio 999 (selos).

`Medidas`: `alturaBotao` 58 · `botaoIcone` 44 · `borda` 1 · `bordaDestaque` 1.5 (contorno do `BotaoSecundario`).

## Elevação

Não há sombras. A profundidade vem das camadas de vidro: fundo `fundoOceano` → campo `glassField` (5%) → campo com foco `glassFieldFocused` (8%) → cartão `glassSurface` (10%) → selo e botão voltar `glassWhite` (15%). Bordas de cartão e aviso são desenhadas com `foregroundDecoration`, para não empurrar o conteúdo.

## Iconografia

Não há biblioteca de ícones. Use os emojis já adotados (🚤 🛥️ 🔑 🌊 ⚓ 👋 🎉 💪 ★) e a seta desenhada do `BotaoVoltar`. Se precisar de um ícone novo, proponha, sem adotar uma biblioteca por conta própria.

## Movimento

Classe `Movimento`: `curva` (`Curves.fastOutSlowIn`) · `curta` 250ms (mudanças pequenas de estado) · `media` 600ms (entrada de bloco) · `escalonamento` 150ms (atraso entre blocos) · `transicaoTela` 700ms (troca de tela, fade cruzado) · loops da tela inicial: `brilhoBotao` 2600ms, `balancoBarco` 1800ms, `pulsoAura` 2200ms, `pulsoSol` 3000ms, `ondas` 4000ms.

## Widgets

- `TelaBase(children:, rolavel:, paddingVertical:)`: estrutura de toda tela (fundo, `SafeArea`, rolagem e margens).
- `BotaoPrincipal(texto:, onPressed:, carregando:)`: a ação principal; só um por tela.
- `BotaoSecundario(texto:, onPressed:)`: ação alternativa ("Já tenho conta", "Sair da conta").
- `BotaoVoltar(onPressed:)`: no topo, à esquerda.
- `CabecalhoTela(titulo:, subtitulo:, emoji:)`: topo da tela; `emoji` é opcional.
- `CartaoVidro(titulo:, children:)`: agrupa conteúdo; o `titulo` opcional vira rótulo de seção.
- `RotuloSecao(texto)`: título de seção em caixa alta, aqua.
- `Aviso(texto:, cor:)`: faixa de mensagem (erro com `coral`, alerta com `sunsetYellow`).
- `mostrarMensagem(context, texto)`: mensagem rápida (`SnackBar`), no lugar do Toast.
- `CampoTexto(controller:, rotulo:, erro:, onChanged:, teclado:, acao:, formatadores:, capitalizacao:, dica:, sufixo:, onSubmitted:, ocultar:, habilitado:)`: campo de formulário. Para CPF, data e telefone, passe `Mascara.cpf`, `Mascara.data` ou `Mascara.telefone` em `formatadores`.
- `CampoSenha(controller:, rotulo:, erro:, onChanged:, acao:, onSubmitted:, habilitado:)`: campo de senha com "Mostrar/Ocultar".

Todo elemento interativo recebe uma `ValueKey` de uma classe de chaves da tela (ex.: `TelaLoginChaves.entrar`), usada nos testes. Use construtores `const` sempre que possível. Antes de criar um widget novo, veja se algum da lista resolve. Se a mesma combinação aparecer em duas telas, sugira transformá-la em widget.

## Estrutura padrão de uma tela

A ordem, de cima para baixo, é: voltar → cabeçalho → cartões → ação principal → ação secundária (opcional).

```dart
TelaBase(
  children: [
    BotaoVoltar(onPressed: onVoltar),
    const SizedBox(height: Espacamento.xl),
    const CabecalhoTela(titulo: '...', subtitulo: '...'),
    const SizedBox(height: Espacamento.xl),
    CartaoVidro(
      titulo: 'Seção',
      children: [/* campos */],
    ),
    const SizedBox(height: Espacamento.xl),
    BotaoPrincipal(texto: '...', onPressed: () {}),
  ],
);
```

Para uma tela sem rolagem com a ação presa embaixo, use `TelaBase(rolavel: false, children: [..., const Spacer(), BotaoSecundario(...)])`.

Navegação: as rotas ficam em `Rotas` e são criadas em `_rota`, no `app.dart`. Toda tela usa a mesma transição (fade cruzado de `Movimento.transicaoTela`). As telas não chamam o `Navigator` direto: recebem callbacks (`onVoltar`, `onLoginConcluido`…) e o `app.dart` decide para onde ir.

## Arquitetura (C4)

O app segue o `docs/ARQUITETURA_C4.md`. Ao criar ou mudar código, respeite as regras de dependência, que o `test/arquitetura_test.dart` verifica:

1. Uma tela nova fica em `lib/ui/<tela>/` e importa só `lib/ui/theme/`, `lib/ui/components/` e `lib/domain/`. **Nunca `lib/data/`** nem outra tela.
2. Dados e ações chegam à tela pelo construtor: interfaces do domínio (ex.: `Autenticacao`) e callbacks. A tela não cria objetos de `data/`; quem cria é o `lib/dependencias.dart`.
3. `lib/ui/theme/` depende só do Flutter; `lib/ui/components/` só do Flutter e de `ui/theme/`. Um widget recebe textos, valores e callbacks prontos; não valida CPF nem chama serviço.
4. `lib/domain/` é Dart puro: sem `package:flutter`, sem `ui/` e sem `data/`.
5. Um widget usado por duas telas ou mais vai para `lib/ui/components/`; uma regra usada por duas telas ou mais vai para `lib/domain/`.
6. Imports internos sempre no formato `package:jetboat/...`.
7. Pasta nova em `lib/` exige atualizar o `ARQUITETURA_C4.md` e o `test/arquitetura_test.dart`.

## Android e iOS

- Barra de status com ícones claros: já aplicado no app inteiro, no `app.dart`.
- Conteúdo dentro de `SafeArea` (já incluída no `TelaBase`). Nunca use margem fixa no topo.
- O gesto de voltar do iOS **não funciona hoje**, por causa da transição própria. Mantenha o `BotaoVoltar` em toda tela e não conte com o gesto.
- Não use Toast, que não existe no iOS: use `mostrarMensagem`.
- Mantenha o efeito de rolagem padrão de cada plataforma.

## Exceções permitidas

Só estes casos podem usar valores próprios, por serem arte e não widgets:

- as ilustrações da tela inicial: ondas, brilho do sol, aura do logo, degradê da marca e tamanho dos emojis (com `CustomPainter` e animações);
- o cartão de categoria clicável, com um degradê de vidro um pouco mais claro;
- as barrinhas de força da senha (raio 3, altura 5, espaço 6).

## Ainda não definido

Os itens abaixo ainda não têm padrão. Quando um pedido meu envolver algum deles, avise e proponha uma solução, sem tratá-la como regra:

gesto de voltar do iOS · estados desabilitado e pressionado dos botões · área de toque de 48 no `BotaoVoltar` · revisão das telas com fonte grande do sistema · tela de abertura e ícone do iOS · `SnackBar` com estilo de vidro · fonte da marca, para o app ficar igual nas duas plataformas · widget de link (hoje varia entre aqua, amarelo e `textSecondary`) · cores de sucesso e informação · diálogo padrão · checkbox, switch e outros controles · espaçamentos fora da base de 4 (2, 6, 10, 14, 18) · cores agrupadas em uma classe · desfoque no vidro (`BackdropFilter`) · sombras · tema claro · biblioteca de ícones · logo e ícone do app · tablet, iPad e celular deitado · tradução com arquivos `.arb`.

## Ao entregar código

1. Confira, e diga que conferiu: nenhum valor escrito à mão fora de `lib/ui/theme/` e das exceções; as regras da seção "Arquitetura (C4)"; a tela usa `TelaBase`; conteúdo em `CartaoVidro`; no máximo um `BotaoPrincipal`; estilos e cores das combinações padrão; nenhum texto sobre o trecho turquesa do fundo; chaves de teste nos elementos interativos.
2. Aponte qualquer comportamento que possa ser diferente entre Android e iOS e diga como testar.
3. Use Dart com null safety e código que passe no `flutter analyze` sem avisos e no `flutter test`. Use `withValues(alpha:)` em vez de `withOpacity`, que está obsoleto.
4. Liste qualquer token ou widget novo que você precisou propor.
5. Escreva os textos da interface em português do Brasil.

---

**Meu pedido:** [descreva aqui a tela ou a alteração]
