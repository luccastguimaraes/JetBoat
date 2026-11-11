import 'package:flutter/widgets.dart';

/// Espaçamentos estruturais (base de 4dp).
abstract final class Espacamento {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Margem lateral de todas as telas.
  static const double margemTela = 20;

  /// Respiro vertical no topo/rodapé das telas.
  static const double margemVerticalTela = 12;

  /// Padding interno dos cartões de vidro.
  static const double paddingCartao = 16;
}

/// Raios de canto.
abstract final class Formas {
  static const campo = BorderRadius.all(Radius.circular(14)); // campos de texto, avisos
  static const botao = BorderRadius.all(Radius.circular(18)); // botões principal e secundário
  static const cartao = BorderRadius.all(Radius.circular(22)); // cartões de vidro
  static const pilula = BorderRadius.all(Radius.circular(999)); // selos, botão voltar
}

/// Medidas fixas de componentes.
abstract final class Medidas {
  static const double alturaBotao = 58;
  static const double botaoIcone = 44; // área de toque mínima: 44–48dp
  static const double borda = 1;
  static const double bordaDestaque = 1.5;
}
