import 'dart:async';

import 'package:flutter/material.dart';

import 'package:jetboat/domain/conta/autenticacao.dart';
import 'package:jetboat/ui/components/componentes.dart';
import 'package:jetboat/ui/theme/cores.dart';
import 'package:jetboat/ui/theme/dimens.dart';

abstract final class TelaPainelChaves {
  static const saudacao = ValueKey('painel_saudacao');
  static const sair = ValueKey('painel_sair');
}

/// Área logada (provisória). Enquanto aberta, confere a sessão quando o token de acesso vence:
/// se ele puder ser renovado, segue; se não, chama [onSessaoExpirada].
class TelaPainel extends StatefulWidget {
  const TelaPainel({
    super.key,
    required this.autenticacao,
    required this.sessaoInicial,
    required this.onSair,
    required this.onSessaoExpirada,
  });

  final Autenticacao autenticacao;
  final Sessao sessaoInicial;
  final VoidCallback onSair;
  final VoidCallback onSessaoExpirada;

  @override
  State<TelaPainel> createState() => _TelaPainelState();
}

class _TelaPainelState extends State<TelaPainel> {
  late Sessao _sessao = widget.sessaoInicial;
  Timer? _verificacao;

  @override
  void initState() {
    super.initState();
    _agendarVerificacao();
  }

  @override
  void dispose() {
    _verificacao?.cancel();
    super.dispose();
  }

  void _agendarVerificacao() {
    final espera = (_sessao.expiraEm - DateTime.now().millisecondsSinceEpoch).clamp(1000, 60000);
    _verificacao = Timer(Duration(milliseconds: espera), () async {
      final sessao = await widget.autenticacao.sessaoAtual();
      if (!mounted) return;
      if (sessao == null) {
        widget.onSessaoExpirada();
      } else {
        setState(() => _sessao = sessao);
        _agendarVerificacao();
      }
    });
  }

  Future<void> _sair() async {
    _verificacao?.cancel();
    await widget.autenticacao.sair();
    widget.onSair();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.texto;
    final perfil = _sessao.perfil;
    return TelaBase(
      rolavel: false,
      paddingVertical: Espacamento.xl,
      children: [
        CabecalhoTela(
          key: TelaPainelChaves.saudacao,
          titulo: 'Olá, ${perfil.primeiroNome} 👋',
          subtitulo: 'Pronto para navegar hoje?',
        ),
        const SizedBox(height: Espacamento.xl),
        CartaoVidro(
          titulo: 'Sua conta',
          children: [
            Text(perfil.nome, style: t.titleMedium?.copyWith(color: textPrimary)),
            Text(perfil.email, style: t.bodyMedium?.copyWith(color: textMuted)),
          ],
        ),
        const Spacer(),
        BotaoSecundario(key: TelaPainelChaves.sair, texto: 'Sair da conta', onPressed: _sair),
      ],
    );
  }
}
