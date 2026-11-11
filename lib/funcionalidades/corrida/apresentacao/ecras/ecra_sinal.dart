import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/corrida/apresentacao/controladores/controlador_corrida.dart';
import 'package:project_x/funcionalidades/corrida/dominio/corrida.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/nucleo/tema/tema_app.dart';
import 'package:project_x/nucleo/utilitarios/formatadores.dart';
import 'package:project_x/partilhado/widgets/elementos_rota.dart';
import 'package:project_x/partilhado/widgets/faixa_capulana.dart';

class EcraSinal extends ConsumerStatefulWidget {
  const EcraSinal({super.key});

  @override
  ConsumerState<EcraSinal> createState() => _EcraSinalState();
}

class _EcraSinalState extends ConsumerState<EcraSinal> {
  Timer? _temporizador;
  bool _piscar = false;
  bool _apagado = false;

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  void _alternarPiscar() {
    _temporizador?.cancel();
    setState(() {
      _piscar = !_piscar;
      _apagado = false;
    });
    if (_piscar) {
      _temporizador = Timer.periodic(
        const Duration(milliseconds: 500),
        (Timer _) => setState(() => _apagado = !_apagado),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final EstadoCorrida estado = ref.watch(controladorCorridaProvider);
    final Corrida? corrida = estado.corrida;
    if (corrida == null) {
      return const Scaffold();
    }
    final MotoqueiroAtribuido motoqueiro = corrida.motoqueiro;
    final double metros = estado.aproximacao?.metros ?? 450;

    return Scaffold(
      backgroundColor: CoresApp.marinho,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _apagado ? 0.15 : 1,
            child: const CapulanaAtual(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CoresApp.creme,
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
                                'Levanta o telemóvel',
                                style: TextStyle(
                                  color: CoresApp.marinho,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${motoqueiro.primeiroNome} está a chegar',
                                style: const TextStyle(
                                  color: CoresApp.marinho,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: Transform.rotate(
                      angle: -0.03,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        color: CoresApp.marinho,
                        child: const Text(
                          'ESTOU À ESPERA DO',
                          style: TextStyle(
                            color: CoresApp.destaque,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: 0.012,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: CoresApp.creme,
                        border: Border.all(color: CoresApp.marinho, width: 5),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'COLETE ${motoqueiro.numeroColete}',
                          style: const TextStyle(
                            color: CoresApp.marinho,
                            fontSize: 60,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      color: CoresApp.marinho,
                      child: Text(
                        '${motoqueiro.descricaoVeiculo} · '
                        '${motoqueiro.matricula}',
                        style: const TextStyle(
                          color: CoresApp.creme,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _BotaoClaro(
                          icone: _piscar
                              ? Icons.check_box_outlined
                              : Icons.check_box_outline_blank,
                          texto: 'Piscar (à noite)',
                          aoTocar: _alternarPiscar,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _BotaoClaro(
                          texto: 'Brilho no máximo',
                          aoTocar: () => mostrarAviso(
                            context,
                            'Sobe o brilho nas definições rápidas do telemóvel.',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CoresApp.marinho.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'O código só dizes quando chegar — nunca o mostres aqui.',
                      style: TextStyle(
                        color: CoresApp.creme,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: CoresApp.marinho,
                      foregroundColor: CoresApp.destaque,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('JÁ ME VIU'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotaoClaro extends StatelessWidget {
  const _BotaoClaro({required this.texto, required this.aoTocar, this.icone});

  final String texto;
  final VoidCallback aoTocar;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: CoresApp.creme,
        foregroundColor: CoresApp.marinho,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      ),
      onPressed: aoTocar,
      icon: icone == null ? const SizedBox.shrink() : Icon(icone),
      label: Text(texto),
    );
  }
}
