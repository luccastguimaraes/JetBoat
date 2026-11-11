import 'package:flutter/services.dart';

/// Máscara de digitação: aceita só dígitos e exibe já formatado.
/// Cada '#' do padrão é substituído por um dígito. Ex.: "###.###.###-##".
/// Para obter o valor "cru", use [digitos].
class Mascara extends TextInputFormatter {
  Mascara(this.padrao) : maxDigitos = '#'.allMatches(padrao).length;

  final String padrao;
  final int maxDigitos;

  static final cpf = Mascara('###.###.###-##');
  static final data = Mascara('##/##/####');
  static final telefone = Mascara('(##) #####-####');

  /// Só os dígitos de um texto.
  static String digitos(String texto) => texto.replaceAll(RegExp(r'[^0-9]'), '');

  String formatar(String digitos) {
    final buffer = StringBuffer();
    var i = 0;
    for (final c in padrao.split('')) {
      if (i >= digitos.length) break;
      buffer.write(c == '#' ? digitos[i++] : c);
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue antigo, TextEditingValue novo) {
    var d = digitos(novo.text);
    // Apagou só um separador (ex.: o "-")? Apaga também o dígito antes dele.
    if (novo.text.length < antigo.text.length && d == digitos(antigo.text) && d.isNotEmpty) {
      d = d.substring(0, d.length - 1);
    }
    if (d.length > maxDigitos) d = d.substring(0, maxDigitos);
    final texto = formatar(d);
    return TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length));
  }
}
