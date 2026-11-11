import 'package:jetboat/domain/conta/autenticacao.dart';

/// [Autenticacao] falsa para os testes de tela (item B7 do `ARQUITETURA_C4.md`).
///
/// Responde na hora, sem arquivo, hash ou JWT, e registra as chamadas. Cada teste pode forçar a
/// resposta com [respostaLogin] e [respostaCadastro] para ver como a tela reage. As regras de verdade
/// (CPF e e-mail únicos, bloqueio por tentativas, tokens) são testadas na camada `data`.
class AutenticacaoFalsa implements Autenticacao {
  AutenticacaoFalsa({Map<String, String> contas = const {}}) : _senhas = {...contas};

  /// E-mail → senha das contas que aceitam login quando [respostaLogin] é `null`.
  final Map<String, String> _senhas;

  /// Se definida, é devolvida por [entrar] em vez de conferir e-mail e senha.
  ResultadoLogin? respostaLogin;

  /// Se definida, é devolvida por [cadastrar] em vez de criar a conta.
  ResultadoCadastro? respostaCadastro;

  int chamadasEntrar = 0;
  int chamadasCadastrar = 0;
  ({String nome, String cpf, String dataNascimento, String telefone, String email, String senha})? ultimoCadastro;
  Sessao? _sessao;

  static Perfil perfilDe(String email, {String nome = 'Maria da Silva'}) => Perfil(
        id: 'id-$email',
        nome: nome,
        cpf: '52998224725',
        dataNascimento: '15/03/1990',
        telefone: '11987654321',
        email: email,
      );

  @override
  Future<ResultadoLogin> entrar(String email, String senha) async {
    chamadasEntrar++;
    final forcada = respostaLogin;
    if (forcada != null) return forcada;
    if (_senhas[email.trim().toLowerCase()] != senha) return const CredenciaisInvalidas(4);
    _sessao = Sessao(perfilDe(email.trim().toLowerCase()), 'token-falso', 0);
    return LoginSucesso(_sessao!);
  }

  @override
  Future<ResultadoCadastro> cadastrar({
    required String nome,
    required String cpf,
    required String dataNascimento,
    required String telefone,
    required String email,
    required String senha,
  }) async {
    chamadasCadastrar++;
    ultimoCadastro = (nome: nome, cpf: cpf, dataNascimento: dataNascimento, telefone: telefone, email: email, senha: senha);
    final forcada = respostaCadastro;
    if (forcada != null) return forcada;
    final perfil = Perfil(
      id: 'id-$email',
      nome: nome,
      cpf: cpf,
      dataNascimento: dataNascimento,
      telefone: telefone,
      email: email,
    );
    _sessao = Sessao(perfil, 'token-falso', 0); // como no contrato: quem se cadastra já entra logado
    return CadastroSucesso(perfil);
  }

  @override
  Future<Sessao?> sessaoAtual() async => _sessao;

  @override
  Future<void> sair() async => _sessao = null;
}
