import 'package:jetboat/domain/conta/resultados.dart';

export 'package:jetboat/domain/conta/perfil.dart';
export 'package:jetboat/domain/conta/resultados.dart';

/// Contrato de autenticação: o que as telas podem pedir sobre conta e sessão.
///
/// As telas só conhecem esta interface (regra 1 do `ARQUITETURA_C4.md`). Implementação atual:
/// `AutenticacaoLocal` (`lib/data/auth/`), que emite e confere os tokens no próprio aparelho.
/// No alvo, `AutenticacaoApi` passa a implementar esta interface chamando a API, e as telas não mudam.
abstract interface class Autenticacao {
  /// Confere e-mail e senha. Erra de forma genérica (não revela se o e-mail existe) e bloqueia
  /// o e-mail por um tempo depois de várias senhas erradas.
  Future<ResultadoLogin> entrar(String email, String senha);

  /// Cadastra uma conta nova e, se der certo, **já inicia a sessão** (quem se cadastra entra logado).
  /// Cada CPF e cada e-mail só podem ser cadastrados uma vez ([CpfJaCadastrado], [EmailJaCadastrado]).
  Future<ResultadoCadastro> cadastrar({
    required String nome,
    required String cpf,
    required String dataNascimento,
    required String telefone,
    required String email,
    required String senha,
  });

  /// Sessão válida no momento (renovando o acesso vencido, se possível); `null` = deslogado.
  Future<Sessao?> sessaoAtual();

  Future<void> sair();
}
