import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project_x/nucleo/configuracao/configuracao_ambiente.dart';
import 'package:project_x/nucleo/configuracao/configuracao_supabase.dart';
import 'package:project_x/nucleo/tema/tema_app.dart';
import 'package:project_x/rotas/rotas_app.dart';

Future<Widget> arrancarApp() async {
  _verificarConfiguracao();
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  if (ConfiguracaoSupabase.configurado) {
    await Supabase.initialize(
      url: ConfiguracaoSupabase.url,
      publishableKey: ConfiguracaoSupabase.chavePublicavel,
    );
  }
  return const ProviderScope(child: _App());
}

/// Falha logo no arranque numa versão de produção sem Supabase, que de outra
/// forma cairia nos repositórios simulados sem ninguém notar.
void _verificarConfiguracao() {
  if (ConfiguracaoAmbiente.producao && !ConfiguracaoSupabase.configurado) {
    throw StateError(
      'Compilação de produção sem SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY. '
      'Usa --dart-define-from-file=env/prod.json.',
    );
  }
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
