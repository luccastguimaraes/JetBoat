import 'package:flutter/material.dart';

import 'package:jetboat/ui/theme/cores.dart';

/// Escala tipográfica do JetBoat. Use sempre via `Theme.of(context).textTheme.<estilo>`.
///
/// | Estilo         | Uso                                   |
/// |----------------|---------------------------------------|
/// | displayLarge   | marca "JetBoat" na tela inicial       |
/// | headlineLarge  | título de tela                        |
/// | titleLarge     | números de destaque                   |
/// | titleMedium    | nome/valor em cartões, título de card |
/// | bodyLarge      | subtítulo de tela, texto corrido      |
/// | bodyMedium     | textos de apoio, links, avisos        |
/// | bodySmall      | legendas, mensagens de campo          |
/// | labelLarge     | texto de botão                        |
/// | labelMedium    | rótulo de seção (CAIXA ALTA)          |
/// | labelSmall     | microtexto (selos, subtítulo de card) |
TextStyle _estilo(double tamanho, double alturaLinha, FontWeight peso, {double espacamento = 0}) => TextStyle(
      // A DEFINIR: fonte da marca (hoje, a padrão do sistema)
      fontSize: tamanho,
      height: alturaLinha / tamanho,
      fontWeight: peso,
      letterSpacing: espacamento,
    );

final tipografia = TextTheme(
  displayLarge: _estilo(52, 58, FontWeight.w900, espacamento: -1),
  headlineLarge: _estilo(30, 36, FontWeight.w900),
  titleLarge: _estilo(20, 26, FontWeight.w800),
  titleMedium: _estilo(17, 22, FontWeight.w700),
  bodyLarge: _estilo(16, 23, FontWeight.w400),
  bodyMedium: _estilo(14, 20, FontWeight.w400),
  bodySmall: _estilo(12, 16, FontWeight.w400),
  labelLarge: _estilo(17, 22, FontWeight.w800),
  labelMedium: _estilo(12, 16, FontWeight.w700, espacamento: 1.2),
  labelSmall: _estilo(11, 14, FontWeight.w500),
);

/// O JetBoat tem identidade sempre escura (fundo oceano), independente do modo do sistema.
/// A DEFINIR: se haverá um tema claro.
final temaJetBoat = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: oceanDeep,
  colorScheme: ColorScheme.dark(
    primary: aqua,
    onPrimary: oceanDeep,
    secondary: sunsetOrange,
    onSecondary: oceanDeep,
    tertiary: sunsetYellow,
    onTertiary: oceanDeep,
    surface: oceanDeep,
    onSurface: foam,
    surfaceContainerHighest: oceanBlue,
    onSurfaceVariant: textMuted,
    outline: glassBorder,
    error: coral,
    onError: oceanDeep,
  ),
  textTheme: tipografia.apply(bodyColor: foam, displayColor: foam),
);
