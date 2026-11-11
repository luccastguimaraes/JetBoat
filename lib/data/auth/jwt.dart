import 'dart:convert';

import 'package:jetboat/data/senha.dart' show iguaisEmTempoConstante;
import 'package:jetboat/data/auth/assinador.dart';

/// Valores da claim `token_use`: separa token de acesso de token de renovação.
abstract final class TipoToken {
  static const acesso = 'access';
  static const renovacao = 'refresh';
}

/// Claims registradas de um JWT (RFC 7519). Datas em segundos desde a época (NumericDate).
class ClaimsJwt {
  const ClaimsJwt({
    required this.sujeito,
    required this.email,
    required this.tipo,
    required this.emitidoEm,
    required this.expiraEm,
    required this.id,
    this.emissor = ClaimsJwt.emissorPadrao,
  });

  static const emissorPadrao = 'jetboat';

  final String sujeito; // sub: id do usuário
  final String email;
  final String tipo; // token_use
  final int emitidoEm; // iat
  final int expiraEm; // exp
  final String id; // jti
  final String emissor; // iss

  @override
  bool operator ==(Object other) =>
      other is ClaimsJwt &&
      other.sujeito == sujeito &&
      other.email == email &&
      other.tipo == tipo &&
      other.emitidoEm == emitidoEm &&
      other.expiraEm == expiraEm &&
      other.id == id &&
      other.emissor == emissor;

  @override
  int get hashCode => Object.hash(sujeito, email, tipo, emitidoEm, expiraEm, id, emissor);
}

sealed class Validacao {
  const Validacao();
}

final class TokenValido extends Validacao {
  const TokenValido(this.claims);
  final ClaimsJwt claims;

  @override
  bool operator ==(Object other) => other is TokenValido && other.claims == claims;

  @override
  int get hashCode => claims.hashCode;
}

final class TokenExpirado extends Validacao {
  const TokenExpirado();
}

final class TokenInvalido extends Validacao {
  const TokenInvalido();
}

/// Geração e validação de JWT no formato compacto `header.payload.assinatura`, algoritmo HS256.
///
/// A validação:
///  - aceita apenas `alg = HS256` (bloqueia o ataque do `alg: none` e troca de algoritmo);
///  - confere a assinatura em tempo constante;
///  - confere emissor, tipo do token, `exp` e `iat`.
///
/// Quando o app tiver uma API própria, a emissão passa para o servidor e o app só guarda os tokens.
class Jwt {
  const Jwt(this._assinador);

  static const _algoritmo = 'HS256';
  static const _toleranciaRelogioSeg = 60;

  final Assinador _assinador;

  String gerar(ClaimsJwt c) {
    final header = {'alg': _algoritmo, 'typ': 'JWT'};
    final payload = {
      'iss': c.emissor,
      'sub': c.sujeito,
      'email': c.email,
      'token_use': c.tipo,
      'iat': c.emitidoEm,
      'exp': c.expiraEm,
      'jti': c.id,
    };
    final conteudo = '${_b64(utf8.encode(jsonEncode(header)))}.${_b64(utf8.encode(jsonEncode(payload)))}';
    return '$conteudo.${_b64(_assinador.assinar(utf8.encode(conteudo)))}';
  }

  /// [agoraSeg] em segundos. [tipoEsperado] é um dos valores de [TipoToken].
  Validacao validar(String token, String tipoEsperado, int agoraSeg) {
    try {
      final partes = token.split('.');
      if (partes.length != 3) return const TokenInvalido();

      final header = jsonDecode(utf8.decode(_deB64(partes[0]))) as Map<String, dynamic>;
      if (header['alg'] != _algoritmo) return const TokenInvalido();

      final esperada = _assinador.assinar(utf8.encode('${partes[0]}.${partes[1]}'));
      if (!iguaisEmTempoConstante(esperada, _deB64(partes[2]))) return const TokenInvalido();

      final p = jsonDecode(utf8.decode(_deB64(partes[1]))) as Map<String, dynamic>;
      final claims = ClaimsJwt(
        sujeito: p['sub'] as String,
        email: p['email'] as String,
        tipo: p['token_use'] as String,
        emitidoEm: (p['iat'] as num).toInt(),
        expiraEm: (p['exp'] as num).toInt(),
        id: p['jti'] as String,
        emissor: p['iss'] as String,
      );
      if (claims.emissor != ClaimsJwt.emissorPadrao) return const TokenInvalido();
      if (claims.tipo != tipoEsperado) return const TokenInvalido();
      if (claims.emitidoEm > agoraSeg + _toleranciaRelogioSeg) return const TokenInvalido(); // emitido "no futuro"
      if (agoraSeg >= claims.expiraEm) return const TokenExpirado();
      return TokenValido(claims);
    } catch (_) {
      return const TokenInvalido(); // token malformado: base64/JSON quebrado, claim ausente etc.
    }
  }

  static String _b64(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

  static List<int> _deB64(String texto) => base64Url.decode(base64Url.normalize(texto));
}
