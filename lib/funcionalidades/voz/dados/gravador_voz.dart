import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

import 'package:project_x/funcionalidades/voz/dominio/excecao_voz.dart';
import 'package:project_x/funcionalidades/voz/dominio/nota_voz.dart';

/// Grava e reproduz notas de voz curtas: m4a no telemóvel, WebM/Opus em
/// memória no browser (o caminho passa a ser um endereço `blob:`).
abstract interface class GravadorVoz {
  /// Lança [ExcecaoVoz] se não houver acesso ao microfone.
  Future<void> iniciar();
  Future<NotaVoz?> parar(int duracaoSegundos);

  /// Termina quando a nota acaba de tocar ou quando [pararDeOuvir] é chamado.
  Future<void> ouvir(NotaVoz nota);
  Future<void> pararDeOuvir();
  Future<void> libertar();
}

class GravadorVozDispositivo implements GravadorVoz {
  final AudioRecorder _gravador = AudioRecorder();
  final AudioPlayer _leitor = AudioPlayer();

  @override
  Future<void> iniciar() async {
    if (!await _gravador.hasPermission()) {
      throw const ExcecaoVoz(
        'Sem acesso ao microfone. Permite-o nas definições do telemóvel para '
        'gravar a nota de voz.',
      );
    }
    try {
      if (kIsWeb) {
        await _gravador.start(
          const RecordConfig(encoder: AudioEncoder.opus),
          path: '',
        );
        return;
      }
      final String caminho =
          '${Directory.systemTemp.path}/nota-'
          '${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _gravador.start(const RecordConfig(), path: caminho);
    } catch (_) {
      throw const ExcecaoVoz(
        'Não foi possível começar a gravar. Tenta de novo.',
      );
    }
  }

  @override
  Future<NotaVoz?> parar(int duracaoSegundos) async {
    final String? caminho = await _gravador.stop();
    if (caminho == null || duracaoSegundos < 1) {
      return null;
    }
    return NotaVoz(caminho: caminho, duracaoSegundos: duracaoSegundos);
  }

  @override
  Future<void> ouvir(NotaVoz nota) async {
    try {
      if (kIsWeb) {
        await _leitor.setUrl(nota.caminho);
      } else {
        await _leitor.setFilePath(nota.caminho);
      }
      // O `play()` do just_audio não termina quando o som acaba; espera-se
      // pelo fim (completed) ou pela paragem (idle, depois de stop()).
      final Future<ProcessingState> fim = _leitor.processingStateStream
          .firstWhere(
            (ProcessingState estado) =>
                estado == ProcessingState.completed ||
                estado == ProcessingState.idle,
          );
      unawaited(_leitor.play());
      await fim;
    } catch (_) {
      throw const ExcecaoVoz('Não foi possível tocar a nota. Grava de novo.');
    } finally {
      await _leitor.stop();
    }
  }

  @override
  Future<void> pararDeOuvir() => _leitor.stop();

  @override
  Future<void> libertar() async {
    await _gravador.dispose();
    await _leitor.dispose();
  }
}

final Provider<GravadorVoz> gravadorVozProvider = Provider<GravadorVoz>((
  Ref ref,
) {
  final GravadorVoz gravador = GravadorVozDispositivo();
  ref.onDispose(gravador.libertar);
  return gravador;
});
