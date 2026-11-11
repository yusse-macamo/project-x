import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/funcionalidades/corrida/dados/repositorio_corrida.dart';
import 'package:project_x/funcionalidades/corrida/dominio/corrida.dart';
import 'package:project_x/funcionalidades/inicio/dados/repositorio_precos.dart';
import 'package:project_x/funcionalidades/inicio/dominio/tipo_veiculo.dart';
import 'package:project_x/funcionalidades/localizacao/apresentacao/controladores/controlador_mapa.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/local.dart';
import 'package:project_x/funcionalidades/voz/dominio/nota_voz.dart';

enum FaseCorrida { semCorrida, motoqueiroACaminho, emViagem, avaliacao }

class EstadoCorrida {
  const EstadoCorrida({
    this.fase = FaseCorrida.semCorrida,
    this.corrida,
    this.tipoVeiculo = TipoVeiculo.mota,
    this.comCarga = false,
    this.temBarco = false,
    this.formaPagamento = FormaPagamento.dinheiro,
    this.notaPagamento = 500,
    this.notaVoz,
    this.aproximacao,
    this.progresso,
    this.aProcessar = false,
    this.erro,
  });

  final FaseCorrida fase;
  final Corrida? corrida;
  final TipoVeiculo tipoVeiculo;
  final bool comCarga;
  final bool temBarco;
  final FormaPagamento formaPagamento;
  final int notaPagamento;
  final NotaVoz? notaVoz;
  final AproximacaoMotoqueiro? aproximacao;
  final ProgressoViagem? progresso;
  final bool aProcessar;
  final String? erro;

  EstadoCorrida copiarCom({
    FaseCorrida? fase,
    Corrida? corrida,
    TipoVeiculo? tipoVeiculo,
    bool? comCarga,
    bool? temBarco,
    FormaPagamento? formaPagamento,
    int? notaPagamento,
    NotaVoz? notaVoz,
    AproximacaoMotoqueiro? aproximacao,
    ProgressoViagem? progresso,
    bool? aProcessar,
    String? erro,
    bool limparErro = false,
  }) {
    return EstadoCorrida(
      fase: fase ?? this.fase,
      corrida: corrida ?? this.corrida,
      tipoVeiculo: tipoVeiculo ?? this.tipoVeiculo,
      comCarga: comCarga ?? this.comCarga,
      temBarco: temBarco ?? this.temBarco,
      formaPagamento: formaPagamento ?? this.formaPagamento,
      notaPagamento: notaPagamento ?? this.notaPagamento,
      notaVoz: notaVoz ?? this.notaVoz,
      aproximacao: aproximacao ?? this.aproximacao,
      progresso: progresso ?? this.progresso,
      aProcessar: aProcessar ?? this.aProcessar,
      erro: limparErro ? null : (erro ?? this.erro),
    );
  }
}

class ControladorCorrida extends Notifier<EstadoCorrida> {
  static const Coordenada _centroVilankulos = Coordenada(
    latitude: -21.9833,
    longitude: 35.3167,
  );

  StreamSubscription<AproximacaoMotoqueiro>? _subAproximacao;
  StreamSubscription<ProgressoViagem>? _subProgresso;

  @override
  EstadoCorrida build() {
    ref.watch(
      controladorAutenticacaoProvider.select(
        (EstadoAutenticacao estado) => estado.utilizador?.id,
      ),
    );
    ref.onDispose(_cancelarSubscricoes);
    return const EstadoCorrida();
  }

  RepositorioCorrida get _repositorio => ref.read(repositorioCorridaProvider);

  bool get modoDeTeste => _repositorio.modoDeTeste;

  double? get extraCargaMt => ref.read(repositorioPrecosProvider).extraCargaMt;

  void _cancelarSubscricoes() {
    _subAproximacao?.cancel();
    _subProgresso?.cancel();
  }

  /// Preço a mostrar antes de pedir: a estimativa com o suplemento que o
  /// repositório indicar. O valor final vem sempre em [Corrida.preco].
  double? precoApresentado(Map<TipoVeiculo, double>? precos, TipoVeiculo tipo) {
    final double? base = precos?[tipo];
    if (base == null) {
      return null;
    }
    return base + (state.comCarga ? (extraCargaMt ?? 0) : 0);
  }

  bool notaChega(int nota, double? preco) => preco == null || nota >= preco;

  void escolherVeiculo(TipoVeiculo tipo) {
    state = state.copiarCom(tipoVeiculo: tipo);
  }

  void definirCarga(bool valor) => state = state.copiarCom(comCarga: valor);

  void definirBarco(bool valor) => state = state.copiarCom(temBarco: valor);

  void escolherPagamento(FormaPagamento forma) {
    state = state.copiarCom(formaPagamento: forma);
  }

  void escolherNota(int nota) => state = state.copiarCom(notaPagamento: nota);

  void definirNotaVoz(NotaVoz nota) => state = state.copiarCom(notaVoz: nota);

  void limparErro() => state = state.copiarCom(limparErro: true);

