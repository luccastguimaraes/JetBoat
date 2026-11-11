import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jetboat/data/auth/armazenamento_seguro.dart';
import 'package:jetboat/data/auth/assinador.dart';
import 'package:jetboat/data/auth/jwt.dart';

void main() {
  final jwt = Jwt(AssinadorHmac(utf8.encode('chave-de-teste-com-32-bytes-ok!!')));
  const agora = 1800000000;

  ClaimsJwt claims({String tipo = TipoToken.acesso, int exp = agora + 900}) =>
      ClaimsJwt(sujeito: 'u1', email: 'maria@email.com', tipo: tipo, emitidoEm: agora, expiraEm: exp, id: 'j1');

  String b64(String texto) => base64Url.encode(utf8.encode(texto)).replaceAll('=', '');

  test('gera token no formato compacto e valida', () {
    final token = jwt.gerar(claims());
    expect(token.split('.'), hasLength(3));
    expect(jwt.validar(token, TipoToken.acesso, agora), TokenValido(claims()));
  });

  test('token vencido é expirado', () {
    final token = jwt.gerar(claims(exp: agora + 900));
    expect(jwt.validar(token, TipoToken.acesso, agora + 900), isA<TokenExpirado>());
  });

  test('recusa tipo errado', () {
    final renovacao = jwt.gerar(claims(tipo: TipoToken.renovacao));
    expect(jwt.validar(renovacao, TipoToken.acesso, agora), isA<TokenInvalido>());
  });

  test('recusa payload alterado', () {
    final [h, _, s] = jwt.gerar(claims()).split('.');
    final forjado = b64('{"iss":"jetboat","sub":"admin","email":"x@x.com","token_use":"access",'
        '"iat":$agora,"exp":${agora + 99999},"jti":"j"}');
    expect(jwt.validar('$h.$forjado.$s', TipoToken.acesso, agora), isA<TokenInvalido>());
  });

  test('recusa alg none', () {
    final [_, p, _] = jwt.gerar(claims()).split('.');
    final headerNone = b64('{"alg":"none","typ":"JWT"}');
    expect(jwt.validar('$headerNone.$p.', TipoToken.acesso, agora), isA<TokenInvalido>());
  });

  test('recusa assinatura de outra chave', () {
    final outro = Jwt(AssinadorHmac(utf8.encode('outra-chave-qualquer-de-32-bytes')));
    expect(jwt.validar(outro.gerar(claims()), TipoToken.acesso, agora), isA<TokenInvalido>());
  });

  test('recusa lixo', () {
    for (final lixo in ['', 'abc', 'a.b.c', '...']) {
      expect(jwt.validar(lixo, TipoToken.acesso, agora), isA<TokenInvalido>());
    }
  });

  test('chave do armazenamento seguro é gerada uma vez e reaproveitada', () async {
    final armazenamento = ArmazenamentoEmMemoria();
    final primeiro = Jwt(await AssinadorHmac.carregar(armazenamento));
    final token = primeiro.gerar(claims());
    final segundo = Jwt(await AssinadorHmac.carregar(armazenamento));
    expect(segundo.validar(token, TipoToken.acesso, agora), isA<TokenValido>());
    expect(base64.decode(armazenamento.valores['jetboat_jwt_hmac']!), hasLength(32));
  });
}
