import 'package:jetboat/data/usuario.dart';
import 'package:jetboat/domain/conta/resultados.dart';

/// Onde as contas ficam guardadas. Uso **interno** da camada `data`: quem usa é a
/// `AutenticacaoLocal`. As telas não veem este contrato; veem só `Autenticacao`, do domínio.
///
/// Regras de qualquer implementação:
///  - cada CPF e cada e-mail só podem ser cadastrados uma vez (comparados com `normalizarCpf` e
///    `normalizarEmail`, do domínio, dos dois lados);
///  - a senha nunca é guardada, só o hash + salt (ver `Senha`).
///
/// Implementação atual: `RepositorioUsuariosArquivo` (arquivo JSON no aparelho). No alvo do
/// `ARQUITETURA_C4.md`, as contas passam a ficar na API (itens A1 e A5).
abstract interface class RepositorioUsuarios {
  Future<List<Usuario>> listar();

  Future<Usuario?> buscarPorEmail(String email);

  Future<Usuario?> buscarPorId(String id);

  Future<ResultadoCadastro> cadastrar({
    required String nome,
    required String cpf,
    required String dataNascimento,
    required String telefone,
    required String email,
    required String senha,
  });
}
