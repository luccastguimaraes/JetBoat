import 'dart:math';

import 'package:flutter/material.dart';

import 'package:jetboat/ui/components/componentes.dart';
import 'package:jetboat/ui/theme/cores.dart';
import 'package:jetboat/ui/theme/dimens.dart';
import 'package:jetboat/ui/theme/movimento.dart';

/// Chaves usadas nos testes de UI.
abstract final class TelaInicialChaves {
  static const titulo = ValueKey('titulo_jetboat');
  static const botaoComecar = ValueKey('botao_comecar');
  static const botaoEntrar = ValueKey('botao_entrar');
  static ValueKey<String> categoria(String titulo) => ValueKey('categoria_$titulo');
}

typedef _Categoria = ({String emoji, String titulo, String subtitulo});

const List<_Categoria> _categorias = [
  (emoji: '🚤', titulo: 'Jetski', subtitulo: 'a partir de\nR\$ 250/h'),
  (emoji: '🛥️', titulo: 'Lancha', subtitulo: 'a partir de\nR\$ 900/h'),
  (emoji: '🔑', titulo: 'Cotas', subtitulo: 'seja sócio\nde um barco'),
];

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key, this.onComecar, this.onEntrar, this.onCategoria});

  final VoidCallback? onComecar;
  final VoidCallback? onEntrar;
  final ValueChanged<String>? onCategoria;

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> with SingleTickerProviderStateMixin {
  // Animação de entrada: cada bloco aparece um "escalonamento" depois do anterior.
  static final _duracaoItem = Movimento.media.inMilliseconds;
  static final _ultimoAtraso = Movimento.escalonamento.inMilliseconds * 5; // 6 blocos
  late final _entrada = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _ultimoAtraso + _duracaoItem),
  )..forward();

  @override
  void dispose() {
    _entrada.dispose();
    super.dispose();
  }

  /// [ordem]: posição do bloco na sequência (0 = primeiro).
  Widget _entrar(int ordem, Widget filho) {
    assert(ordem >= 0 && ordem <= 5, "a tela inicial tem 6 blocos (ordem de 0 a 5)");
    final atrasoMs = ordem * Movimento.escalonamento.inMilliseconds;
    final total = _ultimoAtraso + _duracaoItem;
    final curva = CurvedAnimation(
      parent: _entrada,
      curve: Interval(atrasoMs / total, (atrasoMs + _duracaoItem) / total, curve: Movimento.curva),
    );
    return FadeTransition(
      opacity: curva,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 1 / 3), end: Offset.zero).animate(curva),
        child: filho,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.texto;
    return Scaffold(
      backgroundColor: oceanDeep,
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(gradient: fundoOceano),
        child: Stack(
          children: [
            const Positioned(top: -50, right: -70, child: _BrilhoDoSol()),
            const Positioned(left: 0, right: 0, bottom: 0, height: 170, child: _OndasAnimadas()),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: Espacamento.margemTela, vertical: Espacamento.lg),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _entrar(0, const _SeloTemporada()),
                    const SizedBox(height: 28),
                    _entrar(1, const _LogoFlutuante()),
                    const SizedBox(height: 20),
                    _entrar(
                      2,
                      Column(
                        children: [
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (r) => const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [foam, aqua, sunsetYellow],
                            ).createShader(r),
                            child: Text('JetBoat', key: TelaInicialChaves.titulo, style: t.displayLarge),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aluguel e cotas de jetski e lanchas.\nO mar inteiro ao seu alcance.',
                            style: t.bodyLarge?.copyWith(color: textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _entrar(
                      3,
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 12,
                          children: [
                            for (final c in _categorias)
                              Expanded(
                                child: _CartaoCategoria(categoria: c, onTap: () => widget.onCategoria?.call(c.titulo)),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _entrar(4, const _LinhaDeNumeros()),
                    const SizedBox(height: 36),
                    _entrar(
                      5,
                      Column(
                        children: [
                          BotaoPrincipal(
                            key: TelaInicialChaves.botaoComecar,
                            texto: 'Começar a navegar  🌊',
                            onPressed: () => widget.onComecar?.call(),
                          ),
                          const SizedBox(height: 12),
                          BotaoSecundario(
                            key: TelaInicialChaves.botaoEntrar,
                            texto: 'Já tenho conta',
                            onPressed: () => widget.onEntrar?.call(),
                          ),
                        ],
                      ),
                    ),
                    // Espaço para as ondas não cobrirem os botões
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeloTemporada extends StatelessWidget {
  const _SeloTemporada();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: glassWhite,
        borderRadius: Formas.pilula,
        border: Border.all(color: glassBorder, width: Medidas.borda),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: aqua, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Temporada de verão aberta',
              style: context.texto.bodyMedium?.copyWith(color: foam, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoFlutuante extends StatefulWidget {
  const _LogoFlutuante();

  @override
  State<_LogoFlutuante> createState() => _LogoFlutuanteState();
}

class _LogoFlutuanteState extends State<_LogoFlutuante> with TickerProviderStateMixin {
  late final _balanco = AnimationController(vsync: this, duration: Movimento.balancoBarco)
    ..repeat(reverse: true);
  late final _pulso = AnimationController(vsync: this, duration: Movimento.pulsoAura)
    ..repeat(reverse: true);

  @override
  void dispose() {
    _balanco.dispose();
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balanco = Tween(begin: -6.0, end: 6.0).animate(CurvedAnimation(parent: _balanco, curve: Movimento.curva));
    final pulso = Tween(begin: 0.9, end: 1.15).animate(CurvedAnimation(parent: _pulso, curve: Movimento.curva));
    return SizedBox.square(
      dimension: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Aura pulsante
          ScaleTransition(
            scale: pulso,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [aqua.withValues(alpha: 0.45), Colors.transparent]),
              ),
            ),
          ),
          // Círculo de vidro
          Container(
            width: 104,
            height: 104,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [glassWhite, glassField],
              ),
              border: Border.all(color: glassBorder, width: Medidas.bordaDestaque),
            ),
            child: AnimatedBuilder(
              animation: balanco,
              builder: (context, filho) => Transform.translate(
                offset: Offset(0, balanco.value),
                child: Transform.rotate(angle: balanco.value * 0.8 * pi / 180, child: filho),
              ),
              child: const Text('🚤', style: TextStyle(fontSize: 54)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoCategoria extends StatelessWidget {
  const _CartaoCategoria({required this.categoria, required this.onTap});

  final _Categoria categoria;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.texto;
    // Variante clicável do cartão de vidro: degradê um pouco mais claro para parecer "elevado".
    return Material(
      key: TelaInicialChaves.categoria(categoria.titulo),
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: Formas.cartao,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x33FFFFFF), Color(0x14FFFFFF)],
          ),
          border: Border.all(color: glassBorder, width: Medidas.borda),
        ),
        child: InkWell(
          borderRadius: Formas.cartao,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            child: Column(
              children: [
                Text(categoria.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(categoria.titulo, style: t.titleMedium?.copyWith(color: textPrimary)),
                const SizedBox(height: 2),
                Text(
                  categoria.subtitulo,
                  style: t.labelSmall?.copyWith(color: textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LinhaDeNumeros extends StatelessWidget {
  const _LinhaDeNumeros();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: glassSurface,
        borderRadius: Formas.cartao,
        border: Border.all(color: glassBorder, width: Medidas.borda),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Numero('+120', 'embarcações'),
          _Numero('4.9 ★', 'avaliação'),
          _Numero('24h', 'suporte'),
        ],
      ),
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero(this.valor, this.legenda);

  final String valor;
  final String legenda;

  @override
  Widget build(BuildContext context) {
    final t = context.texto;
    return Column(
      children: [
        Text(valor, style: t.titleLarge?.copyWith(color: sunsetYellow)),
        Text(legenda, style: t.bodySmall?.copyWith(color: textMuted)),
      ],
    );
  }
}

class _BrilhoDoSol extends StatefulWidget {
  const _BrilhoDoSol();

  @override
  State<_BrilhoDoSol> createState() => _BrilhoDoSolState();
}

class _BrilhoDoSolState extends State<_BrilhoDoSol> with SingleTickerProviderStateMixin {
  late final _escala = AnimationController(vsync: this, duration: Movimento.pulsoSol)
    ..repeat(reverse: true);

  @override
  void dispose() {
    _escala.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ScaleTransition(
        scale: Tween(begin: 0.95, end: 1.08).animate(CurvedAnimation(parent: _escala, curve: Movimento.curva)),
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              sunsetYellow.withValues(alpha: 0.55),
              sunsetOrange.withValues(alpha: 0.18),
              Colors.transparent,
            ]),
          ),
        ),
      ),
    );
  }
}

/// Três camadas de ondas senoidais deslizando em velocidades diferentes.
class _OndasAnimadas extends StatefulWidget {
  const _OndasAnimadas();

  @override
  State<_OndasAnimadas> createState() => _OndasAnimadasState();
}

class _OndasAnimadasState extends State<_OndasAnimadas> with SingleTickerProviderStateMixin {
  late final _fase = AnimationController(vsync: this, duration: Movimento.ondas)..repeat();

  @override
  void dispose() {
    _fase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _fase,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _PintorOndas(_fase.value * 2 * pi, MediaQuery.devicePixelRatioOf(context)),
        ),
      ),
    );
  }
}

class _PintorOndas extends CustomPainter {
  _PintorOndas(this.fase, this.densidade);

  final double fase;
  final double densidade;

  @override
  void paint(Canvas canvas, Size size) {
    void onda(double alturaBase, double amplitude, double frequencia, double deslocamento, List<Color> cores) {
      final path = Path()..moveTo(0, size.height);
      final passo = 6 / densidade;
      for (var x = 0.0; x <= size.width; x += passo) {
        path.lineTo(x, alturaBase + amplitude / densidade * sin((x / size.width) * 2 * pi * frequencia + deslocamento));
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      final rect = Offset.zero & size;
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: cores)
              .createShader(rect),
      );
    }

    final h = size.height;
    onda(h * 0.30, 18, 1.2, fase, [aqua.withValues(alpha: 0.25), oceanTeal.withValues(alpha: 0.2)]);
    onda(h * 0.45, 22, 1.6, -fase * 1.5, [oceanTeal.withValues(alpha: 0.5), oceanBlue.withValues(alpha: 0.6)]);
    onda(h * 0.62, 14, 2, fase * 2, [oceanBlue.withValues(alpha: 0.85), oceanDeep]);
  }

  @override
  bool shouldRepaint(_PintorOndas antigo) => antigo.fase != fase;
}
