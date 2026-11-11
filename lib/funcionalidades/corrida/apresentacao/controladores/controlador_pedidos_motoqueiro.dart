import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/funcionalidades/corrida/dados/repositorio_corrida.dart';
import 'package:project_x/funcionalidades/corrida/dominio/corrida.dart';

enum FaseMotoqueiro { livre, pedidoRecebido, aCaminhoDaRecolha, emViagem }

class EstadoPedidosMotoqueiro {
  const EstadoPedidosMotoqueiro({
    this.fase = FaseMotoqueiro.livre,
    this.disponivel = false,
    this.pedido,
    this.segundosRestantes = 0,
    this.aProcessar = false,
    this.erro,
  });

  final FaseMotoqueiro fase;
  final bool disponivel;
  final PedidoParaMotoqueiro? pedido;
  final int segundosRestantes;
  final bool aProcessar;
  final String? erro;
}

class ControladorPedidosMotoqueiro extends Notifier<EstadoPedidosMotoqueiro> {
  static const int _segundosParaAceitar = 15;

  StreamSubscription<PedidoParaMotoqueiro>? _subPedidos;
  Timer? _contagem;

  @override
  EstadoPedidosMotoqueiro build() {
    ref.watch(
      controladorAutenticacaoProvider.select(
        (EstadoAutenticacao estado) => estado.utilizador?.id,
      ),
    );
    ref.onDispose(_pararTudo);
    return const EstadoPedidosMotoqueiro();
  }

  RepositorioPedidosMotoqueiro get _repositorio =>
      ref.read(repositorioPedidosMotoqueiroProvider);

  String? get codigoDeTeste => _repositorio.codigoDeTeste;
  bool get modoDeTeste => _repositorio.modoDeTeste;

  void _pararTudo() {
    _subPedidos?.cancel();
    _subPedidos = null;
    _contagem?.cancel();
  }

  void definirDisponivel(bool disponivel) {
    _pararTudo();
    state = EstadoPedidosMotoqueiro(disponivel: disponivel);
    if (disponivel) {
      _ouvirPedidos();
    }
  }

  void _ouvirPedidos() {
    _subPedidos?.cancel();
    _subPedidos = _repositorio.pedidosDisponiveis().listen(_receberPedido);
  }

  void _receberPedido(PedidoParaMotoqueiro pedido) {
    if (state.fase != FaseMotoqueiro.livre) {
      return;
    }
    _subPedidos?.cancel();
    _subPedidos = null;
    state = EstadoPedidosMotoqueiro(
      fase: FaseMotoqueiro.pedidoRecebido,
      disponivel: true,
      pedido: pedido,
      segundosRestantes: _segundosParaAceitar,
    );
    _contagem = Timer.periodic(const Duration(seconds: 1), (Timer _) {
      final int restantes = state.segundosRestantes - 1;
      if (restantes <= 0) {
        recusar();
        return;
      }
      state = EstadoPedidosMotoqueiro(
        fase: state.fase,
        disponivel: state.disponivel,
        pedido: state.pedido,
        segundosRestantes: restantes,
        aProcessar: state.aProcessar,
      );
    });
  }

  Future<void> recusar() async {
    _contagem?.cancel();
    final PedidoParaMotoqueiro? pedido = state.pedido;
    if (pedido != null) {
      await _repositorio.recusar(pedido);
    }
    _voltarAFicarLivre();
  }

  void _voltarAFicarLivre() {
    _contagem?.cancel();
    state = const EstadoPedidosMotoqueiro(disponivel: true);
    _ouvirPedidos();
  }

  Future<void> aceitar() async {
    final PedidoParaMotoqueiro? pedido = state.pedido;
    if (pedido == null || state.aProcessar) {
      return;
    }
    _contagem?.cancel();
    state = EstadoPedidosMotoqueiro(
      fase: state.fase,
      disponivel: true,
      pedido: pedido,
      segundosRestantes: state.segundosRestantes,
      aProcessar: true,
    );
    try {
      await _repositorio.aceitar(pedido);
      state = EstadoPedidosMotoqueiro(
        fase: FaseMotoqueiro.aCaminhoDaRecolha,
        disponivel: true,
        pedido: pedido,
      );
    } catch (_) {
      _voltarAFicarLivre();
      state = const EstadoPedidosMotoqueiro(
        disponivel: true,
        erro: 'Este pedido já não está disponível.',
      );
    }
  }

  Future<void> iniciar(String codigo) async {
    final PedidoParaMotoqueiro? pedido = state.pedido;
    if (pedido == null || state.aProcessar) {
      return;
    }
    state = EstadoPedidosMotoqueiro(
      fase: state.fase,
      disponivel: true,
      pedido: pedido,
      aProcessar: true,
    );
    try {
      await _repositorio.iniciar(pedido, codigo);
      state = EstadoPedidosMotoqueiro(
        fase: FaseMotoqueiro.emViagem,
        disponivel: true,
        pedido: pedido,
      );
    } on ExcecaoCorrida catch (e) {
      state = EstadoPedidosMotoqueiro(
        fase: state.fase,
        disponivel: true,
        pedido: pedido,
        erro: e.mensagem,
      );
    }
  }

  Future<void> terminar() async {
    final PedidoParaMotoqueiro? pedido = state.pedido;
    if (pedido == null || state.aProcessar) {
      return;
    }
    state = EstadoPedidosMotoqueiro(
      fase: state.fase,
      disponivel: true,
      pedido: pedido,
      aProcessar: true,
    );
    await _repositorio.terminar(pedido);
    _voltarAFicarLivre();
  }
}

final NotifierProvider<ControladorPedidosMotoqueiro, EstadoPedidosMotoqueiro>
controladorPedidosMotoqueiroProvider =
    NotifierProvider<ControladorPedidosMotoqueiro, EstadoPedidosMotoqueiro>(
      ControladorPedidosMotoqueiro.new,
    );
