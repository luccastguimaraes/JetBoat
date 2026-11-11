import 'package:flutter_test/flutter_test.dart';
import 'package:jetboat/ui/components/mascara.dart';

TextEditingValue _v(String texto) => TextEditingValue(text: texto);

void main() {
  test('formata enquanto digita e limita a quantidade de dígitos', () {
    expect(Mascara.cpf.formatEditUpdate(_v(''), _v('529982247251234')).text, '529.982.247-25');
    expect(Mascara.data.formatEditUpdate(_v(''), _v('1503')).text, '15/03');
    expect(Mascara.telefone.formatEditUpdate(_v(''), _v('11987654321')).text, '(11) 98765-4321');
  });

  test('ignora caracteres que não são dígitos', () {
    expect(Mascara.cpf.formatEditUpdate(_v(''), _v('52a9.98')).text, '529.98');
  });

  test('apagar um separador apaga o dígito anterior', () {
    expect(Mascara.cpf.formatEditUpdate(_v('529.'), _v('529')).text, '52');
  });

  test('extrai só os dígitos', () {
    expect(Mascara.digitos('(11) 98765-4321'), '11987654321');
  });
}
