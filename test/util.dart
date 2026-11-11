import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jetboat/ui/theme/tema.dart';

/// Simula a tela de um celular (1080x2400, densidade 2.625 ≈ 411x914dp).
void usarTelaDeCelular(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

Widget comTema(Widget tela) => MaterialApp(theme: temaJetBoat, home: tela);

/// Deixa trabalho assíncrono real (arquivo, isolate de hash) acontecer até [condicao] ser verdadeira.
/// As telas têm animações infinitas, então não dá para usar `pumpAndSettle`.
Future<void> esperarAte(WidgetTester tester, bool Function() condicao, {Duration limite = const Duration(seconds: 10)}) async {
  final fim = DateTime.now().add(limite);
  while (!condicao()) {
    if (DateTime.now().isAfter(fim)) throw TestFailure('Condição não atingida em $limite');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.pump();
  await tester.tap(alvo);
  await tester.pump();
}

Future<void> digitar(WidgetTester tester, Key chave, String texto) async {
  final campo = find.byKey(chave);
  await tester.ensureVisible(campo);
  await tester.enterText(campo, texto);
  await tester.pump();
}
