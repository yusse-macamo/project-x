import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/voz/dados/gravador_voz.dart';
import 'package:project_x/funcionalidades/voz/dominio/excecao_voz.dart';
import 'package:project_x/funcionalidades/voz/dominio/nota_voz.dart';

class EstadoGravacao {
  const EstadoGravacao({
    this.aGravar = false,
    this.aOuvir = false,
    this.segundos = 0,
    this.nota,
    this.erro,
  });

  final bool aGravar;
  final bool aOuvir;
  final int segundos;
  final NotaVoz? nota;
  final String? erro;

  EstadoGravacao copiarCom({
    bool? aGravar,
    bool? aOuvir,
    int? segundos,
    NotaVoz? nota,
    String? erro,
    bool limparErro = false,
  }) {
    return EstadoGravacao(
      aGravar: aGravar ?? this.aGravar,
      aOuvir: aOuvir ?? this.aOuvir,
      segundos: segundos ?? this.segundos,
      nota: nota ?? this.nota,
      erro: limparErro ? null : (erro ?? this.erro),
    );
  }
}

class ControladorGravacao extends AutoDisposeNotifier<EstadoGravacao> {
  static const int _duracaoMaxima = 60;

  Timer? _temporizador;
  bool _libertado = false;

  @override
  EstadoGravacao build() {
    // O ref não pode ser usado dentro do onDispose.
    final GravadorVoz gravador = ref.read(gravadorVozProvider);
    ref.onDispose(() {
      _libertado = true;
      _temporizador?.cancel();
      if (state.aGravar) {
        gravador.parar(0);
      }
      if (state.aOuvir) {
        gravador.pararDeOuvir();
      }
    });
    return const EstadoGravacao();
  }

  GravadorVoz get _gravador => ref.read(gravadorVozProvider);

  Future<void> alternar() async {
    if (state.aGravar) {
      await _parar();
      return;
    }
    if (state.aOuvir) {
      await _gravador.pararDeOuvir();
    }
    try {
      await _gravador.iniciar();
    } on ExcecaoVoz catch (e) {
      state = state.copiarCom(erro: e.mensagem);
      return;
    }
    state = const EstadoGravacao(aGravar: true);
    _temporizador = Timer.periodic(const Duration(seconds: 1), (Timer _) {
      final int segundos = state.segundos + 1;
      state = state.copiarCom(segundos: segundos);
      if (segundos >= _duracaoMaxima) {
        _parar();
      }
    });
  }

  Future<void> _parar() async {
    _temporizador?.cancel();
    final int segundos = state.segundos;
    final NotaVoz? nota = await _gravador.parar(segundos);
    if (!_libertado) {
      state = EstadoGravacao(segundos: segundos, nota: nota);
    }
  }

  Future<void> apagar() async {
    if (state.aOuvir) {
      await _gravador.pararDeOuvir();
    }
    if (!_libertado) {
      state = const EstadoGravacao();
    }
  }

  Future<void> alternarOuvir() async {
    final NotaVoz? nota = state.nota;
    if (nota == null || state.aGravar) {
      return;
    }
    if (state.aOuvir) {
      await _gravador.pararDeOuvir();
      return;
    }
    state = state.copiarCom(aOuvir: true, limparErro: true);
    try {
      await _gravador.ouvir(nota);
      if (!_libertado) {
        state = state.copiarCom(aOuvir: false);
      }
    } on ExcecaoVoz catch (e) {
      if (!_libertado) {
        state = state.copiarCom(aOuvir: false, erro: e.mensagem);
      }
    }
  }
}

final AutoDisposeNotifierProvider<ControladorGravacao, EstadoGravacao>
controladorGravacaoProvider =
    AutoDisposeNotifierProvider<ControladorGravacao, EstadoGravacao>(
      ControladorGravacao.new,
    );
