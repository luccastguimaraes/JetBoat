import 'package:flutter_test/flutter_test.dart';
import 'package:jetboat/domain/conta/autenticacao.dart';
import 'package:jetboat/ui/components/componentes.dart';
import 'package:jetboat/ui/login/tela_login.dart';

import 'autenticacao_falsa.dart';
import 'util.dart';

typedef K = TelaLoginChaves;

void main() {
  late AutenticacaoFalsa auth;
  Sessao? sessao;
  late int voltou;
  late int cadastrar;

  setUp(() {
    auth = AutenticacaoFalsa(contas: {'maria@email.com': 'Barco2026'});
    sessao = null;
    voltou = 0;
    cadastrar = 0;
  });

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
    expect(sessao!.perfil.email, 'maria@email.com');
    expect(auth.chamadasEntrar, 1);
  });

  testWidgets('senha errada mostra erro genérico', (tester) async {
    await abrir(tester);
    await entrarCom(tester, 'maria@email.com', 'errada123');
    await esperarAte(tester, () => find.byKey(K.erro).evaluate().isNotEmpty);
    final aviso = tester.widget<Aviso>(find.byKey(K.erro));
    expect(aviso.texto, startsWith('E-mail ou senha incorretos'));
    expect(sessao, isNull);
  });

  testWidgets('avisa quando restam poucas tentativas', (tester) async {
    auth.respostaLogin = const CredenciaisInvalidas(1);
    await abrir(tester);
    await entrarCom(tester, 'maria@email.com', 'errada123');
    await esperarAte(tester, () => find.byKey(K.erro).evaluate().isNotEmpty);
    expect(tester.widget<Aviso>(find.byKey(K.erro)).texto, 'E-mail ou senha incorretos. Resta 1 tentativa.');
  });

  testWidgets('login bloqueado mostra a contagem no botão e não chama o serviço de novo', (tester) async {
    auth.respostaLogin = const LoginBloqueado(30);
    await abrir(tester);
    await entrarCom(tester, 'maria@email.com', 'errada123');
    await esperarAte(tester, () => find.text('Tente de novo em 30s').evaluate().isNotEmpty);
    expect(tester.widget<Aviso>(find.byKey(K.erro)).texto, startsWith('Muitas tentativas'));

    await tocar(tester, find.byKey(K.entrar)); // bloqueado: o toque é ignorado
    expect(auth.chamadasEntrar, 1);
  });

  testWidgets('campos vazios mostram erros sem chamar o serviço', (tester) async {
    await abrir(tester);
    await tocar(tester, find.byKey(K.entrar));
    expect(find.text('Informe seu e-mail'), findsOneWidget);
    expect(find.text('Informe sua senha'), findsOneWidget);
    expect(auth.chamadasEntrar, 0);
    expect(sessao, isNull);
  });

  testWidgets('aviso de sessão expirada', (tester) async {
    await abrir(tester, sessaoExpirada: true);
    expect(find.byKey(K.avisoSessao), findsOneWidget);
  });

  testWidgets('botões de navegação', (tester) async {
    await abrir(tester);
    await tocar(tester, find.byKey(K.voltar));
    await tocar(tester, find.byKey(K.criarConta));
    expect(voltou, 1);
    expect(cadastrar, 1);
  });
}
