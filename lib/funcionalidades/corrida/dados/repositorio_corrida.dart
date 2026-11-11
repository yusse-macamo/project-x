import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/corrida/dominio/corrida.dart';
import 'package:project_x/funcionalidades/inicio/dados/repositorio_precos.dart';
import 'package:project_x/funcionalidades/inicio/dominio/excecao_precos.dart';
import 'package:project_x/funcionalidades/inicio/dominio/tipo_veiculo.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';
import 'package:project_x/funcionalidades/voz/dominio/nota_voz.dart';
import 'package:project_x/nucleo/constantes/padrao_capulana.dart';

abstract interface class RepositorioCorrida {
  /// `true` enquanto o motoqueiro for fictício. Os ecrãs têm de o dizer.
  bool get modoDeTeste;

  Future<Corrida> pedir(PedidoCorrida pedido);
  Stream<AproximacaoMotoqueiro> aproximacao(Corrida corrida);
  Future<Corrida> confirmarSubida(Corrida corrida);
  Stream<ProgressoViagem> progresso(Corrida corrida);
  Future<Corrida> adicionarParagem(Corrida corrida, ParagemPercurso paragem);
  Future<void> cancelar(Corrida corrida);
  Future<Corrida> concluir(Corrida corrida);
  Future<void> avaliar(AvaliacaoCorrida avaliacao);
  Future<List<Corrida>> historico();
}

abstract interface class RepositorioPedidosMotoqueiro {
  bool get modoDeTeste;
  String? get codigoDeTeste;

  Stream<PedidoParaMotoqueiro> pedidosDisponiveis();
  Future<void> aceitar(PedidoParaMotoqueiro pedido);
  Future<void> recusar(PedidoParaMotoqueiro pedido);

  /// Lança [ExcecaoCorrida] se o código não for o do passageiro.
  Future<void> iniciar(PedidoParaMotoqueiro pedido, String codigo);
  Future<void> terminar(PedidoParaMotoqueiro pedido);
}

class RepositorioCorridaSimulado implements RepositorioCorrida {
  RepositorioCorridaSimulado({required this._precos});

  static const Duration _intervalo = Duration(seconds: 3);
  static const double _metrosIniciais = 450;

  final RepositorioPrecos _precos;
  final Random _aleatorio = Random();
  final List<Corrida> _historico = <Corrida>[];

  @override
  bool get modoDeTeste => true;

