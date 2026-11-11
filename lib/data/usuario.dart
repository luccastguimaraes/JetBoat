import 'package:jetboat/domain/conta/perfil.dart';

/// Registro de uma conta como fica guardado no arquivo, **com hash e salt da senha**.
/// Fica só na camada `data`: para o resto do app, use [perfil].
/// CPF e telefone são guardados só com dígitos; a data de nascimento no formato dd/MM/aaaa.
/// A senha NUNCA é guardada — apenas o hash + salt (ver `Senha`).
class Usuario {
  const Usuario({
    required this.id,
    required this.nome,
    required this.cpf,
    required this.dataNascimento,
    required this.telefone,
    required this.email,
    required this.senhaHash,
    required this.senhaSalt,
    required this.criadoEm,
  });

  final String id;
  final String nome;
  final String cpf;
  final String dataNascimento;
  final String telefone;
  final String email;
  final String senhaHash;
  final String senhaSalt;
  final int criadoEm; // milissegundos desde a época

  /// Os dados da conta sem hash nem salt, para sair da camada `data`.
  Perfil get perfil =>
      Perfil(id: id, nome: nome, cpf: cpf, dataNascimento: dataNascimento, telefone: telefone, email: email);

  Map<String, Object> toJson() => {
        'id': id,
        'nome': nome,
        'cpf': cpf,
        'dataNascimento': dataNascimento,
        'telefone': telefone,
        'email': email,
        'senhaHash': senhaHash,
        'senhaSalt': senhaSalt,
        'criadoEm': criadoEm,
      };

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as String,
        nome: json['nome'] as String,
        cpf: json['cpf'] as String,
        dataNascimento: json['dataNascimento'] as String,
        telefone: json['telefone'] as String,
        email: json['email'] as String,
        senhaHash: json['senhaHash'] as String,
        senhaSalt: json['senhaSalt'] as String,
        criadoEm: (json['criadoEm'] as num).toInt(),
      );
}
