import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Hash de senha com PBKDF2 + salt aleatório.
/// Assim, mesmo que alguém leia o arquivo de usuários, não descobre as senhas.
///
/// Parâmetros idênticos aos da versão Kotlin anterior (PBKDF2WithHmacSHA1, 10.000 iterações,
/// 256 bits, salt de 16 bytes, Base64), para que as contas já cadastradas continuem entrando.
/// O cálculo roda em outro isolate para não travar a interface.
abstract final class Senha {
  static const iteracoes = 10000;
  static const tamanhoChaveBytes = 32;

  static Future<({String hash, String salt})> gerarHash(String senha) {
    final salt = _bytesAleatorios(16);
    return Isolate.run(() => (hash: base64.encode(pbkdf2HmacSha1(utf8.encode(senha), salt)), salt: base64.encode(salt)));
  }

  static Future<bool> confere(String senha, String hash, String salt) => Isolate.run(() {
        final calculado = pbkdf2HmacSha1(utf8.encode(senha), base64.decode(salt));
        return iguaisEmTempoConstante(calculado, base64.decode(hash));
      });

  /// PBKDF2 (RFC 8018) com HMAC-SHA1.
  static Uint8List pbkdf2HmacSha1(
    List<int> senha,
    List<int> salt, {
    int iteracoes = Senha.iteracoes,
    int tamanho = tamanhoChaveBytes,
  }) {
    final hmac = Hmac(sha1, senha);
    final resultado = BytesBuilder(copy: false);
    for (var bloco = 1; resultado.length < tamanho; bloco++) {
      var u = hmac.convert([...salt, bloco >> 24 & 0xff, bloco >> 16 & 0xff, bloco >> 8 & 0xff, bloco & 0xff]).bytes;
      final t = Uint8List.fromList(u);
      for (var i = 1; i < iteracoes; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      resultado.add(t);
    }
    return Uint8List.sublistView(resultado.toBytes(), 0, tamanho);
  }

  static Uint8List _bytesAleatorios(int n) {
    final r = Random.secure();
    return Uint8List.fromList(List.generate(n, (_) => r.nextInt(256)));
  }
}

/// Comparação que não sai cedo no primeiro byte diferente (evita ataque de tempo).
bool iguaisEmTempoConstante(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diferenca = 0;
  for (var i = 0; i < a.length; i++) {
    diferenca |= a[i] ^ b[i];
  }
  return diferenca == 0;
}
