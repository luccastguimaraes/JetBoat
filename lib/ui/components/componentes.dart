import 'package:flutter/material.dart';

import 'package:jetboat/ui/theme/cores.dart';
import 'package:jetboat/ui/theme/dimens.dart';
import 'package:jetboat/ui/theme/movimento.dart';

/// Degradê de fundo padrão das telas do JetBoat.
const fundoOceano = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [oceanDeep, oceanBlue, oceanTeal],
  stops: [0, 0.55, 1],
);

/// Atalho para os estilos de texto do tema.
extension EstilosTexto on BuildContext {
  TextTheme get texto => Theme.of(this).textTheme;
}

/// Botão principal (CTA) com gradiente "pôr do sol" e um brilho que percorre o botão.
class BotaoPrincipal extends StatefulWidget {
  const BotaoPrincipal({super.key, required this.texto, required this.onPressed, this.carregando = false});

  final String texto;
  final VoidCallback onPressed;
  final bool carregando;

  @override
  State<BotaoPrincipal> createState() => _BotaoPrincipalState();
}

class _BotaoPrincipalState extends State<BotaoPrincipal> with SingleTickerProviderStateMixin {
  late final _brilho = AnimationController(vsync: this, duration: Movimento.brilhoBotao)..repeat();

  @override
  void dispose() {
    _brilho.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !widget.carregando,
      child: ClipRRect(
        borderRadius: Formas.botao,
        child: SizedBox(
          height: Medidas.alturaBotao,
          width: double.infinity,
          child: DecoratedBox(
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [sunsetOrange, sunsetYellow])),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: widget.carregando ? null : widget.onPressed,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _brilho,
                        builder: (context, _) => CustomPaint(
                          painter: _PintorBrilho(
                            progresso: -1 + 3 * _brilho.value,
                            larguraFaixa: 120 / MediaQuery.devicePixelRatioOf(context),
                          ),
                        ),
                      ),
                    ),
                    if (widget.carregando)
                      const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(color: oceanDeep, strokeWidth: 3),
                      )
                    else
                      Text(widget.texto, style: context.texto.labelLarge?.copyWith(color: oceanDeep)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PintorBrilho extends CustomPainter {
  _PintorBrilho({required this.progresso, required this.larguraFaixa});

  final double progresso;
  final double larguraFaixa;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * progresso;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.transparent, Colors.white.withValues(alpha: 0.45), Colors.transparent],
      ).createShader(Rect.fromPoints(Offset(x - larguraFaixa, 0), Offset(x + larguraFaixa, size.height)));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_PintorBrilho antigo) => antigo.progresso != progresso;
}

/// Botão secundário: contorno claro, mesma altura e forma do principal.
class BotaoSecundario extends StatelessWidget {
  const BotaoSecundario({super.key, required this.texto, required this.onPressed});

  final String texto;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(Medidas.alturaBotao),
        shape: const RoundedRectangleBorder(borderRadius: Formas.botao),
        side: BorderSide(width: Medidas.bordaDestaque, color: foam.withValues(alpha: 0.6)),
        foregroundColor: foam,
      ),
      child: Text(texto, style: context.texto.labelLarge?.copyWith(color: foam)),
    );
  }
}

/// Botão circular de vidro com seta para voltar (desenhada, sem depender de biblioteca de ícones).
class BotaoVoltar extends StatelessWidget {
  const BotaoVoltar({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Voltar',
      excludeSemantics: true,
      child: Material(
        color: glassWhite,
        shape: const CircleBorder(side: BorderSide(color: glassBorder, width: Medidas.borda)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: const SizedBox.square(
            dimension: Medidas.botaoIcone,
            child: Center(child: CustomPaint(size: Size.square(18), painter: _PintorSeta())),
          ),
        ),
      ),
    );
  }
}

class _PintorSeta extends CustomPainter {
  const _PintorSeta();

