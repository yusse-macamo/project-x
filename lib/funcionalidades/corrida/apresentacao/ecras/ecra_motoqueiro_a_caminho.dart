import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:project_x/funcionalidades/capulana/apresentacao/controladores/controlador_capulana.dart';
import 'package:project_x/funcionalidades/corrida/apresentacao/controladores/controlador_corrida.dart';
import 'package:project_x/funcionalidades/corrida/dominio/corrida.dart';
import 'package:project_x/nucleo/constantes/padrao_capulana.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/nucleo/tema/tema_app.dart';
import 'package:project_x/nucleo/utilitarios/formatadores.dart';
import 'package:project_x/partilhado/widgets/botao_principal.dart';
import 'package:project_x/partilhado/widgets/dialogo_confirmacao.dart';
import 'package:project_x/partilhado/widgets/elementos_rota.dart';
import 'package:project_x/partilhado/widgets/faixa_capulana.dart';
import 'package:project_x/partilhado/widgets/fundo_capulana.dart';
import 'package:project_x/partilhado/widgets/mapa_rota.dart';
import 'package:project_x/partilhado/widgets/marcadores_mapa.dart';
import 'package:project_x/rotas/rotas_app.dart';

class EcraMotoqueiroACaminho extends ConsumerWidget {
  const EcraMotoqueiroACaminho({super.key});