  Future<void> pedir({required String origemNome}) async {
    final EstadoMapa mapa = ref.read(controladorMapaProvider);
    final Local? destino = mapa.destino;
    if (destino == null || state.aProcessar) {
      return;
    }
    final double? preco = precoApresentado(
      mapa.precosEstimados,
      state.tipoVeiculo,
    );
    final bool emDinheiro = state.formaPagamento == FormaPagamento.dinheiro;
    if (emDinheiro && !notaChega(state.notaPagamento, preco)) {
      state = state.copiarCom(
        erro: 'Essa nota não chega para o preço. Escolhe uma nota maior.',
      );
      return;
    }
    state = state.copiarCom(aProcessar: true, limparErro: true);
    try {
      final Corrida corrida = await _repositorio.pedir(
        PedidoCorrida(
          origem: mapa.posicaoAtual ?? _centroVilankulos,
          origemNome: origemNome,
          destino: destino.coordenada,
          destinoNome: destino.nome,
          tipoVeiculo: state.tipoVeiculo,
          modoPreco: mapa.modoPreco,
          comCarga: state.comCarga,
          temBarco: state.temBarco,
          formaPagamento: state.formaPagamento,
          notaPagamento: emDinheiro ? state.notaPagamento : null,
          notaVoz: state.notaVoz,
        ),
      );
      state = state.copiarCom(
        fase: FaseCorrida.motoqueiroACaminho,
        corrida: corrida,
        aProcessar: false,
      );
      _subAproximacao = _repositorio
          .aproximacao(corrida)
          .listen(
            (AproximacaoMotoqueiro valor) =>
                state = state.copiarCom(aproximacao: valor),
          );
    } on ExcecaoCorrida catch (e) {
      state = state.copiarCom(aProcessar: false, erro: e.mensagem);
    }
  }

  Future<void> cancelar() async {
    final Corrida? corrida = state.corrida;
    if (corrida == null || state.aProcessar) {
      return;
    }
    state = state.copiarCom(aProcessar: true, limparErro: true);
    try {
      await _repositorio.cancelar(corrida);
      _terminarFluxo();
    } catch (_) {
      state = state.copiarCom(
        aProcessar: false,
        erro: 'Não foi possível cancelar. Tenta de novo.',
      );
    }
  }

  Future<void> confirmarSubida() async {
    final Corrida? corrida = state.corrida;
    if (corrida == null || state.aProcessar) {
      return;
    }
    state = state.copiarCom(aProcessar: true, limparErro: true);
    try {
      final Corrida atualizada = await _repositorio.confirmarSubida(corrida);
      unawaited(_subAproximacao?.cancel());
      state = state.copiarCom(
        fase: FaseCorrida.emViagem,
        corrida: atualizada,
        aProcessar: false,
      );
      _subProgresso = _repositorio
          .progresso(atualizada)
          .listen(
            (ProgressoViagem valor) =>
                state = state.copiarCom(progresso: valor),
          );
    } catch (_) {
      state = state.copiarCom(
        aProcessar: false,
        erro: 'Não foi possível confirmar. Tenta de novo.',
      );
    }
  }

  Future<void> adicionarParagem(Local local) async {
    final Corrida? corrida = state.corrida;
    if (corrida == null) {
      return;
    }
    try {
      final Corrida atualizada = await _repositorio.adicionarParagem(
        corrida,
        ParagemPercurso(nome: local.nome, coordenada: local.coordenada),
      );
      state = state.copiarCom(corrida: atualizada);
    } catch (_) {
      state = state.copiarCom(
        erro: 'Não foi possível juntar a paragem. Tenta de novo.',
      );
    }
  }

  Future<void> concluir() async {
    final Corrida? corrida = state.corrida;
    if (corrida == null || state.aProcessar) {
      return;
    }
    state = state.copiarCom(aProcessar: true, limparErro: true);
    try {
      final Corrida concluida = await _repositorio.concluir(corrida);
      unawaited(_subProgresso?.cancel());
      state = state.copiarCom(
        fase: FaseCorrida.avaliacao,
        corrida: concluida,
        aProcessar: false,
      );
    } catch (_) {
      state = state.copiarCom(
        aProcessar: false,
        erro: 'Não foi possível terminar a viagem. Tenta de novo.',
      );
    }
  }

  Future<void> avaliar({
    required int nota,
    required Set<String> etiquetas,
    required int gorjeta,
    String? comentario,
  }) async {
    final Corrida? corrida = state.corrida;
    if (corrida == null || state.aProcessar) {
      return;
    }
    state = state.copiarCom(aProcessar: true, limparErro: true);
    try {
      await _repositorio.avaliar(
        AvaliacaoCorrida(
          corridaId: corrida.id,
          nota: nota,
          etiquetas: etiquetas,
          gorjeta: gorjeta,
          comentario: comentario,
        ),
      );
      _terminarFluxo();
    } catch (_) {
      state = state.copiarCom(
        aProcessar: false,
        erro: 'Não foi possível enviar a avaliação. Tenta de novo.',
      );
    }
  }

  void saltarAvaliacao() => _terminarFluxo();

  /// Texto para a família acompanhar. Não inclui o código de subida.
  String textoPartilha() {
    final Corrida? corrida = state.corrida;
    if (corrida == null) {
      return '';
    }
    return 'Estou a caminho de ${corrida.pedido.destinoNome} com a ROTA. '
        'Colete nº ${corrida.motoqueiro.numeroColete}, '
        '${corrida.motoqueiro.descricaoVeiculo}, '
        'matrícula ${corrida.motoqueiro.matricula}.';
  }

  void _terminarFluxo() {
    _cancelarSubscricoes();
    ref.read(controladorMapaProvider.notifier).limparDestino();
    state = const EstadoCorrida();
  }
}

final NotifierProvider<ControladorCorrida, EstadoCorrida>
controladorCorridaProvider =
    NotifierProvider<ControladorCorrida, EstadoCorrida>(ControladorCorrida.new);

final FutureProvider<List<Corrida>> historicoCorridasProvider =
    FutureProvider<List<Corrida>>((Ref ref) {
      ref.watch(controladorCorridaProvider.select((EstadoCorrida e) => e.fase));
      return ref.read(repositorioCorridaProvider).historico();
    });
