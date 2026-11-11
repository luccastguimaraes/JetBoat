import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jetboat/domain/conta/autenticacao.dart';
import 'package:jetboat/ui/cadastro/tela_cadastro.dart';

import 'autenticacao_falsa.dart';
import 'util.dart';

typedef K = TelaCadastroChaves;

void main() {
  late AutenticacaoFalsa auth;
  late int voltou;
  Perfil? concluido;

  setUp(() {
    auth = AutenticacaoFalsa();
    voltou = 0;
    concluido = null;
  });

  Future<void> abrir(WidgetTester tester) async {
    usarTelaDeCelular(tester);
    await tester.pumpWidget(comTema(TelaCadastro(
      autenticacao: auth,
      onVoltar: () => voltou++,
      onCadastroConcluido: (p) => concluido = p,
    )));
  }

  Future<void> preencherFormularioValido(WidgetTester tester, {String cpf = '52998224725'}) async {
    await digitar(tester, K.nome, 'Maria da Silva');
    await digitar(tester, K.cpf, cpf);
    await digitar(tester, K.data, '15031990');
    await digitar(tester, K.telefone, '11987654321');
    await digitar(tester, K.email, 'maria@email.com');
    await digitar(tester, K.senha, 'Barco2026');
    await digitar(tester, K.confirmarSenha, 'Barco2026');
    await tocar(tester, find.byKey(K.termos));
  }

  testWidgets('botão voltar chama o callback', (tester) async {
    await abrir(tester);
    await tocar(tester, find.byKey(K.voltar));
    expect(voltou, 1);
  });

  testWidgets('cadastrar vazio mostra erros e não chama o serviço', (tester) async {
    await abrir(tester);
    await tocar(tester, find.byKey(K.cadastrar));
    expect(find.text('Informe seu nome completo'), findsOneWidget);
    expect(find.text('Informe seu CPF'), findsOneWidget);
    expect(find.text('Aceite os termos para continuar'), findsOneWidget);
    expect(auth.chamadasCadastrar, 0);
  });

  testWidgets('CPF inválido mostra erro e não chama o serviço', (tester) async {
    await abrir(tester);
    await preencherFormularioValido(tester, cpf: '12345678900');
    await tocar(tester, find.byKey(K.cadastrar));
    expect(find.text('CPF inválido'), findsOneWidget);
    expect(auth.chamadasCadastrar, 0);
  });

  testWidgets('cadastro válido envia os dados certos e mostra a confirmação', (tester) async {
    await abrir(tester);
    await preencherFormularioValido(tester);
    await tocar(tester, find.byKey(K.cadastrar));

    await esperarAte(tester, () => find.text('Conta criada! 🎉').evaluate().isNotEmpty);
    expect(find.textContaining('Bem-vindo(a) a bordo, Maria!'), findsOneWidget);
    await tocar(tester, find.text('Continuar'));

    expect(concluido?.nome, 'Maria da Silva');
    // A tela envia só dígitos no CPF e no telefone, e a data no formato dd/MM/aaaa
    final enviado = auth.ultimoCadastro!;
    expect(enviado.cpf, '52998224725');
    expect(enviado.telefone, '11987654321');
    expect(enviado.dataNascimento, '15/03/1990');
    expect(enviado.email, 'maria@email.com');
  });

  testWidgets('CPF já cadastrado mostra erro no campo CPF', (tester) async {
    auth.respostaCadastro = const CpfJaCadastrado();
    await abrir(tester);
    await preencherFormularioValido(tester);
    await tocar(tester, find.byKey(K.cadastrar));
    await esperarAte(tester, () => find.text('CPF já cadastrado').evaluate().isNotEmpty);
    expect(concluido, isNull);
  });

  testWidgets('e-mail já cadastrado mostra erro no campo e-mail', (tester) async {
    auth.respostaCadastro = const EmailJaCadastrado();
    await abrir(tester);
    await preencherFormularioValido(tester);
    await tocar(tester, find.byKey(K.cadastrar));
    await esperarAte(tester, () => find.text('E-mail já cadastrado').evaluate().isNotEmpty);
    expect(concluido, isNull);
  });

  testWidgets('"próximo" do teclado na senha vai para Confirmar senha (não para o botão Mostrar)', (tester) async {
    await abrir(tester);
    await digitar(tester, K.senha, 'Barco2026');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    final confirmar = tester.widget<EditableText>(
      find.descendant(of: find.byKey(K.confirmarSenha), matching: find.byType(EditableText)),
    );
    expect(confirmar.focusNode.hasFocus, isTrue);
  });
}
