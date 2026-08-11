import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:project_x/nucleo/tema/tema_app.dart';
import 'package:project_x/nucleo/tipo_aplicacao.dart';
import 'package:project_x/rotas/rotas_app.dart';

Future<Widget> arrancarApp(TipoAplicacao tipo) async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  return ProviderScope(
    overrides: <Override>[tipoAplicacaoProvider.overrideWithValue(tipo)],
    child: const _App(),
  );
}

class _App extends ConsumerWidget {
  const _App();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter roteador = ref.watch(roteadorProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: TemaApp.claro,
      darkTheme: TemaApp.escuro,
      themeMode: ThemeMode.system,
      routerConfig: roteador,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
