import 'dart:async';

/// Executa operações assíncronas uma de cada vez, na ordem de chegada
/// (o equivalente ao `@Synchronized` da versão Kotlin).
class Fila {
  Future<void> _ultima = Future.value();

  Future<T> executar<T>(Future<T> Function() operacao) {
    final resultado = _ultima.then((_) => operacao());
    _ultima = resultado.then((_) {}, onError: (_) {});
    return resultado;
  }
}
