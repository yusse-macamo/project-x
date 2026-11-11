import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/corrida/apresentacao/controladores/controlador_corrida.dart';
import 'package:project_x/funcionalidades/corrida/dominio/corrida.dart';
import 'package:project_x/nucleo/constantes/padrao_capulana.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/nucleo/utilitarios/formatadores.dart';
import 'package:project_x/partilhado/widgets/botao_principal.dart';
import 'package:project_x/partilhado/widgets/elementos_rota.dart';
import 'package:project_x/partilhado/widgets/fundo_capulana.dart';
import 'package:project_x/partilhado/widgets/faixa_capulana.dart';

class EcraAvaliarCorrida extends ConsumerStatefulWidget {
  const EcraAvaliarCorrida({super.key});

  @override
  ConsumerState<EcraAvaliarCorrida> createState() => _EcraAvaliarCorridaState();
}

class _EcraAvaliarCorridaState extends ConsumerState<EcraAvaliarCorrida> {
  final TextEditingController _comentario = TextEditingController();
  final Set<String> _etiquetas = <String>{};
  int _nota = 5;
  int _gorjeta = 0;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  String get _reacao => switch (_nota) {
    5 => 'MANINGUE NICE!',
    4 => 'FOI BOM!',
    3 => 'MAIS OU MENOS',
    _ => 'CORREU MAL',
  };

  void _enviar() {
    final String comentario = _comentario.text.trim();
    ref
        .read(controladorCorridaProvider.notifier)
        .avaliar(
          nota: _nota,
          etiquetas: _etiquetas,
          gorjeta: _gorjeta,
          comentario: comentario.isEmpty ? null : comentario,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      controladorCorridaProvider.select((EstadoCorrida e) => e.erro),
      (String? anterior, String? erro) {
        if (erro != null) {
          mostrarAviso(context, erro);
          ref.read(controladorCorridaProvider.notifier).limparErro();
        }
      },
    );

    final EstadoCorrida estado = ref.watch(controladorCorridaProvider);
    final Corrida? corrida = estado.corrida;
    if (corrida == null) {
      return const Scaffold();
    }
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TextTheme textos = Theme.of(context).textTheme;
    final double? troco = corrida.troco;
    final String resumo = <String>[
      formatarMt(corrida.preco),
      formatarKm(corrida.distanciaKm),
      '${corrida.minutosViagem} min',
      if (troco != null && troco > 0) 'troco ${formatarMt(troco)}',
    ].join(' · ');

    return Scaffold(
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const CapulanaAtual(),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              color: CoresApp.marinho,
                              child: const Text(
                                'CHEGASTE!',
                                style: TextStyle(
                                  color: CoresApp.destaque,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            BotaoRedondo(
                              icone: Icons.close,
                              dica: 'Fechar',
                              aoTocar: ref
                                  .read(controladorCorridaProvider.notifier)
                                  .saltarAvaliacao,
                            ),
                          ],
                        ),
                        const Spacer(),
                        Transform.rotate(
                          angle: -0.015,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            color: CoresApp.creme,
                            child: Text(
                              corrida.pedido.destinoNome.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: CoresApp.marinho,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          color: CoresApp.marinho,
                          child: Text(
                            resumo,
                            style: const TextStyle(
                              color: CoresApp.creme,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: <Widget>[
                  AvatarIniciais(
                    iniciais: corrida.motoqueiro.iniciais,
                    capulana: const FundoCapulana(
                      padrao: PadraoCapulana.rodasAzuis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Como foi a viagem com ${corrida.motoqueiro.primeiroNome}?',
                    textAlign: TextAlign.center,
                    style: textos.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Colete nº ${corrida.motoqueiro.numeroColete} · '
                    '${corrida.motoqueiro.matricula}',
                    style: textos.bodyMedium?.copyWith(
                      color: cores.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      for (int i = 1; i <= 5; i++)
                        IconButton(
                          iconSize: 40,
                          tooltip: '$i de 5',
                          onPressed: () => setState(() => _nota = i),
                          icon: Icon(
                            i <= _nota ? Icons.star : Icons.star_border,
                            color: CoresApp.destaque,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    _reacao,
                    style: textos.titleLarge?.copyWith(
                      color: CoresApp.primaria,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final String etiqueta in etiquetasDeAvaliacao)
                        ChipOpcao(
                          texto: etiqueta,
                          selecionado: _etiquetas.contains(etiqueta),
                          aoTocar: () => setState(() {
                            if (!_etiquetas.remove(etiqueta)) {
                              _etiquetas.add(etiqueta);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Comentário', style: textos.labelLarge),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _comentario,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText: 'Escreve aqui…',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Text('Gorjeta', style: textos.titleSmall),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            for (final int valor in gorjetasPossiveis)
                              ChipOpcao(
                                texto: valor == 0 ? 'Não' : '$valor MT',
                                selecionado: valor == _gorjeta,
                                corSelecionado: CoresApp.destaque,
                                corTextoSelecionado: CoresApp.marinho,
                                aoTocar: () => setState(() => _gorjeta = valor),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: BotaoPrincipal(
                texto: 'Enviar',
                aCarregar: estado.aProcessar,
                aoPremir: _enviar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
