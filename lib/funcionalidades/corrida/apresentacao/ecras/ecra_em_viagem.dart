import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:project_x/funcionalidades/corrida/apresentacao/controladores/controlador_corrida.dart';
import 'package:project_x/funcionalidades/corrida/dominio/corrida.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/local.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/nucleo/tema/tema_app.dart';
import 'package:project_x/nucleo/utilitarios/formatadores.dart';
import 'package:project_x/partilhado/widgets/elementos_rota.dart';
import 'package:project_x/partilhado/widgets/faixa_capulana.dart';
import 'package:project_x/partilhado/widgets/mapa_rota.dart';
import 'package:project_x/partilhado/widgets/marcadores_mapa.dart';
import 'package:project_x/rotas/rotas_app.dart';

class EcraEmViagem extends ConsumerWidget {
  const EcraEmViagem({super.key});

  // O alerta ainda não chega a ninguém: o ecrã tem de o dizer, para ninguém
  // ficar à espera de uma ajuda que não vem.
  Future<void> _mostrarSos(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext contexto) => AlertDialog(
        title: const Text('SOS ainda não está ligado'),
        content: const Text(
          'Este botão ainda não envia nenhum alerta. Se estiveres em perigo, '
          'liga já para as autoridades ou para alguém de confiança.',
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(),
            child: const Text('Percebi'),
          ),
        ],
      ),
    );
  }

  Future<void> _adicionarParagem(BuildContext context, WidgetRef ref) async {
    final Local? local = await context.push<Local>(Rotas.pesquisaDestino);
    if (local != null) {
      await ref
          .read(controladorCorridaProvider.notifier)
          .adicionarParagem(local);
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
    final ProgressoViagem? progresso = estado.progresso;
    final Coordenada origem = corrida.pedido.origem;
    final Coordenada destino = corrida.pedido.destino;
    final Coordenada posicao = progresso?.posicao ?? origem;
    final double fracao = progresso?.fracao ?? 0;
    final double kmRestantes = progresso?.kmRestantes ?? corrida.distanciaKm;
    final DateTime inicio = corrida.iniciadaEm ?? DateTime.now();
    final DateTime? chegada = corrida.chegadaPrevista;
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TextTheme textos = Theme.of(context).textTheme;

    return Scaffold(
      body: LayoutMapaFolha(
        fracaoMapa: 0.44,
        faixa: 'Devagar se vai ao longe',
        mapa: MapaRota(
          centro: origem.interpolarAte(destino, 0.5),
          zoom: 13.5,
          linhas: <Polyline<Object>>[
            Polyline<Object>(
              points: <LatLng>[paraLatLng(origem), paraLatLng(posicao)],
              color: CoresApp.marinho,
              strokeWidth: 5,
            ),
            Polyline<Object>(
              points: <LatLng>[paraLatLng(posicao), paraLatLng(destino)],
              color: CoresApp.marinho,
              strokeWidth: 4,
              pattern: const StrokePattern.dotted(),
            ),
          ],
          marcadores: <Marker>[
            Marker(
              point: paraLatLng(destino),
              width: 36,
              height: 36,
              child: const MarcadorDestino(),
            ),
            for (final ParagemPercurso paragem in corrida.paragens)
              Marker(
                point: paraLatLng(paragem.coordenada),
                width: 28,
                height: 28,
                child: const MarcadorParagem(),
              ),
            Marker(
              point: paraLatLng(posicao),
              width: 52,
              height: 52,
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
                color: CoresApp.creme,
                borderRadius: BorderRadius.circular(TemaApp.raio),
                border: Border.all(color: CoresApp.marinho, width: 1.5),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'A caminho de',
                          style: TextStyle(
                            color: CoresApp.marinho,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          corrida.pedido.destinoNome.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: CoresApp.marinho,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (chegada != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        const Text(
                          'Chegas às',
                          style: TextStyle(
                            color: CoresApp.marinho,
                            fontSize: 13,
                          ),
                        ),
                        SeloAmarelo(
                          texto: formatarHora(chegada),
                          tamanhoLetra: 20,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 12,
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(84, 52),
                backgroundColor: CoresApp.sos,
                foregroundColor: CoresApp.branco,
                shape: const StadiumBorder(
                  side: BorderSide(color: CoresApp.creme, width: 3),
                ),
              ),
              onPressed: () => _mostrarSos(context),
              child: const Text('SOS'),
            ),
          ),
        ],
        conteudo: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (controlador.modoDeTeste) ...<Widget>[
              const FaixaModoTeste(
                mensagem: 'Modo de teste: esta viagem é simulada.',
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'FALTAM ${formatarKm(kmRestantes).toUpperCase()}',
              style: textos.headlineSmall,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 16,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ColoredBox(color: cores.surfaceContainerHighest),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fracao,
                      child: const CapulanaAtual(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _LinhaPercurso(
              icone: Icons.radio_button_unchecked,
              cor: cores.onSurface,
              texto: '${corrida.pedido.origemNome} (partida)',
              hora: formatarHora(inicio),
              riscado: true,
            ),
            for (final ParagemPercurso paragem in corrida.paragens)
              _LinhaPercurso(
                icone: Icons.circle,
                cor: CoresApp.terracota,
                texto: '${paragem.nome} · ${paragem.minutosParado} min parado',
              ),
            _LinhaPercurso(
              icone: Icons.square_rounded,
              cor: CoresApp.terracota,
              texto: corrida.pedido.destinoNome,
              hora: chegada == null ? null : formatarHora(chegada),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _adicionarParagem(context, ref),
                    child: const Text(
                      '+ Paragem no caminho',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => copiarEAvisar(
                      context,
                      controlador.textoPartilha(),
                      'Mensagem copiada. Cola-a no WhatsApp.',
                    ),
                    icon: const Icon(
                      Icons.share_outlined,
                      color: CoresApp.primaria,
                    ),
                    label: const Text(
                      'Enviar no WhatsApp',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        rodape: IgnorePointer(
          ignoring: estado.aProcessar,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: CoresApp.marinho,
              foregroundColor: CoresApp.destaque,
            ),
            onPressed: controlador.concluir,
            child: estado.aProcessar
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: CoresApp.destaque,
                    ),
                  )
                : Text('CHEGUEI · PAGAR ${formatarMt(corrida.preco)}'),
          ),
        ),
      ),
    );
  }
}

class _LinhaPercurso extends StatelessWidget {
  const _LinhaPercurso({
    required this.icone,
    required this.cor,
    required this.texto,
    this.hora,
    this.riscado = false,
  });

  final IconData icone;
  final Color cor;
  final String texto;
  final String? hora;
  final bool riscado;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final String? horaAtual = hora;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Icon(icone, size: 20, color: cor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontWeight: riscado ? FontWeight.w400 : FontWeight.w800,
                decoration: riscado ? TextDecoration.lineThrough : null,
                color: riscado ? cores.onSurfaceVariant : cores.onSurface,
              ),
            ),
          ),
          if (horaAtual != null)
            Text(horaAtual, style: TextStyle(color: cores.onSurfaceVariant)),
        ],
      ),
    );
  }
}
