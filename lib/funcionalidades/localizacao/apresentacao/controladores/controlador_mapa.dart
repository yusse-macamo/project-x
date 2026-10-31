import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/inicio/dados/repositorio_precos.dart';
import 'package:project_x/funcionalidades/inicio/dominio/excecao_precos.dart';
import 'package:project_x/funcionalidades/inicio/dominio/tipo_veiculo.dart';
import 'package:project_x/funcionalidades/localizacao/dados/repositorio_localizacao.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/estado_permissao_localizacao.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/excecoes.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/local.dart';

class EstadoMapa {
  const EstadoMapa({
    this.permissao = EstadoPermissaoLocalizacao.desconhecido,
    this.posicaoAtual,
    this.aCarregar = false,
    this.erro,
    this.destino,
    this.podeContinuarSemPosicao = false,
    this.precosEstimados,
    this.aCalcularPrecos = false,
  });

  final EstadoPermissaoLocalizacao permissao;
  final Coordenada? posicaoAtual;
  final bool aCarregar;
  final String? erro;
  final Local? destino;
  final bool podeContinuarSemPosicao;
  final Map<TipoVeiculo, double>? precosEstimados;
  final bool aCalcularPrecos;

  EstadoMapa copiarCom({
    EstadoPermissaoLocalizacao? permissao,
    Coordenada? posicaoAtual,
    bool? aCarregar,
    String? erro,
    Local? destino,
    bool? podeContinuarSemPosicao,
    Map<TipoVeiculo, double>? precosEstimados,
    bool? aCalcularPrecos,
    bool limparErro = false,
    bool limparDestino = false,
    bool limparPrecos = false,
  }) {
    return EstadoMapa(
      permissao: permissao ?? this.permissao,
      posicaoAtual: posicaoAtual ?? this.posicaoAtual,
      aCarregar: aCarregar ?? this.aCarregar,
      erro: limparErro ? null : (erro ?? this.erro),
      destino: limparDestino ? null : (destino ?? this.destino),
      podeContinuarSemPosicao:
          podeContinuarSemPosicao ?? this.podeContinuarSemPosicao,
      precosEstimados: limparPrecos
          ? null
          : (precosEstimados ?? this.precosEstimados),
      aCalcularPrecos: aCalcularPrecos ?? this.aCalcularPrecos,
    );
  }
}

class ControladorMapa extends Notifier<EstadoMapa> {
  static const Coordenada _centroVilankulos = Coordenada(
    latitude: -21.9833,
    longitude: 35.3167,
  );

  @override
  EstadoMapa build() => const EstadoMapa();

  RepositorioLocalizacao get _repositorio =>
      ref.read(repositorioLocalizacaoProvider);

  RepositorioPrecos get _repositorioPrecos =>
      ref.read(repositorioPrecosProvider);

  Future<void> iniciar() async {
    state = state.copiarCom(aCarregar: true, limparErro: true);
    final EstadoPermissaoLocalizacao permissao = await _repositorio
        .verificarPermissao();
    state = state.copiarCom(permissao: permissao, aCarregar: false);
    if (permissao == EstadoPermissaoLocalizacao.concedida) {
      await actualizarPosicao();
    }
  }

  Future<void> pedirPermissao() async {
    state = state.copiarCom(aCarregar: true, limparErro: true);
    final EstadoPermissaoLocalizacao permissao = await _repositorio
        .pedirPermissao();
    state = state.copiarCom(permissao: permissao, aCarregar: false);
    if (permissao == EstadoPermissaoLocalizacao.concedida) {
      await actualizarPosicao();
    }
  }

  Future<void> actualizarPosicao() async {
    state = state.copiarCom(aCarregar: true, limparErro: true);
    try {
      final Coordenada posicao = await _repositorio.posicaoAtual();
      state = state.copiarCom(posicaoAtual: posicao, aCarregar: false);
    } on ExcecaoLocalizacao catch (e) {
      state = state.copiarCom(aCarregar: false, erro: e.mensagem);
    }
  }

  Future<void> escolherDestino(Local local) async {
    state = state.copiarCom(
      destino: local,
      aCalcularPrecos: true,
      limparPrecos: true,
    );
    final Coordenada origem = state.posicaoAtual ?? _centroVilankulos;
    try {
      final Map<TipoVeiculo, double> precos = await _repositorioPrecos
          .estimarPrecos(origem: origem, destino: local.coordenada);
      if (state.destino != local) {
        return;
      }
      state = state.copiarCom(precosEstimados: precos, aCalcularPrecos: false);
    } on ExcecaoPrecos catch (e) {
      if (state.destino != local) {
        return;
      }
      state = state.copiarCom(aCalcularPrecos: false, erro: e.mensagem);
    }
  }

  void limparDestino() {
    state = state.copiarCom(limparDestino: true, limparPrecos: true);
  }

  void continuarSemLocalizacao() {
    state = state.copiarCom(podeContinuarSemPosicao: true);
  }

  Future<void> abrirDefinicoesApp() => _repositorio.abrirDefinicoesApp();

  Future<void> abrirDefinicoesLocalizacao() =>
      _repositorio.abrirDefinicoesLocalizacao();
}

final NotifierProvider<ControladorMapa, EstadoMapa> controladorMapaProvider =
    NotifierProvider<ControladorMapa, EstadoMapa>(ControladorMapa.new);
