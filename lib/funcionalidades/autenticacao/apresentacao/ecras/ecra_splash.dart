import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/nucleo/constantes/padrao_capulana.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/partilhado/widgets/elementos_rota.dart';
import 'package:project_x/partilhado/widgets/fundo_capulana.dart';

/// Abre a sessão guardada no telemóvel. Quem já entrou antes vai direto para
/// a app, sem novo código por SMS. Se a verificação falhar (sem internet), a
/// sessão continua guardada e a pessoa só tem de tentar de novo.
class EcraSplash extends ConsumerStatefulWidget {
  const EcraSplash({super.key});

  @override
  ConsumerState<EcraSplash> createState() => _EcraSplashState();
}

class _EcraSplashState extends ConsumerState<EcraSplash> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) => _verificar());
  }

  void _verificar() {
    ref.read(controladorAutenticacaoProvider.notifier).verificarSessao();
  }

  @override
  Widget build(BuildContext context) {
    final EstadoAutenticacao estado = ref.watch(
      controladorAutenticacaoProvider,
    );
    final String? erro = estado.aProcessar ? null : estado.erro;
    final TextTheme textos = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: CoresApp.marinho,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const FundoCapulana(padrao: PadraoCapulana.folhasDoMar),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const LogoRota(invertido: true, tamanhoLetra: 44),
                    const SizedBox(height: 40),
                    if (erro == null)
                      const SizedBox.square(
                        dimension: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: CoresApp.destaque,
                        ),
                      )
                    else ...<Widget>[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CoresApp.marinho,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: <Widget>[
                            Text(
                              erro,
                              textAlign: TextAlign.center,
                              style: textos.bodyLarge?.copyWith(
                                color: CoresApp.creme,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: CoresApp.destaque,
                                foregroundColor: CoresApp.marinho,
                                minimumSize: const Size(0, 48),
                              ),
                              onPressed: _verificar,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tentar de novo'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
