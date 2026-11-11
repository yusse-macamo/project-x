import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/voz/dados/reconhecedor_voz.dart';
import 'package:project_x/funcionalidades/voz/dominio/excecao_voz.dart';

class EstadoDitado {
  const EstadoDitado({this.aOuvir = false, this.textoParcial = '', this.erro});

  final bool aOuvir;
  final String textoParcial;
  final String? erro;
}

/// Ditar em vez de escrever: devolve a frase que a pessoa disse.
class ControladorDitado extends AutoDisposeNotifier<EstadoDitado> {
  bool _libertado = false;
  bool _aOuvir = false;

  @override
  EstadoDitado build() {
    // O ref não pode ser usado dentro do onDispose.
    final ReconhecedorVoz reconhecedor = ref.read(reconhecedorVozProvider);
    ref.onDispose(() {
      _libertado = true;
      if (_aOuvir) {
        reconhecedor.parar();
      }
    });
    return const EstadoDitado();
  }

  /// `null` quando não se percebeu nada ou houve erro (fica em
  /// [EstadoDitado.erro]).
  Future<String?> ditar({
    List<String> frasesProvaveis = const <String>[],
  }) async {
    if (state.aOuvir) {
      await ref.read(reconhecedorVozProvider).parar();
      return null;
    }
    state = const EstadoDitado(aOuvir: true);
    _aOuvir = true;
    try {
      final String? frase = await ref
          .read(reconhecedorVozProvider)
          .ouvir(
            frasesProvaveis: frasesProvaveis,
            aoOuvir: (String parcial) {
              if (!_libertado) {
                state = EstadoDitado(aOuvir: true, textoParcial: parcial);
              }
            },
          );
      _aOuvir = false;
      if (_libertado) {
        return null;
      }
      state = EstadoDitado(
        textoParcial: frase ?? '',
        erro: frase == null
            ? 'Não percebemos. Toca no microfone e diz o nome do lugar outra '
                  'vez.'
            : null,
      );
      return frase;
    } on ExcecaoVoz catch (e) {
      _aOuvir = false;
      if (!_libertado) {
        state = EstadoDitado(erro: e.mensagem);
      }
      return null;
    }
  }

  /// Esquece o último texto e o último erro (ao sair da procura).
  void limpar() {
    if (!_aOuvir) {
      state = const EstadoDitado();
    }
  }
}

final AutoDisposeNotifierProvider<ControladorDitado, EstadoDitado>
controladorDitadoProvider =
    AutoDisposeNotifierProvider<ControladorDitado, EstadoDitado>(
      ControladorDitado.new,
    );
