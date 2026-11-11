import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/cadastro_motoqueiro/dados/selector_imagem.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/dominio/excecao_selector_imagem.dart';
import 'package:project_x/funcionalidades/capulana/apresentacao/controladores/controlador_capulana.dart';
import 'package:project_x/funcionalidades/capulana/dados/repositorio_capulana.dart';
import 'package:project_x/nucleo/constantes/padrao_capulana.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/nucleo/tema/tema_app.dart';
import 'package:project_x/partilhado/widgets/botao_principal.dart';
import 'package:project_x/partilhado/widgets/elementos_rota.dart';
import 'package:project_x/partilhado/widgets/fundo_capulana.dart';

class EcraEscolherCapulana extends ConsumerStatefulWidget {
  const EcraEscolherCapulana({super.key});

  @override
  ConsumerState<EcraEscolherCapulana> createState() =>
      _EcraEscolherCapulanaState();
}

class _EcraEscolherCapulanaState extends ConsumerState<EcraEscolherCapulana> {
  late PadraoCapulana _padrao;
  String? _foto;
  bool _aGuardar = false;

  @override
  void initState() {
    super.initState();
    final CapulanaEscolhida atual = ref.read(controladorCapulanaProvider);
    _padrao = atual.padrao;
    _foto = atual.caminhoFoto;
  }

  Future<void> _fotografar() async {
    try {
      final String? caminho = await ref
          .read(selectorImagemProvider)
          .tirarFotografia();
      if (caminho != null && mounted) {
        setState(() => _foto = caminho);
      }
    } on ExcecaoSelectorImagem {
      if (mounted) {
        mostrarAviso(
          context,
          'Não foi possível abrir a câmara. Autoriza o acesso nas definições '
          'do telemóvel.',
        );
      }
    }
  }

  Future<void> _usar() async {
    setState(() => _aGuardar = true);
    await ref
        .read(controladorCapulanaProvider.notifier)
        .guardar(CapulanaEscolhida(padrao: _padrao, caminhoFoto: _foto));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TextTheme textos = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    BotaoRedondo(
                      icone: Icons.arrow_back_ios_new,
                      dica: 'Voltar',
                      aoTocar: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ESCOLHE A TUA CAPULANA',
                      style: textos.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vira o tema da tua app. E o motoqueiro reconhece-te '
                      'pelo padrão que aparece no ecrã dele.',
                      style: textos.bodyLarge?.copyWith(
                        color: cores.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Previsao(padrao: _padrao, foto: _foto),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.95,
                      children: <Widget>[
                        for (final PadraoCapulana padrao
                            in PadraoCapulana.values)
                          _Opcao(
                            rotulo: padrao.nome,
                            selecionada: _foto == null && padrao == _padrao,
                            aoTocar: () => setState(() {
                              _padrao = padrao;
                              _foto = null;
                            }),
                            child: FundoCapulana(padrao: padrao),
                          ),
                        _Opcao(
                          rotulo: 'Fotografar a minha',
                          selecionada: _foto != null,
                          aoTocar: _fotografar,
                          child: _foto == null
                              ? Container(
                                  color: cores.surfaceContainerLowest,
                                  child: const Icon(
                                    Icons.photo_camera_outlined,
                                    color: CoresApp.terracota,
                                    size: 32,
                                  ),
                                )
                              : FundoCapulana(
                                  padrao: _padrao,
                                  caminhoFoto: _foto,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: BotaoPrincipal(
                texto: 'Usar esta',
                aCarregar: _aGuardar,
                aoPremir: _usar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Previsao extends StatelessWidget {
  const _Previsao({required this.padrao, required this.foto});

  final PadraoCapulana padrao;
  final String? foto;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TextTheme textos = Theme.of(context).textTheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cores.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(TemaApp.raio),
        border: Border.all(color: cores.onSurface, width: 1.5),
      ),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 130,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                FundoCapulana(padrao: padrao, caminhoFoto: foto),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    color: CoresApp.marinho,
                    child: Text(
                      (foto == null ? padrao.nome : 'A minha').toUpperCase(),
                      style: const TextStyle(
                        color: CoresApp.destaque,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                SizedBox.square(
                  dimension: 48,
                  child: ClipOval(
                    child: FundoCapulana(padrao: padrao, caminhoFoto: foto),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'NO ECRÃ DO MOTOQUEIRO',
                        style: textos.labelSmall?.copyWith(
                          color: cores.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Passageiro com esta capulana',
                        style: textos.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'À espera no ponto de recolha',
                        style: textos.bodySmall?.copyWith(
                          color: cores.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Opcao extends StatelessWidget {
  const _Opcao({
    required this.rotulo,
    required this.selecionada,
    required this.aoTocar,
    required this.child,
  });

  final String rotulo;
  final bool selecionada;
  final VoidCallback aoTocar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: aoTocar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
                border: Border.all(
                  color: selecionada ? cores.onSurface : cores.outline,
                  width: selecionada ? 3 : 1,
                ),
              ),
              child: child,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rotulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
