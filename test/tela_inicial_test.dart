import 'package:flutter_test/flutter_test.dart';
import 'package:jetboat/ui/home/tela_inicial.dart';

import 'util.dart';

void main() {
  testWidgets('exibe título e categorias', (tester) async {
    usarTelaDeCelular(tester);
    await tester.pumpWidget(comTema(const TelaInicial()));
    await tester.pump(const Duration(seconds: 2)); // fim da animação de entrada

    expect(find.byKey(TelaInicialChaves.titulo), findsOneWidget);
    expect(find.text('Jetski'), findsOneWidget);
    expect(find.text('Lancha'), findsOneWidget);
    expect(find.text('Cotas'), findsOneWidget);
  });

  testWidgets('botões disparam callbacks', (tester) async {
    usarTelaDeCelular(tester);
    var comecar = 0;
    var entrar = 0;
    var categoria = '';
    await tester.pumpWidget(comTema(TelaInicial(
      onComecar: () => comecar++,
      onEntrar: () => entrar++,
      onCategoria: (c) => categoria = c,
    )));
    await tester.pump(const Duration(seconds: 2));

    await tocar(tester, find.byKey(TelaInicialChaves.botaoComecar));
    await tocar(tester, find.byKey(TelaInicialChaves.botaoEntrar));
    await tocar(tester, find.byKey(TelaInicialChaves.categoria('Lancha')));

    expect(comecar, 1);
    expect(entrar, 1);
    expect(categoria, 'Lancha');
  });
}
