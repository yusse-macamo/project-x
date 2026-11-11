import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:project_x/funcionalidades/voz/dominio/excecao_voz.dart';

/// Voz para texto, com o reconhecimento do próprio telemóvel.
abstract interface class ReconhecedorVoz {
  /// Ouve até a pessoa parar de falar. [aoOuvir] recebe o texto parcial
  /// enquanto fala; o `Future` devolve a frase final, ou `null` se nada foi
  /// percebido. Lança [ExcecaoVoz] com a mensagem para mostrar.
  Future<String?> ouvir({
    required void Function(String textoParcial) aoOuvir,
    List<String> frasesProvaveis = const <String>[],
  });

  Future<void> parar();
}

class ReconhecedorVozDispositivo implements ReconhecedorVoz {
  static const List<String> _idiomasPreferidos = <String>[
    'pt_MZ',
    'pt_PT',
    'pt_BR',
  ];

  final SpeechToText _fala = SpeechToText();
  bool _pronto = false;
  String? _idioma;
  Completer<String?>? _pedido;
  String _ultimoTexto = '';

  Future<void> _preparar() async {
    if (_pronto) {
      return;
    }
    final bool disponivel = await _fala.initialize(
      onError: _aoFalhar,
      onStatus: _aoMudarEstado,
    );
    if (!disponivel) {
      throw const ExcecaoVoz(
        'Não foi possível usar o microfone. Permite o acesso ao microfone nas '
        'definições do telemóvel, ou escreve o destino.',
      );
    }
    _pronto = true;
    // O id vai tal como o telemóvel o dá ("pt-MZ" ou "pt_MZ"); só a
    // comparação ignora a diferença.
    final List<LocaleName> idiomas = await _fala.locales();
    String normal(String id) => id.replaceAll('-', '_');
    _idioma =
        _idiomasPreferidos
            .map(
              (String preferido) => idiomas
                  .where((LocaleName i) => normal(i.localeId) == preferido)
                  .firstOrNull,
            )
            .nonNulls
            .firstOrNull
            ?.localeId ??
        idiomas
            .where((LocaleName i) => normal(i.localeId).startsWith('pt'))
            .firstOrNull
            ?.localeId;
    debugPrint('ReconhecedorVoz: idioma $_idioma');
  }

  @override
  Future<String?> ouvir({
    required void Function(String textoParcial) aoOuvir,
    List<String> frasesProvaveis = const <String>[],
  }) async {
    await _preparar();
    if (_fala.isListening) {
      await _fala.cancel();
    }
    final Completer<String?> pedido = Completer<String?>();
    _pedido = pedido;
    _ultimoTexto = '';
    await _fala.listen(
      onResult: (SpeechRecognitionResult resultado) {
        _ultimoTexto = resultado.recognizedWords;
        aoOuvir(_ultimoTexto);
        if (resultado.finalResult) {
          _concluir(_ultimoTexto);
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: _idioma,
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.search,
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
        contextualPhrases: frasesProvaveis,
      ),
    );
    return pedido.future;
  }

  @override
  Future<void> parar() async {
    await _fala.stop();
    _concluir(_ultimoTexto);
  }

  void _concluir(String texto) {
    final Completer<String?>? pedido = _pedido;
    if (pedido == null || pedido.isCompleted) {
      return;
    }
    _pedido = null;
    pedido.complete(texto.trim().isEmpty ? null : texto.trim());
  }

  void _aoMudarEstado(String estado) {
    if (estado == SpeechToText.doneStatus) {
      // O resultado final pode chegar logo depois do "done".
      Future<void>.delayed(
        const Duration(milliseconds: 500),
        () => _concluir(_ultimoTexto),
      );
    }
  }

  void _aoFalhar(SpeechRecognitionError erro) {
    debugPrint('ReconhecedorVoz: erro ${erro.errorMsg}');
    final Completer<String?>? pedido = _pedido;
    if (pedido == null || pedido.isCompleted) {
      return;
    }
    _pedido = null;
    if (erro.errorMsg == 'error_no_match' ||
        erro.errorMsg == 'error_speech_timeout') {
      pedido.complete(null);
      return;
    }
    pedido.completeError(ExcecaoVoz(_traduzir(erro.errorMsg)));
  }

  static String _traduzir(String codigo) => switch (codigo) {
    'error_network' || 'error_network_timeout' || 'error_server' =>
      'Sem internet para reconhecer a voz. Escreve o destino ou tenta de novo.',
    'error_permission' || 'error_insufficient_permissions' =>
      'Sem acesso ao microfone. Permite-o nas definições do telemóvel.',
    'error_busy' || 'error_recognizer_busy' =>
      'O microfone está ocupado. Espera um momento e tenta de novo.',
    _ => 'Não foi possível ouvir. Toca no microfone e tenta de novo.',
  };
}

final Provider<ReconhecedorVoz> reconhecedorVozProvider =
    Provider<ReconhecedorVoz>((Ref ref) => ReconhecedorVozDispositivo());
