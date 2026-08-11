import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';

class EcraSplash extends ConsumerStatefulWidget {
  const EcraSplash({super.key});

  @override
  ConsumerState<EcraSplash> createState() => _EcraSplashState();
}

class _EcraSplashState extends ConsumerState<EcraSplash> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      ref.read(controladorAutenticacaoProvider.notifier).verificarSessao();
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textos = Theme.of(context).textTheme;
    final ColorScheme cores = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CoresApp.ambar,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.two_wheeler,
                color: CoresApp.textoClaro,
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'MotoTáxi Inhambane',
              style: textos.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Inhambane',
              style: textos.bodyMedium?.copyWith(color: cores.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
