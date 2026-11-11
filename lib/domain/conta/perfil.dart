/// Dados de uma conta como o resto do app os vê: **sem hash nem salt de senha**.
/// CPF e telefone só com dígitos; data de nascimento no formato dd/MM/aaaa.
class Perfil {
  const Perfil({
    required this.id,
    required this.nome,
    required this.cpf,
    required this.dataNascimento,
    required this.telefone,
    required this.email,
  });

  final String id;
  final String nome;
  final String cpf;
  final String dataNascimento;
  final String telefone;
  final String email;

  String get primeiroNome => nome.trim().split(' ').first;
}