  @override
  Future<Corrida> pedir(PedidoCorrida pedido) async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    final Map<TipoVeiculo, double> precos;
    try {
      precos = await _precos.estimarPrecos(
        origem: pedido.origem,
        destino: pedido.destino,
        modo: pedido.modoPreco,
      );
    } on ExcecaoPrecos catch (e) {
      throw ExcecaoCorrida(e.mensagem);
    }
    final double? precoBase = precos[pedido.tipoVeiculo];
    if (precoBase == null) {
      throw const ExcecaoCorrida(
        'Este veículo não está disponível agora. Escolhe outro.',
      );
    }
    final double preco =
        precoBase + (pedido.comCarga ? (_precos.extraCargaMt ?? 0) : 0);
    final int? nota = pedido.notaPagamento;
    if (nota != null && nota < preco) {
      throw const ExcecaoCorrida(
        'Essa nota não chega para o preço. Escolhe uma nota maior.',
      );
    }
    final double km = pedido.origem.distanciaEmMetrosAte(pedido.destino) / 1000;
    return Corrida(
      id: 'c-${DateTime.now().millisecondsSinceEpoch}',
      pedido: pedido,
      motoqueiro: const MotoqueiroAtribuido(
        nome: 'Abílio M.',
        avaliacao: 4.8,
        viagens: 312,
        numeroColete: '027',
        matricula: 'AFR 482 MP',
        descricaoVeiculo: 'Mota Boxer branca',
        telefone: '841234567',
        praca: 'praça das Bombas',
        registadoNaAssociacao: true,
        temCapaceteExtra: true,
      ),
      preco: preco,
      distanciaKm: km,
      minutosViagem: max(2, (km * 3.2).round()),
      codigoSubida: (1000 + _aleatorio.nextInt(9000)).toString(),
    );
  }

  @override
  Stream<AproximacaoMotoqueiro> aproximacao(Corrida corrida) {
    final Coordenada recolha = corrida.pedido.origem;
    final Coordenada partida = Coordenada(
      latitude: recolha.latitude + 0.004,
      longitude: recolha.longitude - 0.001,
    );
    return Stream<AproximacaoMotoqueiro>.periodic(_intervalo, (int passo) {
      final double fracao = min(1, (passo + 1) / 12);
      return AproximacaoMotoqueiro(
        metros: max(20, _metrosIniciais * (1 - fracao)),
        posicao: partida.interpolarAte(recolha, fracao),
      );
    }).take(12);
  }

  @override
  Future<Corrida> confirmarSubida(Corrida corrida) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return corrida.copiarCom(iniciadaEm: DateTime.now());
  }

  @override
  Stream<ProgressoViagem> progresso(Corrida corrida) {
    return Stream<ProgressoViagem>.periodic(_intervalo, (int passo) {
      final double fracao = min(1, (passo + 1) * 0.05);
      return ProgressoViagem(
        fracao: fracao,
        kmRestantes: corrida.distanciaKm * (1 - fracao),
        posicao: corrida.pedido.origem.interpolarAte(
          corrida.pedido.destino,
          fracao,
        ),
      );
    }).take(20);
  }

  @override
  Future<Corrida> adicionarParagem(
    Corrida corrida,
    ParagemPercurso paragem,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return corrida.copiarCom(
      paragens: <ParagemPercurso>[...corrida.paragens, paragem],
    );
  }

  @override
  Future<void> cancelar(Corrida corrida) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<Corrida> concluir(Corrida corrida) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final Corrida concluida = corrida.copiarCom(concluidaEm: DateTime.now());
    _historico.insert(0, concluida);
    return concluida;
  }

  @override
  Future<void> avaliar(AvaliacaoCorrida avaliacao) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<List<Corrida>> historico() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List<Corrida>.unmodifiable(_historico);
  }
}

class RepositorioPedidosMotoqueiroSimulado
    implements RepositorioPedidosMotoqueiro {
  static const String _codigo = '4721';

  @override
  bool get modoDeTeste => true;

  @override
  String? get codigoDeTeste => _codigo;

  @override
  Stream<PedidoParaMotoqueiro> pedidosDisponiveis() async* {
    int numero = 0;
    while (true) {
      await Future<void>.delayed(const Duration(seconds: 6));
      numero++;
      yield PedidoParaMotoqueiro(
        id: 'pedido-$numero',
        passageiroNome: 'Emanuel',
        passageiroAvaliacao: 4.9,
        capulanaPassageiro: PadraoCapulana.folhasDoMar,
        origemNome: 'Barraca da Tia Rosa',
        destinoNome: 'Mercado Municipal',
        distanciaKm: 3.4,
        preco: 100,
        metrosAteRecolha: 450,
        minutosAteRecolha: 2,
        formaPagamento: FormaPagamento.dinheiro,
        notaPagamento: 500,
        notaVoz: const NotaVoz(caminho: 'pedido.m4a', duracaoSegundos: 9),
      );
    }
  }

  @override
  Future<void> aceitar(PedidoParaMotoqueiro pedido) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<void> recusar(PedidoParaMotoqueiro pedido) async {}

  @override
  Future<void> iniciar(PedidoParaMotoqueiro pedido, String codigo) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (codigo != _codigo) {
      throw const ExcecaoCorrida(
        'Código errado. Pede de novo os 4 números ao passageiro.',
      );
    }
  }

  @override
  Future<void> terminar(PedidoParaMotoqueiro pedido) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }
}

/// Sempre simulados por enquanto, mesmo com o Supabase configurado: o servidor
/// ainda não tem colete, código de subida, pagamento nem paragens.
final Provider<RepositorioCorrida> repositorioCorridaProvider =
    Provider<RepositorioCorrida>(
      (Ref ref) => RepositorioCorridaSimulado(
        precos: ref.watch(repositorioPrecosProvider),
      ),
    );

final Provider<RepositorioPedidosMotoqueiro>
repositorioPedidosMotoqueiroProvider = Provider<RepositorioPedidosMotoqueiro>(
  (Ref ref) => RepositorioPedidosMotoqueiroSimulado(),
);