  @override
  void paint(Canvas canvas, Size size) {
    final traco = Paint()
      ..color = foam
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final meioY = size.height / 2;
    final ponta = Offset(size.width * 0.1, meioY);
    canvas.drawLine(Offset(size.width * 0.9, meioY), ponta, traco);
    canvas.drawLine(ponta, Offset(size.width * 0.45, size.height * 0.15), traco);
    canvas.drawLine(ponta, Offset(size.width * 0.45, size.height * 0.85), traco);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Título + subtítulo padrão do topo das telas (com emoji opcional acima).
class CabecalhoTela extends StatelessWidget {
  const CabecalhoTela({super.key, required this.titulo, required this.subtitulo, this.emoji});

  final String titulo;
  final String subtitulo;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final t = context.texto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (emoji != null) ...[
          Text(emoji!, style: TextStyle(fontSize: t.displayLarge!.fontSize! * 0.85)),
          const SizedBox(height: Espacamento.sm),
        ],
        Text(titulo, style: t.headlineLarge?.copyWith(color: textPrimary)),
        const SizedBox(height: 6),
        Text(subtitulo, style: t.bodyLarge?.copyWith(color: textSecondary)),
      ],
    );
  }
}

/// Rótulo de seção em caixa alta, cor aqua.
class RotuloSecao extends StatelessWidget {
  const RotuloSecao(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) =>
      Text(texto.toUpperCase(), style: context.texto.labelMedium?.copyWith(color: aqua));
}

/// Cartão de vidro: superfície translúcida com borda, para agrupar conteúdo.
class CartaoVidro extends StatelessWidget {
  const CartaoVidro({super.key, this.titulo, required this.children});

  final String? titulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Espacamento.paddingCartao),
      decoration: const BoxDecoration(color: glassSurface, borderRadius: Formas.cartao),
      // Borda desenhada por cima: não empurra o conteúdo para dentro (como no Compose)
      foregroundDecoration: BoxDecoration(
        borderRadius: Formas.cartao,
        border: Border.all(color: glassBorder, width: Medidas.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Espacamento.xs,
        children: [
          if (titulo != null)
            Padding(padding: const EdgeInsets.only(bottom: Espacamento.xs), child: RotuloSecao(titulo!)),
          ...children,
        ],
      ),
    );
  }
}

/// Faixa de aviso colorida (erro, alerta, info), com fundo e borda na mesma cor.
class Aviso extends StatelessWidget {
  const Aviso({super.key, required this.texto, required this.cor});

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: Espacamento.md),
      decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), borderRadius: Formas.campo),
      foregroundDecoration: BoxDecoration(
        borderRadius: Formas.campo,
        border: Border.all(color: cor.withValues(alpha: 0.5), width: Medidas.borda),
      ),
      child: Text(texto, style: context.texto.bodyMedium?.copyWith(color: cor)),
    );
  }
}

/// Estrutura padrão de tela: fundo oceano, margens, rolagem e respeito às barras do sistema/teclado.
class TelaBase extends StatelessWidget {
  const TelaBase({super.key, required this.children, this.rolavel = true, this.paddingVertical});

  final List<Widget> children;
  final bool rolavel;
  final double? paddingVertical;

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.symmetric(
      horizontal: Espacamento.margemTela,
      vertical: paddingVertical ?? Espacamento.margemVerticalTela,
    );
    final coluna = Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
    return Scaffold(
      backgroundColor: oceanDeep,
      // O degradê ocupa a tela inteira, mesmo quando o conteúdo é mais curto
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(gradient: fundoOceano),
        child: SafeArea(
          child: rolavel
              ? SingleChildScrollView(padding: padding, child: coluna)
              : Padding(padding: padding, child: coluna),
        ),
      ),
    );
  }
}

/// Mensagem curta na parte de baixo da tela (equivalente ao Toast do Android).
void mostrarMensagem(BuildContext context, String texto) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto), duration: const Duration(seconds: 2)));
}
