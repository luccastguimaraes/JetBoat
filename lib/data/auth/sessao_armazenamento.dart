import 'package:jetboat/data/auth/armazenamento_seguro.dart';

/// Guarda o par de tokens da sessão no armazenamento seguro (criptografado).
/// Os tokens também são assinados, então qualquer alteração invalida a sessão.
class SessaoArmazenamento {
  SessaoArmazenamento(this._armazenamento);

  static const _chaveAcesso = 'token_acesso';
  static const _chaveRenovacao = 'token_renovacao';

  final ArmazenamentoSeguro _armazenamento;

  Future<String?> get tokenAcesso => _armazenamento.ler(_chaveAcesso);
  Future<String?> get tokenRenovacao => _armazenamento.ler(_chaveRenovacao);

  Future<void> salvar(String tokenAcesso, String tokenRenovacao) async {
    await _armazenamento.gravar(_chaveAcesso, tokenAcesso);
    await _armazenamento.gravar(_chaveRenovacao, tokenRenovacao);
  }

  Future<void> limpar() async {
    await _armazenamento.apagar(_chaveAcesso);
    await _armazenamento.apagar(_chaveRenovacao);
  }
}
