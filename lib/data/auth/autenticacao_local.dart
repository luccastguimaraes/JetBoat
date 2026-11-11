import 'dart:math';

import 'package:jetboat/data/fila.dart';
import 'package:jetboat/data/repositorio_usuarios.dart';
import 'package:jetboat/domain/conta/validador_cadastro.dart' show normalizarEmail;
import 'package:jetboat/data/senha.dart';
import 'package:jetboat/data/auth/jwt.dart';
import 'package:jetboat/domain/conta/autenticacao.dart';
import 'package:jetboat/data/auth/sessao_armazenamento.dart';

/// Implementação de [Autenticacao] que roda inteira no aparelho, com o padrão
/// "access token + refresh token":
///  - token de acesso curto ([validadeAcesso], 15 min): é o que provaria a identidade para uma API;
///  - token de renovação longo ([validadeRenovacao], 7 dias): troca o acesso vencido por um novo,
///    e é rotacionado a cada uso (janela deslizante). Se ele também vencer, o usuário volta ao login.
///
/// Também limita tentativas: após [maxTentativas] senhas erradas o e-mail fica bloqueado por [bloqueio].
///
/// Provisória: num sistema com servidor, a emissão dos tokens é do servidor.
class AutenticacaoLocal implements Autenticacao {
  AutenticacaoLocal({
    required this._usuarios,
    required this._jwt,
    required this._armazenamento,
    int Function()? relogio,
    this.validadeAcesso = const Duration(minutes: 15),
    this.validadeRenovacao = const Duration(days: 7),
  }) : _relogio = relogio ?? (() => DateTime.now().millisecondsSinceEpoch);

  static const maxTentativas = 5;
  static const bloqueio = Duration(seconds: 30);

  final RepositorioUsuarios _usuarios;
  final Jwt _jwt;
  final SessaoArmazenamento _armazenamento;
  final int Function() _relogio;
  final Duration validadeAcesso;
  final Duration validadeRenovacao;

  final _fila = Fila();
  final _falhas = <String, int>{};
  final _bloqueadoAte = <String, int>{};

  @override
  Future<ResultadoLogin> entrar(String email, String senha) => _fila.executar(() async {
        final chave = normalizarEmail(email);
        final agora = _relogio();

        final ate = _bloqueadoAte[chave];
        if (ate != null) {
          if (agora < ate) return LoginBloqueado(_segundosAte(ate, agora));
          _bloqueadoAte.remove(chave);
        }

        final usuario = await _usuarios.buscarPorEmail(chave);
        final bool senhaConfere;
        if (usuario != null) {
          senhaConfere = await Senha.confere(senha, usuario.senhaHash, usuario.senhaSalt);
        } else {
          // Gasta o mesmo tempo de um hash real, para não revelar pelo tempo de resposta
          // se o e-mail existe ou não.
          await Senha.gerarHash(senha);
          senhaConfere = false;
        }

        if (usuario == null || !senhaConfere) {
          final tentativas = (_falhas[chave] ?? 0) + 1;
          if (tentativas >= maxTentativas) {
            _falhas.remove(chave);
            final fim = agora + bloqueio.inMilliseconds;
            _bloqueadoAte[chave] = fim;
            return LoginBloqueado(_segundosAte(fim, agora));
          }
          _falhas[chave] = tentativas;
          return CredenciaisInvalidas(maxTentativas - tentativas);
        }

        _falhas.remove(chave);
        return LoginSucesso(await _iniciarSessao(usuario.perfil));
      });

  @override
  Future<ResultadoCadastro> cadastrar({
    required String nome,
    required String cpf,
    required String dataNascimento,
    required String telefone,
    required String email,
    required String senha,
  }) async {
    final resultado = await _usuarios.cadastrar(
      nome: nome,
      cpf: cpf,
      dataNascimento: dataNascimento,
      telefone: telefone,
      email: email,
      senha: senha,
    );
    if (resultado is CadastroSucesso) {
      await _fila.executar(() => _iniciarSessao(resultado.perfil)); // quem se cadastra já entra logado
    }
    return resultado;
  }

  @override
  Future<Sessao?> sessaoAtual() => _fila.executar(() async {
        final acesso = await _armazenamento.tokenAcesso;
        if (acesso == null) return null;
        switch (_jwt.validar(acesso, TipoToken.acesso, _agoraSeg())) {
          case TokenValido(:final claims):
            final usuario = await _usuarios.buscarPorId(claims.sujeito);
            if (usuario == null) return _encerrar();
            return Sessao(usuario.perfil, acesso, claims.expiraEm * 1000);
          case TokenExpirado():
            return _renovar();
          case TokenInvalido():
            return _encerrar();
        }
      });

  @override
  Future<void> sair() => _fila.executar(_armazenamento.limpar);

  Future<Sessao?> _renovar() async {
    final token = await _armazenamento.tokenRenovacao;
    if (token == null) return _encerrar();
    final v = _jwt.validar(token, TipoToken.renovacao, _agoraSeg());
    if (v is! TokenValido) return _encerrar();
    final usuario = await _usuarios.buscarPorId(v.claims.sujeito);
    if (usuario == null) return _encerrar();
    return _iniciarSessao(usuario.perfil); // rotação: o token de renovação antigo é substituído
  }

  /// Emite um novo par de tokens para [perfil] e o guarda.
  Future<Sessao> _iniciarSessao(Perfil perfil) async {
    final agora = _relogio();
    final acesso = _emitir(perfil, TipoToken.acesso, agora, validadeAcesso);
    final renovacao = _emitir(perfil, TipoToken.renovacao, agora, validadeRenovacao);
    await _armazenamento.salvar(acesso, renovacao);
    return Sessao(perfil, acesso, agora + validadeAcesso.inMilliseconds);
  }

  Future<Sessao?> _encerrar() async {
    await _armazenamento.limpar();
    return null;
  }

  String _emitir(Perfil perfil, String tipo, int agoraMs, Duration validade) {
    final iat = agoraMs ~/ 1000;
    return _jwt.gerar(ClaimsJwt(
      sujeito: perfil.id,
      email: perfil.email,
      tipo: tipo,
      emitidoEm: iat,
      expiraEm: iat + validade.inSeconds,
      id: _idAleatorio(),
    ));
  }

  int _agoraSeg() => _relogio() ~/ 1000;

  static int _segundosAte(int ate, int agora) => (ate - agora + 999) ~/ 1000;

  static String _idAleatorio() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }
}
