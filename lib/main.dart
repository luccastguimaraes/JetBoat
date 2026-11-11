import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jetboat/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final dependencias = await Dependencias.criar();
  // Sessão ainda válida (ou renovável)? Abre direto na área logada.
  final sessao = await dependencias.autenticacao.sessaoAtual();

  runApp(JetBoatApp(dependencias: dependencias, sessaoInicial: sessao));
}
