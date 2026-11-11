import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;

import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/estado_permissao_localizacao.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/excecoes.dart';

abstract interface class RepositorioLocalizacao {
  Future<EstadoPermissaoLocalizacao> verificarPermissao();
  Future<EstadoPermissaoLocalizacao> pedirPermissao();
  Future<Coordenada> posicaoAtual();
  Stream<Coordenada> acompanharPosicao();
  Future<void> abrirDefinicoesApp();
  Future<void> abrirDefinicoesLocalizacao();
}

class RepositorioLocalizacaoGeolocator implements RepositorioLocalizacao {
  static const Duration _tempoLimite = Duration(seconds: 15);
  static const int _filtroDistanciaMetros = 20;

  Future<EstadoPermissaoLocalizacao> _estadoAtual() async {
    final bool servicoLigado = await geo.Geolocator.isLocationServiceEnabled();
    if (!servicoLigado) {
      return EstadoPermissaoLocalizacao.servicoDesligado;
    }
    final geo.LocationPermission permissao =
        await geo.Geolocator.checkPermission();
    return _converterPermissao(permissao);
  }

  EstadoPermissaoLocalizacao _converterPermissao(
    geo.LocationPermission permissao,
  ) {
    return switch (permissao) {
      geo.LocationPermission.always ||
      geo.LocationPermission.whileInUse => EstadoPermissaoLocalizacao.concedida,
      geo.LocationPermission.denied => EstadoPermissaoLocalizacao.negada,
      geo.LocationPermission.deniedForever =>
        EstadoPermissaoLocalizacao.negadaPermanente,
      geo.LocationPermission.unableToDetermine =>
        EstadoPermissaoLocalizacao.desconhecido,
    };
  }

  @override
  Future<EstadoPermissaoLocalizacao> verificarPermissao() => _estadoAtual();

  @override
  Future<EstadoPermissaoLocalizacao> pedirPermissao() async {
    final bool servicoLigado = await geo.Geolocator.isLocationServiceEnabled();
    if (!servicoLigado) {
      return EstadoPermissaoLocalizacao.servicoDesligado;
    }
    final geo.LocationPermission permissao =
        await geo.Geolocator.requestPermission();
    return _converterPermissao(permissao);
  }

  @override
  Future<Coordenada> posicaoAtual() async {
    try {
      final geo.Position posicao = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
        timeLimit: _tempoLimite,
      );
      return Coordenada(
        latitude: posicao.latitude,
        longitude: posicao.longitude,
      );
    } on TimeoutException {
      final geo.Position? ultima = await geo.Geolocator.getLastKnownPosition();
      if (ultima != null) {
        return Coordenada(
          latitude: ultima.latitude,
          longitude: ultima.longitude,
        );
      }
      throw const ExcecaoLocalizacao(
        'Não foi possível obter a tua localização. Tenta de novo.',
      );
    } on geo.LocationServiceDisabledException {
      throw const ExcecaoLocalizacao(
        'O GPS está desligado. Liga a localização para continuar.',
      );
    } catch (_) {
      throw const ExcecaoLocalizacao(
        'Não foi possível obter a tua localização. Tenta de novo.',
      );
    }
  }

  @override
  Stream<Coordenada> acompanharPosicao() {
    const geo.LocationSettings definicoes = geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: _filtroDistanciaMetros,
    );
    return geo.Geolocator.getPositionStream(locationSettings: definicoes).map(
      (geo.Position posicao) =>
          Coordenada(latitude: posicao.latitude, longitude: posicao.longitude),
    );
  }

  @override
  Future<void> abrirDefinicoesApp() => geo.Geolocator.openAppSettings();

  @override
  Future<void> abrirDefinicoesLocalizacao() =>
      geo.Geolocator.openLocationSettings();
}

/// Devolve sempre a mesma coordenada em Vilankulos e deixa escolher o
/// estado de permissão a devolver — para trabalhar nos ecrãs sem depender do
/// emulador nem do GPS real.
class RepositorioLocalizacaoSimulado implements RepositorioLocalizacao {
  RepositorioLocalizacaoSimulado({
    EstadoPermissaoLocalizacao estadoInicial =
        EstadoPermissaoLocalizacao.concedida,
  }) : _estado = estadoInicial;

  static const Duration _atraso = Duration(milliseconds: 600);
  static const Coordenada _coordenadaFixa = Coordenada(
    latitude: -21.9833,
    longitude: 35.3167,
  );

  EstadoPermissaoLocalizacao _estado;

  @override
  Future<EstadoPermissaoLocalizacao> verificarPermissao() async {
    await Future<void>.delayed(_atraso);
    return _estado;
  }

  @override
  Future<EstadoPermissaoLocalizacao> pedirPermissao() async {
    await Future<void>.delayed(_atraso);
    if (_estado == EstadoPermissaoLocalizacao.negada) {
      _estado = EstadoPermissaoLocalizacao.negadaPermanente;
    } else if (_estado != EstadoPermissaoLocalizacao.servicoDesligado) {
      _estado = EstadoPermissaoLocalizacao.concedida;
    }
    return _estado;
  }

  @override
  Future<Coordenada> posicaoAtual() async {
    await Future<void>.delayed(_atraso);
    if (_estado != EstadoPermissaoLocalizacao.concedida) {
      throw const ExcecaoLocalizacao(
        'Não foi possível obter a tua localização. Tenta de novo.',
      );
    }
    return _coordenadaFixa;
  }

  @override
  Stream<Coordenada> acompanharPosicao() async* {
    yield _coordenadaFixa;
  }

  @override
  Future<void> abrirDefinicoesApp() async {
    await Future<void>.delayed(_atraso);
  }

  @override
  Future<void> abrirDefinicoesLocalizacao() async {
    await Future<void>.delayed(_atraso);
    _estado = EstadoPermissaoLocalizacao.concedida;
  }
}

final Provider<RepositorioLocalizacao> repositorioLocalizacaoProvider =
    Provider<RepositorioLocalizacao>(
      (Ref ref) => RepositorioLocalizacaoGeolocator(),
    );
