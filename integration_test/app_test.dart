import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jetboat/app.dart';
import 'package:jetboat/data/auth/armazenamento_seguro.dart';
import 'package:jetboat/data/auth/assinador.dart';
import 'package:jetboat/data/auth/jwt.dart';
import 'package:jetboat/data/repositorio_usuarios_arquivo.dart';
import 'package:jetboat/domain/conta/resultados.dart';
import 'package:jetboat/ui/cadastro/tela_cadastro.dart';
import 'package:jetboat/ui/home/tela_inicial.dart';
import 'package:jetboat/ui/login/tela_login.dart';
import 'package:jetboat/ui/painel/tela_painel.dart';

/// Testes no aparelho/emulador: navegação do app inteiro, Keystore real e fluxo completo.
/// Usam um arquivo de usuários próprio, para não mexer nos dados reais do app.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory pasta;
  late Dependencias dependencias;

  setUp(() async {
    pasta = await Directory.systemTemp.createTemp('jetboat_it_');
    dependencias = await Dependencias.criar(arquivoUsuarios: File('${pasta.path}/usuarios.json'));
    await dependencias.sessaoArmazenamento.limpar(); // o app começa deslogado
  });

  tearDown(() async {
    await dependencias.sessaoArmazenamento.limpar();
    await pasta.delete(recursive: true);
  });

  /// Bombeia quadros até [alvo] aparecer (as telas têm animações infinitas).
  Future<void> esperar(WidgetTester tester, Finder alvo, {int segundos = 10}) async {
    final fim = DateTime.now().add(Duration(seconds: segundos));
    while (alvo.evaluate().isEmpty) {
      if (DateTime.now().isAfter(fim)) fail('Não apareceu: $alvo');
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Toca como um usuário: espera o alvo aparecer e a troca de tela / animação de entrada terminarem.
  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    await esperar(tester, alvo);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.ensureVisible(alvo);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(alvo);
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> digitar(WidgetTester tester, Key chave, String texto) async {
    final campo = find.byKey(chave);
    await esperar(tester, campo);
    await tester.ensureVisible(campo);
    await tester.enterText(campo, texto);
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> abrirApp(WidgetTester tester) async {
    await tester.pumpWidget(JetBoatApp(
      dependencias: dependencias,
      sessaoInicial: await dependencias.autenticacao.sessaoAtual(),
    ));
    await tester.pump(const Duration(seconds: 2));
  }

  /// Botão "voltar" do sistema Android.
  Future<void> voltarDoSistema(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(seconds: 1));
  }

  final titulo = find.byKey(TelaInicialChaves.titulo);
  final tituloCadastro = find.text('Crie sua conta ⚓');
  final tituloLogin = find.text('Bem-vindo de volta');

  group('navegação', () {
    testWidgets('Começar abre o cadastro e a seta volta para o início', (tester) async {
      await abrirApp(tester);
      await tocar(tester, find.byKey(TelaInicialChaves.botaoComecar));
      await esperar(tester, tituloCadastro);
      await tocar(tester, find.byKey(TelaCadastroChaves.voltar));
      await esperar(tester, titulo);
    });

    testWidgets('voltar do sistema retorna ao início', (tester) async {
      await abrirApp(tester);
      await tocar(tester, find.byKey(TelaInicialChaves.botaoComecar));
      await esperar(tester, tituloCadastro);
      await voltarDoSistema(tester);
      await esperar(tester, titulo);
    });

    testWidgets('Já tenho conta abre o login e a seta volta para o início', (tester) async {
      await abrirApp(tester);
      await tocar(tester, find.byKey(TelaInicialChaves.botaoEntrar));
      await esperar(tester, tituloLogin);
      await tocar(tester, find.byKey(TelaLoginChaves.voltar));
      await esperar(tester, titulo);
    });

    testWidgets('Criar conta no login abre o cadastro, e voltar retorna ao início', (tester) async {
      await abrirApp(tester);
      await tocar(tester, find.byKey(TelaInicialChaves.botaoEntrar));
      await tocar(tester, find.byKey(TelaLoginChaves.cadastrar));
      await esperar(tester, tituloCadastro);
      await voltarDoSistema(tester);
      await esperar(tester, titulo);
    });
  });

  testWidgets('fluxo completo: cadastro → painel → sair → login → painel → reabrir logado', (tester) async {
    await abrirApp(tester);
    await tocar(tester, find.byKey(TelaInicialChaves.botaoComecar));
    await digitar(tester, TelaCadastroChaves.nome, 'Maria da Silva');
    await digitar(tester, TelaCadastroChaves.cpf, '52998224725');
    await digitar(tester, TelaCadastroChaves.data, '15031990');
    await digitar(tester, TelaCadastroChaves.telefone, '11987654321');
    await digitar(tester, TelaCadastroChaves.email, 'maria@email.com');
    await digitar(tester, TelaCadastroChaves.senha, 'Barco2026');
    await digitar(tester, TelaCadastroChaves.confirmarSenha, 'Barco2026');
    await tocar(tester, find.byKey(TelaCadastroChaves.termos));
    await tocar(tester, find.byKey(TelaCadastroChaves.cadastrar));
    await tocar(tester, find.text('Continuar'));

    // Quem acabou de se cadastrar já entra logado
    await esperar(tester, find.text('Olá, Maria 👋'));

    // Sair leva ao início, e o voltar não retorna à área logada
    await tocar(tester, find.byKey(TelaPainelChaves.sair));
    await esperar(tester, titulo);
    expect(await dependencias.autenticacao.sessaoAtual(), isNull);

    // Login
    await tocar(tester, find.byKey(TelaInicialChaves.botaoEntrar));
    await digitar(tester, TelaLoginChaves.email, 'maria@email.com');
    await digitar(tester, TelaLoginChaves.senha, 'Barco2026');
    await tocar(tester, find.byKey(TelaLoginChaves.entrar));
    await esperar(tester, find.text('Olá, Maria 👋'));

    // Reabrir o app (novas dependências, mesmo Keystore): continua logado
    dependencias = await Dependencias.criar(arquivoUsuarios: File('${pasta.path}/usuarios.json'));
    await tester.pumpWidget(const SizedBox());
    await abrirApp(tester);
    await esperar(tester, find.byKey(TelaPainelChaves.saudacao));
  });

  testWidgets('chave do JWT fica no armazenamento seguro do aparelho (Keystore)', (tester) async {
    final seguro = ArmazenamentoSeguroDispositivo();
    final token = Jwt(await AssinadorHmac.carregar(seguro)).gerar(const ClaimsJwt(
      sujeito: 'u1',
      email: 'maria@email.com',
      tipo: TipoToken.acesso,
      emitidoEm: 1800000000,
      expiraEm: 1800000900,
      id: 'j1',
    ));
    // Uma nova leitura da chave valida o token emitido antes
    final validacao = Jwt(await AssinadorHmac.carregar(seguro)).validar(token, TipoToken.acesso, 1800000000);
    expect(validacao, isA<TokenValido>());
  });

  testWidgets('contas ficam no armazenamento interno do app e sobrevivem a uma nova leitura', (tester) async {
    // Onde o app guarda as contas de verdade (sem tocar nesse arquivo).
    final real = await arquivoUsuariosPadrao();
    if (Platform.isAndroid) {
      // Pasta interna e privada do app: /data/user/0/com.example.jetboat/files/
      expect(real.path.replaceAll(r'\', '/'), endsWith('com.example.jetboat/files/${RepositorioUsuariosArquivo.nomeArquivo}'));
    }

    // Na mesma pasta, um arquivo só deste teste: grava, lê com outra instância e apaga.
    final sonda = File('${real.parent.path}/usuarios_teste_integracao.json');
    try {
      final cadastro = await RepositorioUsuariosArquivo(sonda).cadastrar(
        nome: 'Teste Integração',
        cpf: '52998224725',
        dataNascimento: '15/03/1990',
        telefone: '11987654321',
        email: 'integracao@teste.com',
        senha: 'Barco2026',
      );
      expect(cadastro, isA<CadastroSucesso>());

      final relido = await RepositorioUsuariosArquivo(sonda).buscarPorEmail('INTEGRACAO@teste.com');
      expect(relido?.nome, 'Teste Integração');
      expect(relido?.senhaHash, isNotEmpty);
      expect(await sonda.readAsString(), isNot(contains('Barco2026'))); // senha nunca em texto puro
    } finally {
      if (await sonda.exists()) await sonda.delete();
    }
  });
}
