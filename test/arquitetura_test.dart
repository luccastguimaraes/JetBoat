import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Teste de arquitetura: verifica as regras de dependência da seção 7 do `docs/ARQUITETURA_C4.md`
/// (e a seção 13.2 do `docs/DESIGN_SYSTEM.md`) lendo os imports de cada arquivo de `lib/`.
///
/// Componentes (nível 3 do C4) e onde ficam:
///  - shell:          `main.dart`, `app.dart`, `dependencias.dart`
///  - design system:  `ui/theme/` (tokens) e `ui/components/` (widgets)
///  - telas:          `ui/<tela>/` (qualquer outra pasta de `ui/`)
///  - domínio:        `domain/`
///  - dados:          `data/`
void main() {
  const shell = {'main.dart', 'app.dart', 'dependencias.dart'};
  const infraestrutura = ['dart:io', 'package:path_provider', 'package:flutter_secure_storage', 'package:crypto'];

  final arquivos = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => f.path.replaceAll(r'\', '/').replaceFirst('lib/', ''))
      .toList()
    ..sort();

  /// Nome do componente de um caminho dentro de `lib/`. Telas viram `tela:<pasta>`.
  String componenteDe(String caminho) {
    if (shell.contains(caminho)) return 'shell';
    final partes = caminho.split('/');
    switch (partes.first) {
      case 'domain':
        return 'domain';
      case 'data':
        return 'data';
      case 'ui' when partes.length > 2:
        return switch (partes[1]) {
          'theme' => 'ds_tokens',
          'components' => 'ds_widgets',
          final tela => 'tela:$tela',
        };
      default:
        return 'desconhecido';
    }
  }

  List<String> importsDe(String caminho) => RegExp(r'''^(?:import|export)\s+'([^']+)'(?:\s+show[^;]+)?;''', multiLine: true)
      .allMatches(File('lib/$caminho').readAsStringSync())
      .map((m) => m.group(1)!)
      .toList();

  /// Componentes internos que cada arquivo importa: (arquivo, import, componente do import).
  Iterable<(String, String, String)> dependenciasInternas() sync* {
    for (final a in arquivos) {
      for (final i in importsDe(a).where((i) => i.startsWith('package:jetboat/'))) {
        yield (a, i, componenteDe(i.replaceFirst('package:jetboat/', '')));
      }
    }
  }

  test('todo arquivo de lib/ pertence a um componente conhecido', () {
    final desconhecidos = arquivos.where((a) => componenteDe(a) == 'desconhecido').toList();
    expect(desconhecidos, isEmpty,
        reason: 'Pasta nova em lib/? Inclua-a neste teste e no ARQUITETURA_C4.md (seções 4 e 6).');
  });

  test('imports internos usam package:jetboat/ (nada de caminhos relativos)', () {
    final relativos = [
      for (final a in arquivos)
        for (final i in importsDe(a))
          if (!i.startsWith('package:') && !i.startsWith('dart:')) '$a → $i',
    ];
    expect(relativos, isEmpty);
  });

  test('regra 1: telas não importam lib/data/', () {
    final violacoes = [
      for (final (a, i, destino) in dependenciasInternas())
        if (componenteDe(a).startsWith('tela:') && destino == 'data') '$a → $i',
    ];
    expect(violacoes, isEmpty, reason: 'Telas recebem a interface Autenticacao do domínio, não as implementações.');
  });

  test('regra 2: telas não importam outras telas', () {
    final violacoes = [
      for (final (a, i, destino) in dependenciasInternas())
        if (componenteDe(a).startsWith('tela:') && destino.startsWith('tela:') && destino != componenteDe(a)) '$a → $i',
    ];
    expect(violacoes, isEmpty, reason: 'O que for comum a duas telas vai para ui/components ou para domain.');
  });

  test('regra 3: o design system não conhece regra de negócio', () {
    final violacoes = [
      for (final (a, i, destino) in dependenciasInternas())
        if (componenteDe(a) == 'ds_tokens' && destino != 'ds_tokens' ||
            componenteDe(a) == 'ds_widgets' && !const {'ds_tokens', 'ds_widgets'}.contains(destino))
          '$a → $i',
    ];
    expect(violacoes, isEmpty, reason: 'ui/theme depende só do Flutter; ui/components, só do Flutter e de ui/theme.');
  });

  test('regra 4: o domínio é Dart puro (sem Flutter, sem ui/, sem data/)', () {
    final violacoes = [
      for (final a in arquivos.where((a) => componenteDe(a) == 'domain'))
        for (final i in importsDe(a))
          if (i.startsWith('package:') && !i.startsWith('package:jetboat/domain/') || infraestrutura.contains(i) || i == 'dart:ui')
            '$a → $i',
    ];
    expect(violacoes, isEmpty);
  });

  test('a camada de dados não importa a interface (ui/)', () {
    final violacoes = [
      for (final (a, i, destino) in dependenciasInternas())
        if (componenteDe(a) == 'data' && (destino.startsWith('tela:') || destino.startsWith('ds_') || destino == 'shell'))
          '$a → $i',
    ];
    expect(violacoes, isEmpty);
  });

  test('regra 6: só o dependencias.dart monta as implementações de lib/data/', () {
    final violacoes = [
      for (final (a, i, destino) in dependenciasInternas())
        if (destino == 'data' && componenteDe(a) != 'data' && a != 'dependencias.dart') '$a → $i',
    ];
    expect(violacoes, isEmpty, reason: 'Fora de data/, só lib/dependencias.dart conhece as implementações.');
  });

  test('telas e design system não usam infraestrutura (arquivo, criptografia, armazenamento)', () {
    final violacoes = [
      for (final a in arquivos.where((a) => componenteDe(a).startsWith('tela:') || componenteDe(a).startsWith('ds_')))
        for (final i in importsDe(a))
          if (infraestrutura.any(i.startsWith)) '$a → $i',
    ];
    expect(violacoes, isEmpty);
  });
}
