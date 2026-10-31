import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/localizacao/dados/repositorio_lugares.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/excecoes.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/local.dart';

const int _tamanhoMinimoTermo = 3;
const Duration _atrasoDebounce = Duration(milliseconds: 600);

class EstadoPesquisaDestino {
  const EstadoPesquisaDestino({
    this.termo = '',
    this.resultados = const <Local>[],
    this.aPesquisar = false,
    this.erro,
    this.jaPesquisouAlgumaVez = false,
  });

  final String termo;
  final List<Local> resultados;
  final bool aPesquisar;
  final String? erro;
  final bool jaPesquisouAlgumaVez;

  EstadoPesquisaDestino copiarCom({
    String? termo,
    List<Local>? resultados,
    bool? aPesquisar,
    String? erro,
    bool? jaPesquisouAlgumaVez,
    bool limparErro = false,
  }) {
    return EstadoPesquisaDestino(
      termo: termo ?? this.termo,
      resultados: resultados ?? this.resultados,
      aPesquisar: aPesquisar ?? this.aPesquisar,
      erro: limparErro ? null : (erro ?? this.erro),
      jaPesquisouAlgumaVez: jaPesquisouAlgumaVez ?? this.jaPesquisouAlgumaVez,
    );
  }
}

class ControladorPesquisaDestino extends Notifier<EstadoPesquisaDestino> {
  Timer? _temporizadorDebounce;
  int _geracao = 0;

  @override
  EstadoPesquisaDestino build() {
    ref.onDispose(() => _temporizadorDebounce?.cancel());
    return const EstadoPesquisaDestino();
  }

  RepositorioLugares get _repositorio => ref.read(repositorioLugaresProvider);

  Future<void> carregarSugestoesIniciais({Coordenada? perto}) =>
      _pesquisarAgora('', perto: perto);

  void mudarTermo(String termo, {Coordenada? perto}) {
    _temporizadorDebounce?.cancel();
    state = state.copiarCom(termo: termo, limparErro: true);

    if (termo.trim().length < _tamanhoMinimoTermo) {
      return;
    }

    _temporizadorDebounce = Timer(_atrasoDebounce, () {
      _pesquisarAgora(termo, perto: perto);
    });
  }

  void tentarNovamente({Coordenada? perto}) {
    _pesquisarAgora(state.termo, perto: perto);
  }

  Future<void> _pesquisarAgora(String termo, {Coordenada? perto}) async {
    final int geracaoDoPedido = ++_geracao;
    state = state.copiarCom(aPesquisar: true, limparErro: true);
    try {
      final List<Local> resultados = await _repositorio.pesquisar(
        termo,
        perto: perto,
      );
      if (geracaoDoPedido != _geracao) {
        return;
      }
      state = state.copiarCom(
        resultados: resultados,
        aPesquisar: false,
        jaPesquisouAlgumaVez: true,
      );
    } on ExcecaoPesquisa catch (e) {
      if (geracaoDoPedido != _geracao) {
        return;
      }
      state = state.copiarCom(
        aPesquisar: false,
        erro: e.mensagem,
        jaPesquisouAlgumaVez: true,
      );
    }
  }
}

final NotifierProvider<ControladorPesquisaDestino, EstadoPesquisaDestino>
controladorPesquisaDestinoProvider =
    NotifierProvider<ControladorPesquisaDestino, EstadoPesquisaDestino>(
      ControladorPesquisaDestino.new,
    );
