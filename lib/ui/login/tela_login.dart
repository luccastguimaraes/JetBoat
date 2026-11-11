import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jetboat/domain/conta/autenticacao.dart';
import 'package:jetboat/domain/conta/validador_cadastro.dart';
import 'package:jetboat/ui/components/campos.dart';
import 'package:jetboat/ui/components/componentes.dart';
import 'package:jetboat/ui/theme/cores.dart';
import 'package:jetboat/ui/theme/dimens.dart';
import 'package:jetboat/ui/theme/movimento.dart';

/// Chaves usadas nos testes de UI.
abstract final class TelaLoginChaves {
  static const voltar = ValueKey('login_voltar');
  static const email = ValueKey('login_email');
  static const senha = ValueKey('login_senha');
  static const entrar = ValueKey('login_entrar');
  static const erro = ValueKey('login_erro');
  static const avisoSessao = ValueKey('login_aviso_sessao');
  static const criarConta = ValueKey('login_criar_conta');
  static const esqueciSenha = ValueKey('login_esqueci_senha');
}

class TelaLogin extends StatefulWidget {
  const TelaLogin({
    super.key,
    required this.autenticacao,
    required this.onVoltar,
    required this.onCriarConta,
    required this.onEsqueciSenha,
    required this.onLoginConcluido,
    this.sessaoExpirada = false,
  });

  final Autenticacao autenticacao;
  final VoidCallback onVoltar;
  final VoidCallback onCriarConta;
  final VoidCallback onEsqueciSenha;
  final ValueChanged<Sessao> onLoginConcluido;
  final bool sessaoExpirada;

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  String? _erroEmail;
  String? _erroSenha;
  String? _erroGeral;
  var _carregando = false;

  // Contagem regressiva do bloqueio por excesso de tentativas
  var _segundosBloqueio = 0;
  Timer? _cronometro;

  bool get _bloqueado => _segundosBloqueio > 0;

  @override
  void dispose() {
    _cronometro?.cancel();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  void _iniciarBloqueio(int segundos) {
    final ate = DateTime.now().add(Duration(seconds: segundos));
    void atualizar() {
      final restante = (ate.difference(DateTime.now()).inMilliseconds + 999) ~/ 1000;
      setState(() {
        _segundosBloqueio = restante < 0 ? 0 : restante;
        if (_segundosBloqueio == 0) {
          _cronometro?.cancel();
          _erroGeral = null;
        }
      });
    }

    _cronometro?.cancel();
    _cronometro = Timer.periodic(const Duration(seconds: 1), (_) => atualizar());
    atualizar();
  }

  Future<void> _entrar() async {
    if (_carregando || _bloqueado) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _erroEmail = ValidadorCadastro.email(_email.text);
      _erroSenha = _senha.text.isEmpty ? 'Informe sua senha' : null;
    });
    if (_erroEmail != null || _erroSenha != null) return;

    setState(() {
      _carregando = true;
      _erroGeral = null;
    });
    final resultado = await widget.autenticacao.entrar(_email.text, _senha.text);
    if (!mounted) return;
    setState(() => _carregando = false);
    switch (resultado) {
      case LoginSucesso(:final sessao):
        _senha.clear();
        widget.onLoginConcluido(sessao);
      case CredenciaisInvalidas(:final tentativasRestantes):
        // Mensagem genérica: não revela se o e-mail existe.
        // Avisa das últimas tentativas antes do bloqueio.
        setState(() => _erroGeral = 'E-mail ou senha incorretos.${switch (tentativasRestantes) {
              1 => ' Resta 1 tentativa.',
              2 => ' Restam 2 tentativas.',
              _ => '',
            }}');
      case LoginBloqueado(:final segundosRestantes):
        setState(() => _erroGeral = 'Muitas tentativas. Aguarde um pouco para tentar de novo.');
        _iniciarBloqueio(segundosRestantes);
    }
  }

  void _limparErros({bool email = false, bool senha = false}) => setState(() {
        if (email) _erroEmail = null;
        if (senha) _erroSenha = null;
        _erroGeral = null;
      });

  @override
  Widget build(BuildContext context) {
    final t = context.texto;
    return TelaBase(
      children: [
        BotaoVoltar(key: TelaLoginChaves.voltar, onPressed: widget.onVoltar),
        const SizedBox(height: Espacamento.xl),
        const CabecalhoTela(
          emoji: '🚤',
          titulo: 'Bem-vindo de volta',
          subtitulo: 'Entre para reservar sua próxima saída para o mar.',
        ),
        const SizedBox(height: Espacamento.xl),
        if (widget.sessaoExpirada) ...[
          const Aviso(
            key: TelaLoginChaves.avisoSessao,
            texto: 'Sua sessão expirou. Entre novamente para continuar.',
            cor: sunsetYellow,
          ),
          const SizedBox(height: Espacamento.lg),
        ],
        CartaoVidro(
          titulo: 'Acesse sua conta',
          children: [
            const SizedBox(height: Espacamento.xs),
            CampoTexto(
              key: TelaLoginChaves.email,
              controller: _email,
              rotulo: 'E-mail',
              erro: _erroEmail,
              onChanged: (_) => _limparErros(email: true),
              teclado: TextInputType.emailAddress,
              formatadores: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
              dica: 'voce@email.com',
              habilitado: !_carregando,
            ),
            const SizedBox(height: Espacamento.xs),
            CampoSenha(
              key: TelaLoginChaves.senha,
              controller: _senha,
              rotulo: 'Senha',
              erro: _erroSenha,
              onChanged: (_) => _limparErros(senha: true),
              acao: TextInputAction.done,
              onSubmitted: _entrar,
              habilitado: !_carregando,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: TelaLoginChaves.esqueciSenha,
                onPressed: widget.onEsqueciSenha,
                child: Text('Esqueci minha senha', style: t.bodyMedium?.copyWith(color: aqua)),
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: Movimento.curta,
          child: _erroGeral == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: Espacamento.lg),
                  child: Aviso(key: TelaLoginChaves.erro, texto: _erroGeral!, cor: coral),
                ),
        ),
        const SizedBox(height: Espacamento.xl),
        BotaoPrincipal(
          key: TelaLoginChaves.entrar,
          texto: _bloqueado ? 'Tente de novo em ${_segundosBloqueio}s' : 'Entrar',
          onPressed: _entrar,
          carregando: _carregando,
        ),
        const SizedBox(height: Espacamento.lg),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Ainda não tem conta?', style: t.bodyMedium?.copyWith(color: textSecondary)),
              TextButton(
                key: TelaLoginChaves.criarConta,
                onPressed: widget.onCriarConta,
                child: Text(
                  'Criar conta',
                  style: t.bodyMedium?.copyWith(color: sunsetYellow, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Espacamento.lg),
      ],
    );
  }
}
