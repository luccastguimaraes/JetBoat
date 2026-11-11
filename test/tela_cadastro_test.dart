import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jetboat/data/usuario.dart';
import 'package:jetboat/domain/conta/perfil.dart';
import 'package:jetboat/data/repositorio_usuarios_arquivo.dart';
import 'package:jetboat/data/auth/armazenamento_seguro.dart';
import 'package:jetboat/data/auth/assinador.dart';
import 'package:jetboat/data/auth/autenticacao_local.dart';
import 'package:jetboat/data/auth/jwt.dart';
import 'package:jetboat/data/auth/sessao_armazenamento.dart';
import 'package:jetboat/ui/cadastro/tela_cadastro.dart';

import 'util.dart';

typedef K = TelaCadastroChaves;

void main() {
  late Directory pasta;
  late RepositorioUsuariosArquivo repositorio;
  late AutenticacaoLocal auth;
  late SessaoArmazenamento sessao;
  late int voltou;
  Perfil? concluido;

  setUp(() {
    pasta = Directory.systemTemp.createTempSync('jetboat_cadastro_');
    repositorio = RepositorioUsuariosArquivo(File('${pasta.path}/usuarios.json'));
    sessao = SessaoArmazenamento(ArmazenamentoEmMemoria());
    auth = AutenticacaoLocal(usuarios: repositorio, jwt: Jwt(AssinadorHmac(List.filled(32, 3))), armazenamento: sessao);
    voltou = 0;
    concluido = null;
  });

  tearDown(() => pasta.deleteSync(recursive: true));

  Future<void> abrir(WidgetTester tester) async {
    usarTelaDeCelular(tester);
    await tester.pumpWidget(comTema(TelaCadastro(
      autenticacao: auth,
      onVoltar: () => voltou++,
      onCadastroConcluido: (u) => concluido = u,
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

  Future<List<Usuario>> salvos(WidgetTester tester) async => (await tester.runAsync(repositorio.listar))!;

  testWidgets('botão voltar chama o callback', (tester) async {
    await abrir(tester);
    await tocar(tester, find.byKey(K.voltar));
    expect(voltou, 1);
  });

  testWidgets('cadastrar vazio mostra erros e não salva', (tester) async {
    await abrir(tester);
    await tocar(tester, find.byKey(K.cadastrar));
    expect(find.text('Informe seu nome completo'), findsOneWidget);
    expect(find.text('Informe seu CPF'), findsOneWidget);
    expect(find.text('Aceite os termos para continuar'), findsOneWidget);
    expect(await salvos(tester), isEmpty);
  });

  testWidgets('CPF inválido mostra erro', (tester) async {
    await abrir(tester);
    await preencherFormularioValido(tester, cpf: '12345678900');
    await tocar(tester, find.byKey(K.cadastrar));
    expect(find.text('CPF inválido'), findsOneWidget);
    expect(await salvos(tester), isEmpty);
  });

  testWidgets('cadastro válido salva e mostra confirmação', (tester) async {
    await abrir(tester);
    await preencherFormularioValido(tester);
    await tocar(tester, find.byKey(K.cadastrar));

    await esperarAte(tester, () => find.text('Conta criada! 🎉').evaluate().isNotEmpty);
    await tocar(tester, find.text('Continuar'));

    expect(concluido, isNotNull);
    expect(await tester.runAsync(() => sessao.tokenAcesso), isNotNull); // quem se cadastra já entra logado
    final lista = await salvos(tester);
    expect(lista, hasLength(1));
    expect(lista[0].cpf, '52998224725');
    expect(lista[0].dataNascimento, '15/03/1990');
  });

  testWidgets('CPF já cadastrado mostra erro', (tester) async {
    await tester.runAsync(() => repositorio.cadastrar(
          nome: 'João Souza',
          cpf: '52998224725',
          dataNascimento: '01/01/1980',
          telefone: '11912345678',
          email: 'joao@email.com',
          senha: 'Barco2026',
        ));
    await abrir(tester);
    await preencherFormularioValido(tester);
    await tocar(tester, find.byKey(K.cadastrar));
    await esperarAte(tester, () => find.text('CPF já cadastrado').evaluate().isNotEmpty);
    expect(await salvos(tester), hasLength(1));
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

  testWidgets('e-mail já cadastrado mostra erro (sem diferenciar maiúsculas)', (tester) async {
    await tester.runAsync(() => repositorio.cadastrar(
          nome: 'João Souza',
          cpf: '11144477735',
          dataNascimento: '01/01/1980',
          telefone: '11912345678',
          email: 'MARIA@email.com',
          senha: 'Barco2026',
        ));
    await abrir(tester);
    await preencherFormularioValido(tester); // CPF diferente, e-mail maria@email.com
    await tocar(tester, find.byKey(K.cadastrar));
    await esperarAte(tester, () => find.text('E-mail já cadastrado').evaluate().isNotEmpty);
    expect(concluido, isNull);
    expect(await salvos(tester), hasLength(1));
  });
}
