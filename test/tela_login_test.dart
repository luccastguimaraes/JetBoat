import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jetboat/data/auth/armazenamento_seguro.dart';
import 'package:jetboat/data/auth/assinador.dart';
import 'package:jetboat/data/auth/autenticacao_local.dart';
import 'package:jetboat/domain/conta/autenticacao.dart';
import 'package:jetboat/data/auth/jwt.dart';
import 'package:jetboat/data/auth/sessao_armazenamento.dart';
import 'package:jetboat/data/repositorio_usuarios_arquivo.dart';
import 'package:jetboat/ui/components/componentes.dart';
import 'package:jetboat/ui/login/tela_login.dart';

import 'util.dart';

typedef K = TelaLoginChaves;

void main() {
  late Directory pasta;
  late AutenticacaoLocal auth;
  Sessao? sessao;
  late int voltou;
  late int cadastrar;

  setUp(() async {
    pasta = Directory.systemTemp.createTempSync('jetboat_login_');
    final usuarios = RepositorioUsuariosArquivo(File('${pasta.path}/usuarios.json'));
    await usuarios.cadastrar(
      nome: 'Maria da Silva',
      cpf: '52998224725',
      dataNascimento: '15/03/1990',
      telefone: '11987654321',
      email: 'maria@email.com',
      senha: 'Barco2026',
    );
    auth = AutenticacaoLocal(
      usuarios: usuarios,
      jwt: Jwt(AssinadorHmac(List.filled(32, 7))),
      armazenamento: SessaoArmazenamento(ArmazenamentoEmMemoria()),
    );
    sessao = null;
    voltou = 0;
    cadastrar = 0;
  });

  tearDown(() => pasta.deleteSync(recursive: true));

  Future<void> abrir(WidgetTester tester, {bool sessaoExpirada = false}) async {
    usarTelaDeCelular(tester);
    await tester.pumpWidget(comTema(TelaLogin(
      autenticacao: auth,
      sessaoExpirada: sessaoExpirada,
      onVoltar: () => voltou++,
      onCriarConta: () => cadastrar++,
      onEsqueciSenha: () {},
      onLoginConcluido: (s) => sessao = s,
    )));
  }

  Future<void> entrarCom(WidgetTester tester, String email, String senha) async {
    await digitar(tester, K.email, email);
    await digitar(tester, K.senha, senha);
    await tocar(tester, find.byKey(K.entrar));
  }

  testWidgets('login válido conclui', (tester) async {
    await abrir(tester);
    await entrarCom(tester, 'maria@email.com', 'Barco2026');
    await esperarAte(tester, () => sessao != null);
    expect(sessao!.perfil.nome, 'Maria da Silva');
  });

  testWidgets('senha errada mostra erro genérico', (tester) async {
    await abrir(tester);
    await entrarCom(tester, 'maria@email.com', 'errada123');
    await esperarAte(tester, () => find.byKey(K.erro).evaluate().isNotEmpty);
    final aviso = tester.widget<Aviso>(find.byKey(K.erro));
    expect(aviso.texto, startsWith('E-mail ou senha incorretos'));
    expect(sessao, isNull);
  });

  testWidgets('campos vazios mostram erros sem chamar o serviço', (tester) async {
    await abrir(tester);
    await tocar(tester, find.byKey(K.entrar));
    expect(find.text('Informe seu e-mail'), findsOneWidget);
    expect(find.text('Informe sua senha'), findsOneWidget);
    expect(sessao, isNull);
  });

  testWidgets('aviso de sessão expirada', (tester) async {
    await abrir(tester, sessaoExpirada: true);
    expect(find.byKey(K.avisoSessao), findsOneWidget);
  });

  testWidgets('botões de navegação', (tester) async {
    await abrir(tester);
    await tocar(tester, find.byKey(K.voltar));
    await tocar(tester, find.byKey(K.cadastrar));
    expect(voltou, 1);
    expect(cadastrar, 1);
  });
}