  Future<void> _cancelar(BuildContext context, WidgetRef ref) async {
    final bool confirmado = await mostrarDialogoConfirmacao(
      context,
      titulo: 'Cancelar a viagem?',
      mensagem: 'O motoqueiro deixa de vir buscar-te.',
      rotuloConfirmar: 'Cancelar viagem',
      rotuloCancelar: 'Manter viagem',
    );
    if (confirmado) {
      await ref.read(controladorCorridaProvider.notifier).cancelar();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final ControladorCorrida controlador = ref.read(
      controladorCorridaProvider.notifier,
    );
    final Corrida? corrida = estado.corrida;
    if (corrida == null) {
      return const Scaffold();
    }
    final MotoqueiroAtribuido motoqueiro = corrida.motoqueiro;
    final AproximacaoMotoqueiro? aproximacao = estado.aproximacao;
    final PadraoCapulana padrao = ref.watch(controladorCapulanaProvider).padrao;
    final double metros = aproximacao?.metros ?? 450;
    final double? troco = corrida.troco;
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TextTheme textos = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool saiu, Object? _) {
        if (!saiu && !estado.aProcessar) {
          _cancelar(context, ref);
        }
      },
      child: Scaffold(
        body: LayoutMapaFolha(
          fracaoMapa: 0.32,
          faixa: 'O mota já vem',
          mapa: MapaRota(
            centro: corrida.pedido.origem,
            zoom: 15.5,
            marcadores: <Marker>[
              Marker(
                point: paraLatLng(corrida.pedido.origem),
                width: 56,
                height: 56,
                child: const MarcadorPosicao(),
              ),
              if (aproximacao != null)
                Marker(
                  point: paraLatLng(aproximacao.posicao),
                  width: 48,
                  height: 48,
                  child: const MarcadorMota(),
                ),
            ],
          ),
          sobreposicoes: <Widget>[
            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CoresApp.marinho,
                  borderRadius: BorderRadius.circular(TemaApp.raio),
                ),
                child: Row(
                  children: <Widget>[
                    SeloAmarelo(
                      texto: formatarDistancia(metros).toUpperCase(),
                      inclinado: false,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'O mais perto de ti',
                            style: TextStyle(
                              color: CoresApp.creme,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Saiu da ${motoqueiro.praca}',
                            style: const TextStyle(
                              color: CoresApp.creme,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: CoresApp.creme,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: CoresApp.marinho, width: 1.5),
                ),
                child: Row(
                  children: <Widget>[
                    const SizedBox.square(
                      dimension: 40,
                      child: ClipOval(child: CapulanaAtual()),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Procura a tua capulana “${padrao.nome}”',
                        style: const TextStyle(
                          color: CoresApp.marinho,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        backgroundColor: CoresApp.marinho,
                        foregroundColor: CoresApp.destaque,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () => context.push(Rotas.sinal),
                      child: const Text('MOSTRAR SINAL'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          conteudo: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (controlador.modoDeTeste) ...<Widget>[
                const FaixaModoTeste(
                  mensagem:
                      'Modo de teste: motoqueiro fictício. Ninguém vem '
                      'buscar-te.',
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: <Widget>[
                  AvatarIniciais(
                    iniciais: motoqueiro.iniciais,
                    tamanho: 64,
                    capulana: const FundoCapulana(
                      padrao: PadraoCapulana.rodasAzuis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          motoqueiro.nome,
                          style: textos.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.star,
                              size: 18,
                              color: CoresApp.destaque,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${formatarAvaliacao(motoqueiro.avaliacao)} · '
                              '${motoqueiro.viagens} viagens',
                              style: textos.bodyMedium?.copyWith(
                                color: cores.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cores.surfaceContainerLowest,
                      border: Border.all(color: cores.onSurface),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      motoqueiro.matricula,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _Etiqueta(
                    texto: 'COLETE Nº ${motoqueiro.numeroColete}',
                    destaque: true,
                  ),
                  if (motoqueiro.registadoNaAssociacao)
                    const _Etiqueta(texto: '✓ Registado na associação'),
                  if (motoqueiro.temCapaceteExtra)
                    const _Etiqueta(texto: '✓ Capacete para ti'),
                ],
              ),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cores.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(TemaApp.raio),
                          border: Border.all(
                            color: cores.onSurface,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Código para subir', style: textos.labelLarge),
                            const SizedBox(height: 4),
                            Text(
                              corrida.codigoSubida,
                              style: textos.headlineMedium?.copyWith(
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CoresApp.destaqueClara,
                          borderRadius: BorderRadius.circular(TemaApp.raio),
                          border: Border.all(
                            color: CoresApp.destaque,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              troco == null
                                  ? 'Pagas ${formatarMt(corrida.preco)} por '
                                        '${corrida.pedido.formaPagamento.nome}'
                                  : 'Pagas ${formatarMt(corrida.preco)} c/ '
                                        'nota de '
                                        '${corrida.pedido.notaPagamento}',
                              style: const TextStyle(
                                color: CoresApp.marinho,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (troco != null && troco > 0)
                              Text(
                                'Traz ${formatarMt(troco)} de troco',
                                style: const TextStyle(
                                  color: CoresApp.marinho,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _Acao(
                      icone: Icons.call_outlined,
                      texto: 'Ligar',
                      aoTocar: () => copiarEAvisar(
                        context,
                        motoqueiro.telefone,
                        'Número copiado. Cola-o no telefone para ligar.',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Acao(
                      icone: Icons.mic_none,
                      texto: 'Áudio',
                      aoTocar: () => mostrarAviso(
                        context,
                        'As mensagens de voz ainda não estão disponíveis.',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Acao(
                      icone: Icons.share_outlined,
                      texto: 'WhatsApp da família',
                      aoTocar: () => copiarEAvisar(
                        context,
                        controlador.textoPartilha(),
                        'Mensagem copiada. Cola-a no WhatsApp da família.',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          rodape: Row(
            children: <Widget>[
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CoresApp.terracota,
                  ),
                  onPressed: estado.aProcessar
                      ? null
                      : () => _cancelar(context, ref),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: BotaoPrincipal(
                  texto: 'Já subi',
                  aCarregar: estado.aProcessar,
                  aoPremir: controlador.confirmarSubida,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, this.destaque = false});

  final String texto;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: destaque ? CoresApp.marinho : CoresApp.primariaClara,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: destaque ? CoresApp.destaque : CoresApp.primariaEscura,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _Acao extends StatelessWidget {
  const _Acao({
    required this.icone,
    required this.texto,
    required this.aoTocar,
  });

  final IconData icone;
  final String texto;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    return InkWell(
      onTap: aoTocar,
      borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
      child: Container(
        height: 84,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cores.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
          border: Border.all(color: cores.outline),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icone, color: CoresApp.primaria),
            const SizedBox(height: 4),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
