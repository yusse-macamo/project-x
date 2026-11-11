import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/capulana/apresentacao/controladores/controlador_capulana.dart';
import 'package:project_x/funcionalidades/capulana/dados/repositorio_capulana.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/partilhado/widgets/fundo_capulana.dart';

/// Capulana escolhida pelo passageiro, que é o tema da app.
class CapulanaAtual extends ConsumerWidget {
  const CapulanaAtual({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CapulanaEscolhida capulana = ref.watch(controladorCapulanaProvider);
    return FundoCapulana(
      padrao: capulana.padrao,
      caminhoFoto: capulana.caminhoFoto,
    );
  }
}

class FaixaCapulana extends StatelessWidget {
  const FaixaCapulana({required this.texto, super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const CapulanaAtual(),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: CoresApp.marinho,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  texto.toUpperCase(),
                  style: const TextStyle(
                    color: CoresApp.creme,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mapa em cima, faixa de capulana e folha com o conteúdo por baixo. O mapa
/// continua atrás dos cantos arredondados da faixa.
class LayoutMapaFolha extends StatelessWidget {
  const LayoutMapaFolha({
    required this.mapa,
    required this.faixa,
    required this.conteudo,
    this.sobreposicoes = const <Widget>[],
    this.rodape,
    this.fracaoMapa = 0.34,
    super.key,
  });

  final Widget mapa;
  final List<Widget> sobreposicoes;
  final String faixa;
  final Widget conteudo;
  final Widget? rodape;
  final double fracaoMapa;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final Widget? rodapeAtual = rodape;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints limites) {
        final double alturaMapa = limites.maxHeight * fracaoMapa;
        return Stack(
          children: <Widget>[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: alturaMapa + 24,
              child: mapa,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: alturaMapa,
              child: SafeArea(
                bottom: false,
                child: Stack(children: sobreposicoes),
              ),
            ),
            Positioned.fill(
              child: Column(
                children: <Widget>[
                  SizedBox(height: alturaMapa),
                  FaixaCapulana(texto: faixa),
                  Expanded(
                    child: ColoredBox(
                      color: cores.surface,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        child: conteudo,
                      ),
                    ),
                  ),
                  if (rodapeAtual != null)
                    ColoredBox(
                      color: cores.surface,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                        child: SafeArea(top: false, child: rodapeAtual),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
