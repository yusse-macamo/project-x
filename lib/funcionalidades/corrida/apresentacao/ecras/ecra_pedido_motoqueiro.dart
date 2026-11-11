import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/corrida/apresentacao/controladores/controlador_pedidos_motoqueiro.dart';
import 'package:project_x/funcionalidades/corrida/dominio/corrida.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/nucleo/tema/tema_app.dart';
import 'package:project_x/nucleo/utilitarios/formatadores.dart';
import 'package:project_x/partilhado/widgets/elementos_rota.dart';
import 'package:project_x/partilhado/widgets/fundo_capulana.dart';

class EcraPedidoMotoqueiro extends ConsumerWidget {
  const EcraPedidoMotoqueiro({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EstadoPedidosMotoqueiro estado = ref.watch(
      controladorPedidosMotoqueiroProvider,
    );
    final ControladorPedidosMotoqueiro controlador = ref.read(
      controladorPedidosMotoqueiroProvider.notifier,
    );
    final PedidoParaMotoqueiro? pedido = estado.pedido;
    if (pedido == null) {
      return const Scaffold(backgroundColor: CoresApp.marinho);
    }
    final double? troco = pedido.trocoALevar;

    return Scaffold(
      backgroundColor: CoresApp.marinho,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Row(
                      children: <Widget>[
                        LogoRota(invertido: true, tamanhoLetra: 18),
                        SizedBox(width: 12),
                        Text(
                          'MOTOQUEIRO',
                          style: TextStyle(
                            color: CoresApp.creme,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (controlador.modoDeTeste) ...<Widget>[
                      const FaixaModoTeste(
                        mensagem: 'Modo de teste: este pedido é fictício.',
                      ),
                      const SizedBox(height: 12),
                    ],
                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: CoresApp.creme,
                        borderRadius: BorderRadius.circular(TemaApp.raio),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          SizedBox(
                            height: 150,
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                FundoCapulana(
                                  padrao: pedido.capulanaPassageiro,
                                ),
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    color: CoresApp.marinho,
                                    child: const Text(
                                      'PROCURA ESTE PADRÃO',
                                      style: TextStyle(
                                        color: CoresApp.destaque,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 12,
                                  bottom: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    color: CoresApp.creme,
                                    child: Text(
                                      pedido.capulanaPassageiro.nome
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: CoresApp.marinho,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 12,
                                  bottom: 12,
                                  child: SeloAmarelo(
                                    texto: formatarMt(pedido.preco),
                                    tamanhoLetra: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Expanded(
                                      child: _TextoCartao(
                                        titulo: pedido.passageiroNome,
                                        subtitulo:
                                            '★ ${formatarAvaliacao(pedido.passageiroAvaliacao)} '
                                            'como passageiro',
                                      ),
                                    ),
                                    _TextoCartao(
                                      titulo: formatarDistancia(
                                        pedido.metrosAteRecolha,
                                      ).toUpperCase(),
                                      subtitulo:
                                          'até à recolha · '
                                          '${pedido.minutosAteRecolha} min',
                                      alinhamento: CrossAxisAlignment.end,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const _Rotulo('APANHAR EM'),
                                _Valor(pedido.origemNome),
                                if (pedido.notaVoz != null) ...<Widget>[
                                  const SizedBox(height: 8),
                                  _NotaVozCompacta(
                                    segundos: pedido.notaVoz!.duracaoSegundos,
                                  ),
                                ],
                                const SizedBox(height: 12),
                                const _Rotulo('LEVAR ATÉ'),
                                _Valor(
                                  '${pedido.destinoNome} · '
                                  '${formatarKm(pedido.distanciaKm)}',
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: CoresApp.destaqueClara,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      const Icon(
                                        Icons.payments_outlined,
                                        color: CoresApp.marinho,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          troco == null
                                              ? 'Paga por '
                                                    '${pedido.formaPagamento.nome}'
                                              : 'Paga em dinheiro com nota de '
                                                    '${pedido.notaPagamento} — '
                                                    'leva ${formatarMt(troco)} '
                                                    'de troco',
                                          style: const TextStyle(
                                            color: CoresApp.marinho,
                                            fontWeight: FontWeight.w700,
                                          ),
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
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(TemaApp.raio),
                        border: Border.all(color: CoresApp.marinhoClaro),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'COMO ENCONTRAR',
                            style: TextStyle(
                              color: CoresApp.destaque,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '1. Chega à referência. 2. Procura alguém com este '
                            'padrão no ecrã levantado. 3. Antes de partir, '
                            'pede o código de 4 números.',
                            style: TextStyle(color: CoresApp.creme),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CoresApp.creme,
                        side: const BorderSide(
                          color: CoresApp.marinhoClaro,
                          width: 2,
                        ),
                      ),
                      onPressed: estado.aProcessar ? null : controlador.recusar,
                      child: const Text('Recusar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: CoresApp.destaque,
                        foregroundColor: CoresApp.marinho,
                      ),
                      onPressed: estado.aProcessar ? null : controlador.aceitar,
                      child: Text('ACEITAR · ${estado.segundosRestantes} S'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextoCartao extends StatelessWidget {
  const _TextoCartao({
    required this.titulo,
    required this.subtitulo,
    this.alinhamento = CrossAxisAlignment.start,
  });

  final String titulo;
  final String subtitulo;
  final CrossAxisAlignment alinhamento;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alinhamento,
      children: <Widget>[
        Text(
          titulo,
          style: const TextStyle(
            color: CoresApp.marinho,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          subtitulo,
          style: const TextStyle(
            color: CoresApp.textoSecundarioClaro,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: CoresApp.textoSecundarioClaro,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _Valor extends StatelessWidget {
  const _Valor(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: CoresApp.marinho,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _NotaVozCompacta extends StatelessWidget {
  const _NotaVozCompacta({required this.segundos});

  final int segundos;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => mostrarAviso(
        context,
        'Modo de teste: a nota de voz ainda não tem som.',
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
        decoration: BoxDecoration(
          color: CoresApp.marinho,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircleAvatar(
              radius: 18,
              backgroundColor: CoresApp.terracota,
              child: Icon(Icons.play_arrow, color: CoresApp.branco),
            ),
            const SizedBox(width: 8),
            const OndaAudio(
              corAtiva: CoresApp.textoSecundarioEscuro,
              barras: 14,
              altura: 22,
            ),
            const SizedBox(width: 8),
            Text(
              formatarDuracao(segundos),
              style: const TextStyle(color: CoresApp.creme),
            ),
          ],
        ),
      ),
    );
  }
}
