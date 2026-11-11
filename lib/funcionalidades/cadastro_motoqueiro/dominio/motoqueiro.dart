import 'package:project_x/funcionalidades/inicio/dominio/tipo_veiculo.dart';

enum EstadoVerificacao { incompleto, pendente, aprovado, rejeitado }

enum TipoDocumento {
  fotoMotorista,
  veiculoFrente,
  veiculoTraseira,
  cartaConducao,
}

/// Veículos com que se pode trabalhar na ROTA. A camioneta fica para o
/// transporte de mercadorias.
const List<TipoVeiculo> veiculosDeTrabalho = veiculosDeViagem;

/// Fotografias pedidas a cada tipo de veículo: a mota não pede carta.
List<TipoDocumento> documentosExigidos(TipoVeiculo tipo) => <TipoDocumento>[
  TipoDocumento.fotoMotorista,
  TipoDocumento.veiculoFrente,
  TipoDocumento.veiculoTraseira,
  if (tipo != TipoVeiculo.mota) TipoDocumento.cartaConducao,
];

/// Só o táxi pede marca e modelo.
bool exigeMarcaModelo(TipoVeiculo tipo) => tipo == TipoVeiculo.carro;

class Motoqueiro {
  const Motoqueiro({
    required this.id,
    required this.telefone,
    required this.tipoVeiculo,
    required this.nomeCompleto,
    required this.email,
    this.matricula,
    this.cor,
    this.marca,
    this.modelo,
    this.estadoVerificacao = EstadoVerificacao.incompleto,
    this.motivoRejeicao,
    this.documentos = const <TipoDocumento, String>{},
    this.dataSubmissao,
  });

  final String id;
  final String telefone;
  final TipoVeiculo tipoVeiculo;
  final String nomeCompleto;
  final String email;
  final String? matricula;
  final String? cor;
  final String? marca;
  final String? modelo;
  final EstadoVerificacao estadoVerificacao;
  final String? motivoRejeicao;
  final Map<TipoDocumento, String> documentos;
  final DateTime? dataSubmissao;

  List<TipoDocumento> get documentosEmFalta => documentosExigidos(
    tipoVeiculo,
  ).where((TipoDocumento tipo) => !documentos.containsKey(tipo)).toList();

  bool get dadosVeiculoCompletos =>
      matricula != null &&
      cor != null &&
      (!exigeMarcaModelo(tipoVeiculo) || (marca != null && modelo != null));

  Motoqueiro copiarCom({
    TipoVeiculo? tipoVeiculo,
    String? nomeCompleto,
    String? email,
    String? matricula,
    String? cor,
    String? marca,
    String? modelo,
    EstadoVerificacao? estadoVerificacao,
    String? motivoRejeicao,
    bool limparMotivoRejeicao = false,
    Map<TipoDocumento, String>? documentos,
    DateTime? dataSubmissao,
  }) {
    return Motoqueiro(
      id: id,
      telefone: telefone,
      tipoVeiculo: tipoVeiculo ?? this.tipoVeiculo,
      nomeCompleto: nomeCompleto ?? this.nomeCompleto,
      email: email ?? this.email,
      matricula: matricula ?? this.matricula,
      cor: cor ?? this.cor,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      estadoVerificacao: estadoVerificacao ?? this.estadoVerificacao,
      motivoRejeicao: limparMotivoRejeicao
          ? null
          : (motivoRejeicao ?? this.motivoRejeicao),
      documentos: documentos ?? this.documentos,
      dataSubmissao: dataSubmissao ?? this.dataSubmissao,
    );
  }
}

class Documento {
  const Documento({
    required this.tipo,
    this.caminhoLocal,
    this.urlRemota,
    this.enviado = false,
    this.erro,
  });

  final TipoDocumento tipo;
  final String? caminhoLocal;
  final String? urlRemota;
  final bool enviado;
  final String? erro;

  Documento copiarCom({
    String? caminhoLocal,
    String? urlRemota,
    bool? enviado,
    String? erro,
    bool limparErro = false,
  }) {
    return Documento(
      tipo: tipo,
      caminhoLocal: caminhoLocal ?? this.caminhoLocal,
      urlRemota: urlRemota ?? this.urlRemota,
      enviado: enviado ?? this.enviado,
      erro: limparErro ? null : (erro ?? this.erro),
    );
  }
}

class ExcecaoCadastro implements Exception {
  const ExcecaoCadastro(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}
