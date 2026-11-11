import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jetboat/dependencias.dart';
import 'package:jetboat/domain/conta/autenticacao.dart';
import 'package:jetboat/ui/components/componentes.dart';
import 'package:jetboat/ui/theme/movimento.dart';
import 'package:jetboat/ui/theme/tema.dart';
import 'package:jetboat/ui/cadastro/tela_cadastro.dart';
import 'package:jetboat/ui/home/tela_inicial.dart';
import 'package:jetboat/ui/login/tela_login.dart';
import 'package:jetboat/ui/painel/tela_painel.dart';

export 'package:jetboat/dependencias.dart';

/// Rotas de navegação do app.
abstract final class Rotas {
  static const inicio = '/';
  static const cadastro = '/cadastro';
  static const login = '/login'; // argumento: bool sessaoExpirada
  static const painel = '/painel'; // argumento: Sessao
}

class JetBoatApp extends StatefulWidget {
  /// [sessaoInicial]: sessão ainda válida (ou renovável) ao abrir o app — se houver, abre direto na área logada.
  const JetBoatApp({super.key, required this.dependencias, this.sessaoInicial});

  final Dependencias dependencias;
  final Sessao? sessaoInicial;

  @override
  State<JetBoatApp> createState() => _JetBoatAppState();
}

class _JetBoatAppState extends State<JetBoatApp> {
  final _navegador = GlobalKey<NavigatorState>();

  NavigatorState get _nav => _navegador.currentState!;
  Autenticacao get _auth => widget.dependencias.autenticacao;

  /// Vai para a área logada limpando a pilha: o "voltar" não retorna ao login/cadastro.
  void _irParaPainel(Sessao sessao) => _nav.pushNamedAndRemoveUntil(Rotas.painel, (_) => false, arguments: sessao);

  /// Volta ao início limpando a pilha: o "voltar" não retorna à área logada.
  void _irParaInicio() => _nav.pushNamedAndRemoveUntil(Rotas.inicio, (_) => false);

  Route<void> _rota(RouteSettings settings) {
    final Widget tela = switch (settings.name) {
      Rotas.cadastro => Builder(
          builder: (context) => TelaCadastro(
            autenticacao: _auth,
            onVoltar: () => _nav.pop(),
            onCadastroConcluido: (_) async {
              // A conta já foi criada com a sessão aberta (Autenticacao.cadastrar)
              final sessao = await _auth.sessaoAtual();
              if (sessao != null) _irParaPainel(sessao);
            },
          ),
        ),
      Rotas.login => Builder(
          builder: (context) => TelaLogin(
            autenticacao: _auth,
            sessaoExpirada: settings.arguments == true,
            onVoltar: () => _nav.pop(),
            onCriarConta: () => _nav.pushNamedAndRemoveUntil(Rotas.cadastro, ModalRoute.withName(Rotas.inicio)),
            // TODO: fluxo de recuperação de senha
            onEsqueciSenha: () => mostrarMensagem(context, 'Recuperação de senha em breve'),
            onLoginConcluido: _irParaPainel,
          ),
        ),
      Rotas.painel => TelaPainel(
          autenticacao: _auth,
          sessaoInicial: settings.arguments! as Sessao,
          onSair: _irParaInicio,
          onSessaoExpirada: () {
            _irParaInicio();
            _nav.pushNamed(Rotas.login, arguments: true);
          },
        ),
      _ => Builder(
          builder: (context) => TelaInicial(
            onComecar: () => _nav.pushNamed(Rotas.cadastro),
            onEntrar: () => _nav.pushNamed(Rotas.login),
            onCategoria: (nome) => mostrarMensagem(context, nome),
          ),
        ),
    };
    return _RotaFade(settings: settings, tela: tela);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Fundo escuro (oceano): ícones das barras do sistema sempre claros
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: MaterialApp(
        title: 'JetBoat',
        debugShowCheckedModeBanner: false,
        theme: temaJetBoat,
        navigatorKey: _navegador,
        // Como no Compose: a altura de linha não adiciona espaço acima da 1ª linha nem abaixo da última
        builder: (context, filho) => DefaultTextHeightBehavior(
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
          child: filho!,
        ),
        onGenerateRoute: _rota,
        onGenerateInitialRoutes: (_) => [
          widget.sessaoInicial != null
              ? _rota(RouteSettings(name: Rotas.painel, arguments: widget.sessaoInicial))
              : _rota(const RouteSettings(name: Rotas.inicio)),
        ],
      ),
    );
  }
}

/// Troca de tela com fade cruzado: a nova aparece enquanto a anterior some
/// (Movimento.transicaoTela, Movimento.curva). Usada por todas as rotas.
class _RotaFade extends PageRouteBuilder<void> {
  _RotaFade({required RouteSettings super.settings, required Widget tela})
      : super(
          transitionDuration: Movimento.transicaoTela,
          reverseTransitionDuration: Movimento.transicaoTela,
          pageBuilder: (_, _, _) => tela,
          transitionsBuilder: (_, entrada, saida, filho) => FadeTransition(
            opacity: CurvedAnimation(parent: entrada, curve: Movimento.curva),
            child: FadeTransition(
              opacity: ReverseAnimation(CurvedAnimation(parent: saida, curve: Movimento.curva)),
              child: filho,
            ),
          ),
        );
}
