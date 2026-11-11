/// Valores digitados no formulário (CPF, data e telefone só com dígitos).
class CamposCadastro {
  const CamposCadastro({
    this.nome = '',
    this.cpf = '',
    this.dataNascimento = '',
    this.telefone = '',
    this.email = '',
    this.senha = '',
    this.confirmacaoSenha = '',
    this.aceitouTermos = false,
  });

  final String nome;
  final String cpf;
  final String dataNascimento;
  final String telefone;
  final String email;
  final String senha;
  final String confirmacaoSenha;
  final bool aceitouTermos;
}

/// Mensagem de erro de cada campo; `null` = campo válido.
class ErrosCadastro {
  const ErrosCadastro({
    this.nome,
    this.cpf,
    this.dataNascimento,
    this.telefone,
    this.email,
    this.senha,
    this.confirmacaoSenha,
    this.termos,
  });

  final String? nome;
  final String? cpf;
  final String? dataNascimento;
  final String? telefone;
  final String? email;
  final String? senha;
  final String? confirmacaoSenha;
  final String? termos;

  bool get valido => [nome, cpf, dataNascimento, telefone, email, senha, confirmacaoSenha, termos].every((e) => e == null);

  static const _manter = Object();

  /// Cópia alterando campos; passe `null` para limpar o erro de um campo.
  ErrosCadastro copyWith({
    Object? nome = _manter,
    Object? cpf = _manter,
    Object? dataNascimento = _manter,
    Object? telefone = _manter,
    Object? email = _manter,
    Object? senha = _manter,
    Object? confirmacaoSenha = _manter,
    Object? termos = _manter,
  }) {
    String? v(Object? novo, String? atual) => identical(novo, _manter) ? atual : novo as String?;
    return ErrosCadastro(
      nome: v(nome, this.nome),
      cpf: v(cpf, this.cpf),
      dataNascimento: v(dataNascimento, this.dataNascimento),
      telefone: v(telefone, this.telefone),
      email: v(email, this.email),
      senha: v(senha, this.senha),
      confirmacaoSenha: v(confirmacaoSenha, this.confirmacaoSenha),
      termos: v(termos, this.termos),
    );
  }
}

/// Regras de validação do cadastro (Dart puro, testável sem aparelho).
abstract final class ValidadorCadastro {
  static const idadeMinima = 18;
  static final _regexEmail = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
  static final _letra = RegExp(r'\p{L}', unicode: true);
  static final _digito = RegExp(r'\p{Nd}', unicode: true);
  static final _digitosAscii = RegExp(r'^[0-9]+$');

  static ErrosCadastro validar(CamposCadastro c, {DateTime? hoje}) => ErrosCadastro(
        nome: nome(c.nome),
        cpf: cpf(c.cpf),
        dataNascimento: dataNascimento(c.dataNascimento, hoje: hoje),
        telefone: telefone(c.telefone),
        email: email(c.email),
        senha: senha(c.senha),
        confirmacaoSenha: confirmacaoSenha(c.senha, c.confirmacaoSenha),
        termos: c.aceitouTermos ? null : 'Aceite os termos para continuar',
      );

  static String? nome(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    bool parteValida(String p) => p.split('').every((ch) => _letra.hasMatch(ch) || ch == "'" || ch == '-');
    if (nome.trim().isEmpty) return 'Informe seu nome completo';
    if (!partes.every(parteValida)) return 'Use apenas letras';
    if (partes.length < 2) return 'Informe nome e sobrenome';
    return null;
  }

  static String? cpf(String digitos) {
    if (digitos.isEmpty) return 'Informe seu CPF';
    if (digitos.length != 11 || !_digitosAscii.hasMatch(digitos)) return 'CPF incompleto';
    if (digitos.split('').every((d) => d == digitos[0])) return 'CPF inválido';

    final n = digitos.codeUnits.map((c) => c - 48).toList();
    int digitoVerificador(int qtd) {
      var soma = 0;
      for (var i = 0; i < qtd; i++) {
        soma += n[i] * (qtd + 1 - i);
      }
      final resto = soma % 11;
      return resto < 2 ? 0 : 11 - resto;
    }

    return digitoVerificador(9) == n[9] && digitoVerificador(10) == n[10] ? null : 'CPF inválido';
  }

