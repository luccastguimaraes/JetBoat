import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'package:jetboat/data/auth/armazenamento_seguro.dart';

/// Calcula a assinatura HMAC-SHA256 usada no JWT.
abstract interface class Assinador {
  List<int> assinar(List<int> dados);
}

/// Assina com uma chave HMAC de 256 bits.
class AssinadorHmac implements Assinador {
  AssinadorHmac(List<int> chave) : _hmac = Hmac(sha256, chave);

  final Hmac _hmac;

  @override
  List<int> assinar(List<int> dados) => _hmac.convert(dados).bytes;

  static const _chaveArmazenamento = 'jetboat_jwt_hmac';

  /// Carrega a chave do armazenamento seguro, gerando uma nova (aleatória) no primeiro uso.
  ///
  /// No Android, o armazenamento seguro criptografa a chave com uma chave mestra do
  /// Android Keystore (no iOS, fica no Keychain). Sem ela, ninguém consegue forjar um token
  /// editando os arquivos do app.
  static Future<AssinadorHmac> carregar(ArmazenamentoSeguro armazenamento) async {
    var chave = await armazenamento.ler(_chaveArmazenamento);
    if (chave == null) {
      final r = Random.secure();
      chave = base64.encode(List.generate(32, (_) => r.nextInt(256)));
      await armazenamento.gravar(_chaveArmazenamento, chave);
    }
    return AssinadorHmac(base64.decode(chave));
  }
}
