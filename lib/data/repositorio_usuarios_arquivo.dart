import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:jetboat/data/fila.dart';
import 'package:jetboat/data/repositorio_usuarios.dart';
import 'package:jetboat/data/senha.dart';
import 'package:jetboat/data/usuario.dart';
import 'package:jetboat/domain/conta/resultados.dart';
import 'package:jetboat/domain/conta/validador_cadastro.dart' show normalizarCpf, normalizarEmail;

/// Implementação de [RepositorioUsuarios] com um arquivo JSON no armazenamento interno do app
/// (`files/usuarios.json` no Android — o mesmo arquivo da versão Kotlin anterior).
///
/// É o "banco de dados" provisório, enquanto não existe uma API.
class RepositorioUsuariosArquivo implements RepositorioUsuarios {
  RepositorioUsuariosArquivo(this.arquivo);

  static const nomeArquivo = 'usuarios.json';

  final File arquivo;
  final _fila = Fila();

  @override
  Future<List<Usuario>> listar() => _fila.executar(_ler);

  @override
  Future<Usuario?> buscarPorEmail(String email) async {
    final normalizado = normalizarEmail(email);
    return (await listar()).where((u) => normalizarEmail(u.email) == normalizado).firstOrNull;
  }

  @override
  Future<Usuario?> buscarPorId(String id) async => (await listar()).where((u) => u.id == id).firstOrNull;

  @override
  Future<ResultadoCadastro> cadastrar({
    required String nome,
    required String cpf,
    required String dataNascimento,
    required String telefone,
    required String email,
    required String senha,
  }) =>
      _fila.executar(() async {
        final usuarios = await _ler();
        final emailNormalizado = normalizarEmail(email);
        final cpfNormalizado = normalizarCpf(cpf);

        // Cada CPF e cada e-mail só podem ser cadastrados uma vez. Os dois lados são normalizados,
        // para que nem maiúsculas, espaços ou pontuação deixem passar um duplicado.
        if (usuarios.any((u) => normalizarCpf(u.cpf) == cpfNormalizado)) return const CpfJaCadastrado();
        if (usuarios.any((u) => normalizarEmail(u.email) == emailNormalizado)) return const EmailJaCadastrado();

        final hash = await Senha.gerarHash(senha);
        final novo = Usuario(
          id: _uuidV4(),
          nome: nome.trim().replaceAll(RegExp(r'\s+'), ' '),
          cpf: cpfNormalizado,
          dataNascimento: dataNascimento,
          telefone: telefone,
          email: emailNormalizado,
          senhaHash: hash.hash,
          senhaSalt: hash.salt,
          criadoEm: DateTime.now().millisecondsSinceEpoch,
        );
        await _salvar([...usuarios, novo]);
        return CadastroSucesso(novo.perfil);
      });

  Future<List<Usuario>> _ler() async {
    if (!await arquivo.exists()) return [];
    final texto = await arquivo.readAsString();
    if (texto.trim().isEmpty) return [];
    final lista = (jsonDecode(texto) as Map<String, dynamic>)['usuarios'] as List<dynamic>?;
    return [for (final u in lista ?? const []) Usuario.fromJson(u as Map<String, dynamic>)];
  }

  /// Escreve em um arquivo temporário e depois renomeia, para não corromper os dados se o app fechar no meio.
  Future<void> _salvar(List<Usuario> usuarios) async {
    final json = const JsonEncoder.withIndent('  ').convert({'usuarios': [for (final u in usuarios) u.toJson()]});
    await arquivo.parent.create(recursive: true);
    final temporario = File('${arquivo.path}.tmp');
    await temporario.writeAsString(json, flush: true);
    await temporario.rename(arquivo.path);
  }

  static String _uuidV4() {
    final r = Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }
}
