import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:jetboat/data/auth/armazenamento_seguro.dart';
import 'package:jetboat/data/auth/assinador.dart';
import 'package:jetboat/data/auth/autenticacao_local.dart';
import 'package:jetboat/data/auth/jwt.dart';
import 'package:jetboat/domain/conta/autenticacao.dart';
import 'package:jetboat/data/auth/sessao_armazenamento.dart';
import 'package:jetboat/data/repositorio_usuarios.dart';
import 'package:jetboat/data/repositorio_usuarios_arquivo.dart';

/// Raiz de composição: o **único lugar** do app que conhece as implementações.
/// Tudo o que sai daqui para as telas é contrato ([RepositorioUsuarios], [Autenticacao]).
///
/// Para trocar um contêiner (ex.: o arquivo local por uma API), muda-se só este arquivo.
class Dependencias {
  Dependencias({required this.repositorio, required this.autenticacao, required this.sessaoArmazenamento});

  final RepositorioUsuarios repositorio;
  final Autenticacao autenticacao;

  /// Exposto só para os testes de integração começarem deslogados.
  final SessaoArmazenamento sessaoArmazenamento;

  /// Versão real: arquivo no armazenamento interno + chave/tokens no armazenamento seguro.
  /// [arquivoUsuarios] permite aos testes usar outro arquivo sem tocar nos dados do app.
  static Future<Dependencias> criar({File? arquivoUsuarios}) async {
    final repositorio = RepositorioUsuariosArquivo(arquivoUsuarios ?? await arquivoUsuariosPadrao());
    final seguro = ArmazenamentoSeguroDispositivo();
    final sessao = SessaoArmazenamento(seguro);
    return Dependencias(
      repositorio: repositorio,
      sessaoArmazenamento: sessao,
      autenticacao: AutenticacaoLocal(
        usuarios: repositorio,
        jwt: Jwt(await AssinadorHmac.carregar(seguro)),
        armazenamento: sessao,
      ),
    );
  }
}

/// `files/usuarios.json` no Android — o mesmo arquivo que a versão Kotlin usava.
Future<File> arquivoUsuariosPadrao() async =>
    File('${(await getApplicationSupportDirectory()).path}/${RepositorioUsuariosArquivo.nomeArquivo}');
