import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';
import 'package:project_x/funcionalidades/paragens/dados/repositorio_paragens.dart';
import 'package:project_x/funcionalidades/paragens/dominio/paragem.dart';
import 'package:project_x/funcionalidades/voz/dominio/nota_voz.dart';

const double _raioMarcoProximo = 3000;

class EstadoParagens {
  const EstadoParagens({
    this.marcos = const <MarcoConhecido>[],
    this.comunidade = const <Paragem>[],
    this.minhas = const <Paragem>[],
    this.aCarregar = false,
    this.aGravar = false,
    this.erro,
  });

  final List<MarcoConhecido> marcos;
  final List<Paragem> comunidade;
  final List<Paragem> minhas;
  final bool aCarregar;
  final bool aGravar;
  final String? erro;

  EstadoParagens copiarCom({
    List<MarcoConhecido>? marcos,
    List<Paragem>? comunidade,
    List<Paragem>? minhas,
    bool? aCarregar,
    bool? aGravar,
    String? erro,
    bool limparErro = false,
  }) {
    return EstadoParagens(
      marcos: marcos ?? this.marcos,
      comunidade: comunidade ?? this.comunidade,
      minhas: minhas ?? this.minhas,
      aCarregar: aCarregar ?? this.aCarregar,
      aGravar: aGravar ?? this.aGravar,
      erro: limparErro ? null : (erro ?? this.erro),
    );
  }

  /// O marco mais perto, se estiver a menos de [_raioMarcoProximo]; longe
  /// de todos, "Perto de: …" seria enganador.
  MarcoConhecido? marcoMaisProximo(Coordenada posicao) {
    MarcoConhecido? maisProximo;
    double menorDistancia = _raioMarcoProximo;
    for (final MarcoConhecido marco in marcos) {
      final double distancia = marco.coordenada.distanciaEmMetrosAte(posicao);
      if (distancia < menorDistancia) {
        menorDistancia = distancia;
        maisProximo = marco;
      }
    }
    return maisProximo;
  }
}

class ControladorParagens extends Notifier<EstadoParagens> {
  @override
  EstadoParagens build() => const EstadoParagens();

  RepositorioParagens get _repositorio => ref.read(repositorioParagensProvider);

  Future<void> carregar() async {
    state = state.copiarCom(aCarregar: true, limparErro: true);
    try {
      final List<MarcoConhecido> marcos = await _repositorio.listarMarcos();
      final List<Paragem> comunidade = await _repositorio.listarComunidade();
      final List<Paragem> minhas = await _repositorio.listarMinhas();
      state = state.copiarCom(
        marcos: marcos,
        comunidade: comunidade
            .where((Paragem paragem) => paragem.visivelNaComunidade)
            .toList(),
        minhas: minhas,
        aCarregar: false,
      );
    } catch (_) {
      state = state.copiarCom(
        aCarregar: false,
        erro: 'Não foi possível carregar os lugares. Tenta de novo.',
      );
    }
  }

  /// Devolve a paragem gravada, ou `null` se falhar (o motivo fica em `erro`).
  Future<Paragem?> gravar({
    required String nome,
    required Coordenada coordenada,
    required CategoriaParagem categoria,
    required bool partilhar,
    NotaVoz? notaVoz,
    String? caminhoFoto,
  }) async {
    final String nomeLimpo = nome.trim();
    if (nomeLimpo.length < 3) {
      state = state.copiarCom(
        erro: 'Escreve o nome que toda a gente conhece, com 3 letras ou mais.',
      );
      return null;
    }
    state = state.copiarCom(aGravar: true, limparErro: true);
    try {
      final Paragem paragem = await _repositorio.gravar(
        nome: nomeLimpo,
        coordenada: coordenada,
        categoria: categoria,
        partilhar: partilhar,
        notaVoz: notaVoz,
        caminhoFoto: caminhoFoto,
      );
      state = state.copiarCom(
        aGravar: false,
        minhas: <Paragem>[...state.minhas, paragem],
      );
      return paragem;
    } catch (_) {
      state = state.copiarCom(
        aGravar: false,
        erro: 'Não foi possível gravar a paragem. Tenta de novo.',
      );
      return null;
    }
  }
}

final NotifierProvider<ControladorParagens, EstadoParagens>
controladorParagensProvider =
    NotifierProvider<ControladorParagens, EstadoParagens>(
      ControladorParagens.new,
    );
