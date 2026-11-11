import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jetboat/data/auth/armazenamento_seguro.dart';
import 'package:jetboat/data/auth/assinador.dart';
import 'package:jetboat/data/auth/autenticacao_local.dart';
import 'package:jetboat/domain/conta/autenticacao.dart';
import 'package:jetboat/data/auth/jwt.dart';
import 'package:jetboat/data/auth/sessao_armazenamento.dart';
import 'package:jetboat/data/repositorio_usuarios_arquivo.dart';

void main() {
  late Directory pasta;
  late SessaoArmazenamento armazenamento;
  late AutenticacaoLocal auth;
  late Perfil maria;
  var agora = 0;

  setUp(() async {
    agora = 1800000000000;
    pasta = Directory.systemTemp.createTempSync('jetboat_auth_');
    final usuarios = RepositorioUsuariosArquivo(File('${pasta.path}/usuarios.json'));
    maria = (await usuarios.cadastrar(
      nome: 'Maria da Silva',
      cpf: '52998224725',
      dataNascimento: '15/03/1990',
      telefone: '11987654321',
      email: 'maria@email.com',
      senha: 'Barco2026',
    ) as CadastroSucesso)
        .perfil;
    armazenamento = SessaoArmazenamento(ArmazenamentoEmMemoria());
    auth = AutenticacaoLocal(
      usuarios: usuarios,
      jwt: Jwt(AssinadorHmac(utf8.encode('chave-de-teste-com-32-bytes-ok!!'))),
      armazenamento: armazenamento,
      relogio: () => agora,
    );
  });

  tearDown(() => pasta.deleteSync(recursive: true));

  test('login correto cria sessão com tokens', () async {
    final resultado = await auth.entrar('  MARIA@email.com ', 'Barco2026');
    expect(resultado, isA<LoginSucesso>());
    final sessao = (resultado as LoginSucesso).sessao;
    expect(sessao.perfil.id, maria.id);
    expect(sessao.expiraEm, agora + const Duration(minutes: 15).inMilliseconds);
    expect(await armazenamento.tokenAcesso, isNotNull);
    expect(await armazenamento.tokenRenovacao, isNotNull);
    expect((await auth.sessaoAtual())?.perfil.id, maria.id);
  });

  test('senha errada ou e-mail inexistente dão o mesmo erro', () async {
    expect(await auth.entrar('maria@email.com', 'errada123'), const CredenciaisInvalidas(4));
    expect(await auth.entrar('ninguem@email.com', 'Barco2026'), const CredenciaisInvalidas(4));
    expect(await auth.sessaoAtual(), isNull);
  });

  test('bloqueia após cinco erros e libera depois', () async {
    for (var i = 0; i < 4; i++) {
      await auth.entrar('maria@email.com', 'errada123');
    }
    expect(await auth.entrar('maria@email.com', 'errada123'), const LoginBloqueado(30));
    // Mesmo com a senha certa, continua bloqueado
    expect(await auth.entrar('maria@email.com', 'Barco2026'), isA<LoginBloqueado>());

    agora += const Duration(seconds: 31).inMilliseconds;
    expect(await auth.entrar('maria@email.com', 'Barco2026'), isA<LoginSucesso>());
  });

  test('token de acesso vencido é renovado com rotação', () async {
    await auth.entrar('maria@email.com', 'Barco2026');
    final acessoAntigo = await armazenamento.tokenAcesso;
    final renovacaoAntiga = await armazenamento.tokenRenovacao;

    agora += const Duration(minutes: 16).inMilliseconds;
    final sessao = await auth.sessaoAtual();

    expect(sessao, isNotNull);
    expect(await armazenamento.tokenAcesso, isNot(acessoAntigo));
    expect(await armazenamento.tokenRenovacao, isNot(renovacaoAntiga));
    expect(sessao!.expiraEm, agora + const Duration(minutes: 15).inMilliseconds);
  });

  test('sessão expira quando a renovação também vence', () async {
    await auth.entrar('maria@email.com', 'Barco2026');
    agora += const Duration(days: 8).inMilliseconds;
    expect(await auth.sessaoAtual(), isNull);
    expect(await armazenamento.tokenAcesso, isNull);
    expect(await armazenamento.tokenRenovacao, isNull);
  });

  test('token adulterado encerra a sessão', () async {
    await auth.entrar('maria@email.com', 'Barco2026');
    await armazenamento.salvar('${await armazenamento.tokenAcesso}x', (await armazenamento.tokenRenovacao)!);
    expect(await auth.sessaoAtual(), isNull);
    expect(await armazenamento.tokenRenovacao, isNull);
  });

  test('sair apaga os tokens', () async {
    await auth.entrar('maria@email.com', 'Barco2026');
    await auth.sair();
    expect(await auth.sessaoAtual(), isNull);
    expect(await armazenamento.tokenAcesso, isNull);
  });

  Future<ResultadoCadastro> cadastrar({String cpf = '11144477735', String email = 'joao@email.com'}) =>
      auth.cadastrar(
        nome: 'João Souza',
        cpf: cpf,
        dataNascimento: '01/01/1980',
        telefone: '11912345678',
        email: email,
        senha: 'Remo2026',
      );

  test('cadastrar cadastra e já inicia a sessão', () async {
    expect(await cadastrar(), isA<CadastroSucesso>());
    expect((await auth.sessaoAtual())?.perfil.email, 'joao@email.com');
    expect(await auth.entrar('joao@email.com', 'Remo2026'), isA<LoginSucesso>());
  });

  test('cadastrar com CPF ou e-mail repetido não abre sessão', () async {
    expect(await cadastrar(cpf: '52998224725'), isA<CpfJaCadastrado>()); // CPF da Maria
    expect(await cadastrar(email: 'MARIA@email.com'), isA<EmailJaCadastrado>());
    expect(await auth.sessaoAtual(), isNull);
  });
}
