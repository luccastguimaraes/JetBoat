import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Chave-valor criptografado. Abstrai o `flutter_secure_storage` para permitir testes sem aparelho.
abstract interface class ArmazenamentoSeguro {
  Future<String?> ler(String chave);
  Future<void> gravar(String chave, String valor);
  Future<void> apagar(String chave);
}

/// Implementação real: Android Keystore (Android) / Keychain (iOS).
class ArmazenamentoSeguroDispositivo implements ArmazenamentoSeguro {
  ArmazenamentoSeguroDispositivo([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> ler(String chave) => _storage.read(key: chave);

  @override
  Future<void> gravar(String chave, String valor) => _storage.write(key: chave, value: valor);

  @override
  Future<void> apagar(String chave) => _storage.delete(key: chave);
}

/// Implementação em memória, para testes.
class ArmazenamentoEmMemoria implements ArmazenamentoSeguro {
  final valores = <String, String>{};

  @override
  Future<String?> ler(String chave) async => valores[chave];

  @override
  Future<void> gravar(String chave, String valor) async => valores[chave] = valor;

  @override
  Future<void> apagar(String chave) async => valores.remove(chave);
}
