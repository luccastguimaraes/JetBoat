import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jetboat/ui/theme/cores.dart';
import 'package:jetboat/ui/theme/dimens.dart';
import 'package:jetboat/ui/components/componentes.dart';

/// Campo de texto padrão do app (vidro + borda aqua), com mensagem de erro abaixo.
class CampoTexto extends StatelessWidget {
  const CampoTexto({
    super.key,
    required this.controller,
    required this.rotulo,
    this.erro,
    this.onChanged,
    this.teclado = TextInputType.text,
    this.acao = TextInputAction.next,
    this.formatadores = const [],
    this.capitalizacao = TextCapitalization.none,
    this.dica,
    this.sufixo,
    this.onSubmitted,
    this.ocultar = false,
    this.habilitado = true,
  });

  final TextEditingController controller;
  final String rotulo;
  final String? erro;
  final ValueChanged<String>? onChanged;
  final TextInputType teclado;
  final TextInputAction acao;
  final List<TextInputFormatter> formatadores;
  final TextCapitalization capitalizacao;
  final String? dica;
  final Widget? sufixo;
  final VoidCallback? onSubmitted;
  final bool ocultar;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final t = context.texto;
    OutlineInputBorder borda(Color cor, [double largura = 1]) =>
        OutlineInputBorder(borderRadius: Formas.campo, borderSide: BorderSide(color: cor, width: largura));

    return TextField(
      controller: controller,
      onChanged: onChanged,
      enabled: habilitado,
      obscureText: ocultar,
      keyboardType: teclado,
      textInputAction: acao,
      textCapitalization: capitalizacao,
      inputFormatters: formatadores,
      autocorrect: false,
      enableSuggestions: !ocultar,
      onSubmitted: (_) => onSubmitted?.call(),
      cursorColor: erro != null ? coral : aqua,
      style: t.bodyLarge?.copyWith(color: textPrimary),
      decoration: InputDecoration(
        labelText: rotulo,
        hintText: dica,
        errorText: erro,
        suffixIcon: sufixo,
        filled: true,
        fillColor: WidgetStateColor.resolveWith((estados) {
          if (estados.contains(WidgetState.error)) return coral.withValues(alpha: 0.08);
          if (estados.contains(WidgetState.focused)) return glassFieldFocused;
          return glassField;
        }),
        labelStyle: t.bodyLarge?.copyWith(color: textMuted),
        // O Flutter reduz o rótulo flutuante a 75%: bodyLarge (16) × 0,75 = 12, igual ao bodySmall do Compose
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((estados) => t.bodyLarge!.copyWith(
              color: estados.contains(WidgetState.error)
                  ? coral
                  : estados.contains(WidgetState.focused)
                      ? aqua
                      : textMuted,
            )),
        hintStyle: t.bodyLarge?.copyWith(color: textHint),
        errorStyle: t.bodySmall?.copyWith(color: coral),
        border: borda(glassBorder),
        enabledBorder: borda(glassBorder),
        disabledBorder: borda(glassBorder),
        focusedBorder: borda(aqua, 2),
        errorBorder: borda(coral),
        focusedErrorBorder: borda(coral, 2),
        contentPadding: const EdgeInsets.symmetric(horizontal: Espacamento.lg, vertical: Espacamento.lg),
      ),
    );
  }
}

/// Campo de senha com botão "Mostrar/Ocultar".
class CampoSenha extends StatefulWidget {
  const CampoSenha({
    super.key,
    required this.controller,
    required this.rotulo,
    this.erro,
    this.onChanged,
    this.acao = TextInputAction.next,
    this.onSubmitted,
    this.habilitado = true,
  });

  final TextEditingController controller;
  final String rotulo;
  final String? erro;
  final ValueChanged<String>? onChanged;
  final TextInputAction acao;
  final VoidCallback? onSubmitted;
  final bool habilitado;

  @override
  State<CampoSenha> createState() => _CampoSenhaState();
}

class _CampoSenhaState extends State<CampoSenha> {
  var _visivel = false;

  @override
  Widget build(BuildContext context) {
    return CampoTexto(
      controller: widget.controller,
      rotulo: widget.rotulo,
      erro: widget.erro,
      onChanged: widget.onChanged,
      teclado: TextInputType.visiblePassword,
      acao: widget.acao,
      onSubmitted: widget.onSubmitted,
      habilitado: widget.habilitado,
      ocultar: !_visivel,
      // Fora da ordem de foco: o "próximo" do teclado deve ir para o campo seguinte, não para este botão
      sufixo: ExcludeFocus(
        child: Padding(
          padding: const EdgeInsets.only(right: Espacamento.xs),
          child: TextButton(
            onPressed: () => setState(() => _visivel = !_visivel),
            child: Text(_visivel ? 'Ocultar' : 'Mostrar', style: context.texto.bodyMedium?.copyWith(color: aqua)),
          ),
        ),
      ),
    );
  }
}
