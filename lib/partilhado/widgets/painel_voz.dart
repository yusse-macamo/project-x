import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/voz/apresentacao/controladores/controlador_gravacao.dart';
import 'package:project_x/funcionalidades/voz/dominio/nota_voz.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/nucleo/tema/tema_app.dart';
import 'package:project_x/nucleo/utilitarios/formatadores.dart';

/// Nota de voz opcional, em três passos claros: gravar → parar → ouvir,
/// gravar de novo ou apagar. A nota fica com o que estiver a ser gravado
/// (por exemplo, a paragem).
class PainelVoz extends ConsumerWidget {
  const PainelVoz({required this.dica, super.key});

  final String dica;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EstadoGravacao estado = ref.watch(controladorGravacaoProvider);
    final ControladorGravacao controlador = ref.read(
      controladorGravacaoProvider.notifier,
    );
    final NotaVoz? nota = estado.nota;
    final String? erro = estado.erro;

    final (String titulo, String texto) = estado.aGravar
        ? (
            'A GRAVAR · ${formatarDuracao(estado.segundos)}',
            'Fala agora. Toca no ■ quando acabares (máximo 1 minuto).',
          )
        : nota != null
        ? (
            'NOTA GRAVADA · ${formatarDuracao(nota.duracaoSegundos)}',
            'Fica guardada com a paragem. Ouve-a para confirmar.',
          )
        : ('NOTA DE VOZ (OPCIONAL)', '$dica Toca no microfone para começar.');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoresApp.marinho,
        borderRadius: BorderRadius.circular(TemaApp.raio),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (nota == null || estado.aGravar)
                Material(
                  color: estado.aGravar
                      ? CoresApp.destaque
                      : CoresApp.terracota,
                  shape: const CircleBorder(
                    side: BorderSide(color: CoresApp.destaque, width: 3),
                  ),
                  child: IconButton(
                    iconSize: 32,
                    tooltip: estado.aGravar ? 'Parar' : 'Gravar',
                    icon: Icon(
                      estado.aGravar
                          ? Icons.stop_rounded
                          : Icons.mic_none_rounded,
                      color: estado.aGravar
                          ? CoresApp.marinho
                          : CoresApp.branco,
                    ),
                    onPressed: controlador.alternar,
                  ),
                )
              else
                const Icon(
                  Icons.check_circle,
                  size: 44,
                  color: CoresApp.destaque,
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: CoresApp.destaque,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      texto,
                      style: const TextStyle(
                        color: CoresApp.creme,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (erro != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                erro,
                style: const TextStyle(
                  color: CoresApp.destaque,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (nota != null && !estado.aGravar) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: CoresApp.destaque,
                    foregroundColor: CoresApp.marinho,
                  ),
                  onPressed: controlador.alternarOuvir,
                  icon: Icon(
                    estado.aOuvir
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(estado.aOuvir ? 'Parar' : 'Ouvir'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CoresApp.creme,
                    side: const BorderSide(color: CoresApp.creme),
                  ),
                  onPressed: controlador.alternar,
                  icon: const Icon(Icons.mic_none_rounded),
                  label: const Text('Gravar de novo'),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: CoresApp.creme),
                  onPressed: controlador.apagar,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Apagar'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
