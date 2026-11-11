import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jetboat/data/senha.dart';
import 'package:jetboat/domain/conta/resultados.dart';
import 'package:jetboat/data/repositorio_usuarios_arquivo.dart';

void main() {
  late Directory pasta;
  late File arquivo;
  late RepositorioUsuariosArquivo repositorio;

  setUp(() {
    pasta = Directory.systemTemp.createTempSync('jetboat_repo_');
    arquivo = File('${pasta.path}/usuarios.json');
    repositorio = RepositorioUsuariosArquivo(arquivo);
  });

  tearDown(() => pasta.deleteSync(recursive: true));

  Future<ResultadoCadastro> cadastrarMaria({String cpf = '52998224725', String email = 'Maria@Email.com'}) =>
      repositorio.cadastrar(
        nome: 'Maria  da Silva',
        cpf: cpf,
        dataNascimento: '15/03/1990',
        telefone: '11987654321',
        email: email,
        senha: 'Barco2026',
      );

  test('cadastra e salva no arquivo', () async {
    expect(await cadastrarMaria(), isA<CadastroSucesso>());

    // Uma nova instância lê o mesmo arquivo: os dados persistem
    final usuarios = await RepositorioUsuariosArquivo(arquivo).listar();
    expect(usuarios, hasLength(1));
    expect(usuarios[0].nome, 'Maria da Silva');
    expect(usuarios[0].email, 'maria@email.com'); // e-mail normalizado
  });

  test('senha não fica em texto puro', () async {
    final perfil = (await cadastrarMaria() as CadastroSucesso).perfil;
    final usuario = (await repositorio.buscarPorId(perfil.id))!; // o hash só existe dentro da camada data
    expect(arquivo.readAsStringSync(), isNot(contains('Barco2026')));
    expect(await Senha.confere('Barco2026', usuario.senhaHash, usuario.senhaSalt), isTrue);
    expect(await Senha.confere('SenhaErrada1', usuario.senhaHash, usuario.senhaSalt), isFalse);
  });

  test('recusa CPF ou e-mail duplicado', () async {
    await cadastrarMaria();
    expect(await cadastrarMaria(email: 'outra@email.com'), isA<CpfJaCadastrado>());
    expect(await cadastrarMaria(cpf: '11144477735', email: 'MARIA@email.com'), isA<EmailJaCadastrado>());
    expect(await repositorio.listar(), hasLength(1));
  });

  test('CPF com pontuação conta como o mesmo CPF e é salvo só com dígitos', () async {
    final maria = (await cadastrarMaria(cpf: '529.982.247-25') as CadastroSucesso).perfil;
    expect(maria.cpf, '52998224725');
    expect(await cadastrarMaria(cpf: '52998224725', email: 'outra@email.com'), isA<CpfJaCadastrado>());
  });

  test('recusa duplicado mesmo quando o dado salvo está fora do padrão', () async {
    // Arquivo editado à mão: e-mail com maiúsculas e espaços, CPF com pontuação
    arquivo.writeAsStringSync('''
{"usuarios": [{"id": "1", "nome": "Maria da Silva", "cpf": "529.982.247-25", "dataNascimento": "15/03/1990",
"telefone": "11987654321", "email": " Maria@Email.COM ", "senhaHash": "x", "senhaSalt": "y", "criadoEm": 0}]}''');
    expect(await cadastrarMaria(email: 'nova@email.com'), isA<CpfJaCadastrado>());
    expect(await cadastrarMaria(cpf: '11144477735', email: 'maria@email.com'), isA<EmailJaCadastrado>());
    expect(await repositorio.buscarPorEmail('MARIA@email.com'), isNotNull);
    expect(await repositorio.listar(), hasLength(1));
  });

  test('cadastros simultâneos com o mesmo e-mail: só um entra', () async {
    final resultados = await Future.wait([
      cadastrarMaria(cpf: '52998224725'),
      cadastrarMaria(cpf: '11144477735'),
    ]);
    expect(resultados.whereType<CadastroSucesso>(), hasLength(1));
    expect(resultados.whereType<EmailJaCadastrado>(), hasLength(1));
    expect(await repositorio.listar(), hasLength(1));
  });

  test('lê o arquivo no formato gravado pela versão Kotlin', () async {
    arquivo.writeAsStringSync('''
{
  "usuarios": [
    {
      "id": "6f1c2a8e-2b1d-4c3e-9f00-1a2b3c4d5e6f",
      "nome": "Maria da Silva",
      "cpf": "52998224725",
      "dataNascimento": "15\\/03\\/1990",
      "telefone": "11987654321",
      "email": "maria@email.com",
      "senhaHash": "TiwhBKbhkKZp5OijiyB3enufKaI1xZE2zkDtVUxeD24=",
      "senhaSalt": "AwoRGB8mLTQ7QklQV15lbA==",
      "criadoEm": 1762790400000
    }
  ]
}''');
    final maria = (await repositorio.buscarPorEmail('MARIA@email.com'))!;
    expect(maria.dataNascimento, '15/03/1990');
    expect(await Senha.confere('Barco2026', maria.senhaHash, maria.senhaSalt), isTrue);
  });
}
