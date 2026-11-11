import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jetboat/domain/conta/autenticacao.dart';
import 'package:jetboat/ui/components/campos.dart';
import 'package:jetboat/ui/components/componentes.dart';
import 'package:jetboat/ui/theme/cores.dart';
import 'package:jetboat/ui/theme/dimens.dart';
import 'package:jetboat/ui/theme/movimento.dart';
import 'package:jetboat/ui/components/mascara.dart';
import 'package:jetboat/domain/conta/validador_cadastro.dart';

/// Chaves usadas nos testes de UI.
abstract final class TelaCadastroChaves {
  static const voltar = ValueKey('cadastro_voltar');
  static const nome = ValueKey('cadastro_nome');
  static const cpf = ValueKey('cadastro_cpf');
  static const data = ValueKey('cadastro_data');
  static const telefone = ValueKey('cadastro_telefone');
  static const email = ValueKey('cadastro_email');
  static const senha = ValueKey('cadastro_senha');
  static const confirmarSenha = ValueKey('cadastro_confirmar_senha');
  static const termos = ValueKey('cadastro_termos');
  static const cadastrar = ValueKey('cadastro_cadastrar');
}

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({
    super.key,
    required this.autenticacao,
    required this.onVoltar,
    required this.onCadastroConcluido,
  });

  /// Cria a conta e já inicia a sessão (ver [Autenticacao.cadastrar]).
  final Autenticacao autenticacao;
  final VoidCallback onVoltar;
  final ValueChanged<Perfil> onCadastroConcluido;

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  final _nome = TextEditingController();
  final _cpf = TextEditingController();
  final _data = TextEditingController();
  final _telefone = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirmacao = TextEditingController();
  var _aceitouTermos = false;

  var _erros = const ErrosCadastro();
  var _carregando = false;

  @override
  void dispose() {
    for (final c in [_nome, _cpf, _data, _telefone, _email, _senha, _confirmacao]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (_carregando) return;
    FocusScope.of(context).unfocus();
    final cpf = Mascara.digitos(_cpf.text);
    final data = Mascara.digitos(_data.text);
    final telefone = Mascara.digitos(_telefone.text);
    final campos = CamposCadastro(
      nome: _nome.text,
      cpf: cpf,
      dataNascimento: data,
      telefone: telefone,
      email: _email.text,
      senha: _senha.text,
      confirmacaoSenha: _confirmacao.text,
      aceitouTermos: _aceitouTermos,
    );
    setState(() => _erros = ValidadorCadastro.validar(campos));
    if (!_erros.valido) return;

    setState(() => _carregando = true);
    final resultado = await widget.autenticacao.cadastrar(
      nome: _nome.text,
      cpf: cpf,
      dataNascimento: '${data.substring(0, 2)}/${data.substring(2, 4)}/${data.substring(4, 8)}',
      telefone: telefone,
      email: _email.text,
      senha: _senha.text,
    );
    if (!mounted) return;
    setState(() => _carregando = false);
    switch (resultado) {
      case CadastroSucesso(:final perfil):
        await _mostrarConfirmacao(perfil);
      case CpfJaCadastrado():
        setState(() => _erros = _erros.copyWith(cpf: 'CPF já cadastrado'));
      case EmailJaCadastrado():
        setState(() => _erros = _erros.copyWith(email: 'E-mail já cadastrado'));
    }
  }

  Future<void> _mostrarConfirmacao(Perfil perfil) async {
    final t = context.texto;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (contextoDialogo) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: oceanDeep,
          title: Text('Conta criada! 🎉', style: t.titleLarge?.copyWith(color: textPrimary)),
          content: Text(
            'Bem-vindo(a) a bordo, ${perfil.primeiroNome}! Agora é só escolher sua embarcação.',
            style: t.bodyLarge?.copyWith(color: textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(contextoDialogo).pop(),
              child: Text('Continuar', style: t.bodyLarge?.copyWith(color: sunsetYellow, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    widget.onCadastroConcluido(perfil);
  }

  void _alternarTermos() => setState(() {
        _aceitouTermos = !_aceitouTermos;
        _erros = _erros.copyWith(termos: null);
      });

  @override
  Widget build(BuildContext context) {
    final t = context.texto;
    return TelaBase(
      children: [
        // Cabeçalho
        Row(
          children: [
            BotaoVoltar(key: TelaCadastroChaves.voltar, onPressed: widget.onVoltar),
            const SizedBox(width: Espacamento.md),
            Text('Passo 1 de 1', style: t.bodyMedium?.copyWith(color: textMuted)),
          ],
        ),
        const SizedBox(height: Espacamento.xl),
        const CabecalhoTela(
          titulo: 'Crie sua conta ⚓',
          subtitulo: 'Leva menos de um minuto para você começar a navegar.',
        ),
        const SizedBox(height: Espacamento.xl),

        _Secao('Dados pessoais', [
          CampoTexto(
            key: TelaCadastroChaves.nome,
            controller: _nome,
            rotulo: 'Nome completo',
            erro: _erros.nome,
            onChanged: (_) => setState(() => _erros = _erros.copyWith(nome: null)),
            capitalizacao: TextCapitalization.words,
          ),
          CampoTexto(
            key: TelaCadastroChaves.cpf,
            controller: _cpf,
            rotulo: 'CPF',
            erro: _erros.cpf,
            onChanged: (_) => setState(() => _erros = _erros.copyWith(cpf: null)),
            teclado: TextInputType.number,
            formatadores: [Mascara.cpf],
            dica: '000.000.000-00',
          ),
          CampoTexto(
            key: TelaCadastroChaves.data,
            controller: _data,
            rotulo: 'Data de nascimento',
            erro: _erros.dataNascimento,
            onChanged: (_) => setState(() => _erros = _erros.copyWith(dataNascimento: null)),
            teclado: TextInputType.number,
            formatadores: [Mascara.data],
            dica: 'dd/mm/aaaa',
          ),
        ]),

        _Secao('Contato', [
          CampoTexto(
            key: TelaCadastroChaves.telefone,
            controller: _telefone,
            rotulo: 'Celular',
            erro: _erros.telefone,
            onChanged: (_) => setState(() => _erros = _erros.copyWith(telefone: null)),
            teclado: TextInputType.phone,
            formatadores: [Mascara.telefone],
            dica: '(00) 00000-0000',
          ),
          CampoTexto(
            key: TelaCadastroChaves.email,
            controller: _email,
            rotulo: 'E-mail',
            erro: _erros.email,
            onChanged: (_) => setState(() => _erros = _erros.copyWith(email: null)),
            teclado: TextInputType.emailAddress,
            formatadores: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            dica: 'voce@email.com',
          ),
        ]),

        _Secao('Segurança', [
          CampoSenha(
            key: TelaCadastroChaves.senha,
            controller: _senha,
            rotulo: 'Senha',
            erro: _erros.senha,
            onChanged: (_) => setState(() => _erros = _erros.copyWith(senha: null)),
          ),
          _IndicadorForcaSenha(ValidadorCadastro.forcaSenha(_senha.text)),
          CampoSenha(
            key: TelaCadastroChaves.confirmarSenha,
            controller: _confirmacao,
            rotulo: 'Confirmar senha',
            erro: _erros.confirmacaoSenha,
            onChanged: (_) => setState(() => _erros = _erros.copyWith(confirmacaoSenha: null)),
            acao: TextInputAction.done,
            onSubmitted: _cadastrar,
          ),
        ]),

        // Termos de uso
        InkWell(
          key: TelaCadastroChaves.termos,
          borderRadius: Formas.campo,
          onTap: _alternarTermos,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Espacamento.xs),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Espacamento.xs),
                  child: Checkbox(
                    value: _aceitouTermos,
                    onChanged: (_) => _alternarTermos(),
                    activeColor: aqua,
                    checkColor: oceanDeep,
                    side: BorderSide(color: _erros.termos != null ? coral : textMuted, width: 2),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Li e aceito os Termos de Uso e a Política de Privacidade',
                    style: t.bodyMedium?.copyWith(color: textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_erros.termos != null)
          Padding(
            padding: const EdgeInsets.only(left: Espacamento.lg),
            child: Text(_erros.termos!, style: t.bodySmall?.copyWith(color: coral)),
          ),

        const SizedBox(height: Espacamento.xl),
        BotaoPrincipal(
          key: TelaCadastroChaves.cadastrar,
          texto: 'Cadastrar',
          onPressed: _cadastrar,
          carregando: _carregando,
        ),
        const SizedBox(height: Espacamento.md),
        Center(
          child: TextButton(
            onPressed: widget.onVoltar,
            child: Text('Voltar para o início', style: t.bodyMedium?.copyWith(color: textSecondary)),
          ),
        ),
        const SizedBox(height: Espacamento.lg),
      ],
    );
  }
}

/// Cartão de vidro com título, agrupando campos relacionados.
class _Secao extends StatelessWidget {
  const _Secao(this.titulo, this.campos);

  final String titulo;
  final List<Widget> campos;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Espacamento.lg),
        child: CartaoVidro(
          titulo: titulo,
          // 4 (espaçamento do cartão) + 8 (espaço do rótulo do campo) = 12, como no Compose
          children: [for (final c in campos) Padding(padding: const EdgeInsets.only(top: Espacamento.sm), child: c)],
        ),
      );
}

class _IndicadorForcaSenha extends StatelessWidget {
  const _IndicadorForcaSenha(this.forca);

  final int forca;

  @override
  Widget build(BuildContext context) {
    final (texto, cor) = switch (forca) {
      0 => ('Use 8+ caracteres com letras e números', textMuted),
      1 => ('Senha fraca', coral),
      2 => ('Senha razoável', sunsetOrange),
      3 => ('Senha boa', sunsetYellow),
      _ => ('Senha forte 💪', aqua),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: Espacamento.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 6,
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: AnimatedContainer(
                    duration: Movimento.curta,
                    height: 5,
                    decoration: BoxDecoration(
                      color: i < forca ? cor : glassWhite,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(texto, style: context.texto.bodySmall?.copyWith(color: cor)),
        ],
      ),
    );
  }
}
