import 'package:jetboat/domain/conta/perfil.dart';

/// Sessão autenticada. [expiraEm] em milissegundos: validade do token de acesso atual.
class Sessao {
  const Sessao(this.perfil, this.tokenAcesso, this.expiraEm);
  final Perfil perfil;
  final String tokenAcesso;
  final int expiraEm;
}

sealed class ResultadoLogin {
  const ResultadoLogin();
}

final class LoginSucesso extends ResultadoLogin {
  const LoginSucesso(this.sessao);
  final Sessao sessao;
}

final class CredenciaisInvalidas extends ResultadoLogin {
  const CredenciaisInvalidas(this.tentativasRestantes);
  final int tentativasRestantes;

  @override
  bool operator ==(Object other) => other is CredenciaisInvalidas && other.tentativasRestantes == tentativasRestantes;

  @override
  int get hashCode => tentativasRestantes.hashCode;
}

final class LoginBloqueado extends ResultadoLogin {
  const LoginBloqueado(this.segundosRestantes);
  final int segundosRestantes;

  @override
  bool operator ==(Object other) => other is LoginBloqueado && other.segundosRestantes == segundosRestantes;

  @override
  int get hashCode => segundosRestantes.hashCode;
}

sealed class ResultadoCadastro {
  const ResultadoCadastro();
}

final class CadastroSucesso extends ResultadoCadastro {
  const CadastroSucesso(this.perfil);
  final Perfil perfil;
}

final class CpfJaCadastrado extends ResultadoCadastro {
  const CpfJaCadastrado();
}

final class EmailJaCadastrado extends ResultadoCadastro {
  const EmailJaCadastrado();
}
