import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jetboat/data/senha.dart';

String _hex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  test('PBKDF2-HMAC-SHA1 confere com os vetores oficiais (RFC 6070)', () {
    expect(
      _hex(Senha.pbkdf2HmacSha1(utf8.encode('password'), utf8.encode('salt'), iteracoes: 1, tamanho: 20)),
      '0c60c80f961f0e71f3a9b524af6012062fe037a6',
    );
    expect(
      _hex(Senha.pbkdf2HmacSha1(utf8.encode('password'), utf8.encode('salt'), iteracoes: 4096, tamanho: 20)),
      '4b007901b765489abead49d926f721d065a429c1',
    );
    expect(
      _hex(Senha.pbkdf2HmacSha1(
        utf8.encode('passwordPASSWORDpassword'),
        utf8.encode('saltSALTsaltSALTsaltSALTsaltSALTsalt'),
        iteracoes: 4096,
        tamanho: 25,
      )),
      '3d2eec4fe41c849b80c8d83662c0e44a8b291a964cf2f07038',
    );
  });

  // Hashes gerados pelo `PBKDF2WithHmacSHA1` do Java, o mesmo usado pela versão Kotlin do app.
  // Garante que as contas criadas antes da migração continuam entrando.
  test('compatível com os hashes gerados pela versão Kotlin', () async {
    const salt = 'AwoRGB8mLTQ7QklQV15lbA==';
    expect(await Senha.confere('Barco2026', 'TiwhBKbhkKZp5OijiyB3enufKaI1xZE2zkDtVUxeD24=', salt), isTrue);
    expect(await Senha.confere('Ção#Mar 2026', 'l7mj2ZXiUpa+ATWS18fl7584syzMbNQu5yqUkXIV4DY=', salt), isTrue);
    expect(await Senha.confere('Barco2025', 'TiwhBKbhkKZp5OijiyB3enufKaI1xZE2zkDtVUxeD24=', salt), isFalse);
  });

  test('gera salt aleatório e confere a própria senha', () async {
    final a = await Senha.gerarHash('Barco2026');
    final b = await Senha.gerarHash('Barco2026');
    expect(a.salt, isNot(b.salt));
    expect(a.hash, isNot(b.hash));
    expect(await Senha.confere('Barco2026', a.hash, a.salt), isTrue);
    expect(await Senha.confere('SenhaErrada1', a.hash, a.salt), isFalse);
  });
}
