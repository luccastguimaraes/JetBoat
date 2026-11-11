import 'package:flutter/animation.dart';

/// Durações e curvas das animações do JetBoat.
abstract final class Movimento {
  /// Curva padrão: acelera rápido e desacelera no fim (FastOutSlowIn do Material).
  static const curva = Curves.fastOutSlowIn;

  // ── Interface ────────────────────────────────────────────────────────
  /// Mudanças pequenas de estado (cor de barra, aparecer um aviso).
  static const curta = Duration(milliseconds: 250);

  /// Entrada de um bloco de conteúdo.
  static const media = Duration(milliseconds: 600);

  /// Atraso entre blocos que entram em sequência.
  static const escalonamento = Duration(milliseconds: 150);

  /// Troca de tela (fade cruzado, igual ao padrão do Navigation Compose).
  static const transicaoTela = Duration(milliseconds: 700);

  // ── Ambiente (loops contínuos das ilustrações) ───────────────────────
  static const brilhoBotao = Duration(milliseconds: 2600); // linear
  static const balancoBarco = Duration(milliseconds: 1800); // vai e volta
  static const pulsoAura = Duration(milliseconds: 2200); // vai e volta
  static const pulsoSol = Duration(milliseconds: 3000); // vai e volta
  static const ondas = Duration(milliseconds: 4000); // linear
}