  /// [digitos] no formato ddMMaaaa.
  static String? dataNascimento(String digitos, {DateTime? hoje}) {
    if (digitos.isEmpty) return 'Informe sua data de nascimento';
    if (digitos.length != 8 || !_digitosAscii.hasMatch(digitos)) return 'Data incompleta';

    final dia = int.parse(digitos.substring(0, 2));
    final mes = int.parse(digitos.substring(2, 4));
    final ano = int.parse(digitos.substring(4, 8));
    if (mes < 1 || mes > 12 || ano < 1900 || dia < 1 || dia > _diasNoMes(mes, ano)) return 'Data inválida';

    final h = hoje ?? DateTime.now();
    var idade = h.year - ano;
    if (h.month < mes || (h.month == mes && h.day < dia)) idade--;

    if (idade < 0) return 'Data no futuro';
    if (idade < idadeMinima) return 'É preciso ter $idadeMinima anos ou mais';
    if (idade > 120) return 'Data inválida';
    return null;
  }

  static String? telefone(String digitos) {
    if (digitos.isEmpty) return 'Informe seu telefone';
    if (digitos.length < 10 || digitos.length > 11 || !_digitosAscii.hasMatch(digitos)) return 'Telefone incompleto';
    if (int.parse(digitos.substring(0, 2)) < 11) return 'DDD inválido';
    if (digitos.length == 11 && digitos[2] != '9') return 'Celular deve começar com 9';
    return null;
  }

  static String? email(String email) {
    if (email.trim().isEmpty) return 'Informe seu e-mail';
    if (!_regexEmail.hasMatch(email.trim())) return 'E-mail inválido';
    return null;
  }

  static String? senha(String senha) {
    if (senha.isEmpty) return 'Crie uma senha';
    if (senha.length < 8) return 'Mínimo de 8 caracteres';
    if (!_letra.hasMatch(senha) || !_digito.hasMatch(senha)) return 'Use letras e números';
    return null;
  }

  static String? confirmacaoSenha(String senha, String confirmacao) {
    if (confirmacao.isEmpty) return 'Confirme sua senha';
    if (senha != confirmacao) return 'As senhas não conferem';
    return null;
  }

  /// Força da senha de 0 a 4 (para a barrinha visual).
  static int forcaSenha(String senha) {
    if (senha.isEmpty) return 0;
    final chars = senha.split('');
    bool maiuscula(String c) => c != c.toLowerCase();
    bool minuscula(String c) => c != c.toUpperCase();
    var pontos = 0;
    if (senha.length >= 8) pontos++;
    if (chars.any(maiuscula) && chars.any(minuscula)) pontos++;
    if (_digito.hasMatch(senha)) pontos++;
    if (chars.any((c) => !_letra.hasMatch(c) && !_digito.hasMatch(c))) pontos++;
    return pontos;
  }

  static int _diasNoMes(int mes, int ano) => switch (mes) {
        2 => (ano % 4 == 0 && ano % 100 != 0) || ano % 400 == 0 ? 29 : 28,
        4 || 6 || 9 || 11 => 30,
        _ => 31,
      };
}

/// E-mail sem espaços nas pontas e em minúsculas: `" Maria@Email.com"` e `"maria@email.com"` são o mesmo.
String normalizarEmail(String email) => email.trim().toLowerCase();

/// Só os dígitos do CPF: `"529.982.247-25"` e `"52998224725"` são o mesmo.
String normalizarCpf(String cpf) => cpf.replaceAll(RegExp(r'[^0-9]'), '');
