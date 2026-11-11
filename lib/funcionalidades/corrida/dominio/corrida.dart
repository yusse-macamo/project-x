import 'package:project_x/funcionalidades/inicio/dominio/tipo_veiculo.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';
import 'package:project_x/funcionalidades/voz/dominio/nota_voz.dart';
import 'package:project_x/nucleo/constantes/padrao_capulana.dart';

enum FormaPagamento {
  dinheiro('Dinheiro'),
  mpesa('M-Pesa'),
  emola('e-Mola');

  const FormaPagamento(this.nome);

  final String nome;
}

const List<int> notasDePagamento = <int>[100, 200, 500, 1000];
const List<int> gorjetasPossiveis = <int>[0, 10, 20, 50];
const List<String> etiquetasDeAvaliacao = <String>[
  'Conduz com cuidado',
  'Tinha troco',
  'Conhece as referências',
  'Capacete limpo',
  'Chegou rápido',
  'Respeitou o preço',
];

class ExcecaoCorrida implements Exception {
  const ExcecaoCorrida(this.mensagem);

  final String mensagem;
}

class MotoqueiroAtribuido {
  const MotoqueiroAtribuido({
    required this.nome,
    required this.avaliacao,
    required this.viagens,
    required this.numeroColete,
    required this.matricula,
    required this.descricaoVeiculo,
    required this.telefone,
    required this.praca,
    this.registadoNaAssociacao = false,
    this.temCapaceteExtra = false,
  });

  final String nome;
  final double avaliacao;
  final int viagens;
  final String numeroColete;
  final String matricula;
  final String descricaoVeiculo;
  final String telefone;
  final String praca;
  final bool registadoNaAssociacao;
  final bool temCapaceteExtra;

  String get primeiroNome => nome.split(' ').first;

  String get iniciais {
    final List<String> partes = nome
        .replaceAll('.', '')
        .split(' ')
        .where((String parte) => parte.isNotEmpty)
        .toList();
    return partes.take(2).map((String parte) => parte[0]).join().toUpperCase();
  }
}

class PedidoCorrida {
  const PedidoCorrida({
    required this.origem,
    required this.origemNome,
    required this.destino,
    required this.destinoNome,
    required this.tipoVeiculo,
    required this.modoPreco,
    required this.comCarga,
    required this.temBarco,
    required this.formaPagamento,
    this.notaPagamento,
    this.notaVoz,
  });

  final Coordenada origem;
  final String origemNome;
  final Coordenada destino;
  final String destinoNome;
  final TipoVeiculo tipoVeiculo;
  final ModoPreco modoPreco;
  final bool comCarga;
  final bool temBarco;
  final FormaPagamento formaPagamento;
  final int? notaPagamento;
  final NotaVoz? notaVoz;
}

class ParagemPercurso {
  const ParagemPercurso({
    required this.nome,
    required this.coordenada,
    this.minutosParado = 2,
  });

  final String nome;
  final Coordenada coordenada;
  final int minutosParado;
}

class Corrida {
  const Corrida({
    required this.id,
    required this.pedido,
    required this.motoqueiro,
    required this.preco,
    required this.distanciaKm,
    required this.minutosViagem,
    required this.codigoSubida,
    this.paragens = const <ParagemPercurso>[],
    this.iniciadaEm,
    this.concluidaEm,
  });

  final String id;
  final PedidoCorrida pedido;
  final MotoqueiroAtribuido motoqueiro;

  /// Valor decidido pelo repositório (no futuro, pelo servidor).
  final double preco;
  final double distanciaKm;
  final int minutosViagem;
  final String codigoSubida;
  final List<ParagemPercurso> paragens;
  final DateTime? iniciadaEm;
  final DateTime? concluidaEm;

  double? get troco {
    final int? nota = pedido.notaPagamento;
    if (pedido.formaPagamento != FormaPagamento.dinheiro || nota == null) {
      return null;
    }
    return nota - preco;
  }

  int get minutosParados => paragens.fold<int>(
    0,
    (int soma, ParagemPercurso paragem) => soma + paragem.minutosParado,
  );

  DateTime? get chegadaPrevista =>
      iniciadaEm?.add(Duration(minutes: minutosViagem + minutosParados));

  Corrida copiarCom({
    List<ParagemPercurso>? paragens,
    DateTime? iniciadaEm,
    DateTime? concluidaEm,
  }) {
    return Corrida(
      id: id,
      pedido: pedido,
      motoqueiro: motoqueiro,
      preco: preco,
      distanciaKm: distanciaKm,
      minutosViagem: minutosViagem,
      codigoSubida: codigoSubida,
      paragens: paragens ?? this.paragens,
      iniciadaEm: iniciadaEm ?? this.iniciadaEm,
      concluidaEm: concluidaEm ?? this.concluidaEm,
    );
  }
}

class AproximacaoMotoqueiro {
  const AproximacaoMotoqueiro({required this.metros, required this.posicao});

  final double metros;
  final Coordenada posicao;
}

class ProgressoViagem {
  const ProgressoViagem({
    required this.fracao,
    required this.kmRestantes,
    required this.posicao,
  });

  final double fracao;
  final double kmRestantes;
  final Coordenada posicao;
}

class AvaliacaoCorrida {
  const AvaliacaoCorrida({
    required this.corridaId,
    required this.nota,
    required this.etiquetas,
    required this.gorjeta,
    this.comentario,
  });

  final String corridaId;
  final int nota;
  final Set<String> etiquetas;
  final int gorjeta;
  final String? comentario;
}

class PedidoParaMotoqueiro {
  const PedidoParaMotoqueiro({
    required this.id,
    required this.passageiroNome,
    required this.passageiroAvaliacao,
    required this.capulanaPassageiro,
    required this.origemNome,
    required this.destinoNome,
    required this.distanciaKm,
    required this.preco,
    required this.metrosAteRecolha,
    required this.minutosAteRecolha,
    required this.formaPagamento,
    this.notaPagamento,
    this.notaVoz,
  });

  final String id;
  final String passageiroNome;
  final double passageiroAvaliacao;
  final PadraoCapulana capulanaPassageiro;
  final String origemNome;
  final String destinoNome;
  final double distanciaKm;
  final double preco;
  final double metrosAteRecolha;
  final int minutosAteRecolha;
  final FormaPagamento formaPagamento;
  final int? notaPagamento;
  final NotaVoz? notaVoz;

  double? get trocoALevar {
    final int? nota = notaPagamento;
    if (formaPagamento != FormaPagamento.dinheiro || nota == null) {
      return null;
    }
    return nota - preco;
  }
}
