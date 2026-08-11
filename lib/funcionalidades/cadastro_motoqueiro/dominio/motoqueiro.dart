enum EstadoVerificacao { incompleto, pendente, aprovado, rejeitado }

enum TipoDocumento { cartaConducao, livrete, bilheteIdentidade, selfie }

enum PassoCadastro { dados, mota, documentos }

class Motoqueiro {
  const Motoqueiro({
    required this.id,
    required this.telefone,
    required this.nomeCompleto,
    required this.numeroBi,
    required this.bairro,
    required this.distrito,
    required this.contactoEmergencia,
    this.matricula,
    this.marca,
    this.modelo,
    this.cor,
    this.anoFabrico,
    this.estadoVerificacao = EstadoVerificacao.incompleto,
    this.motivoRejeicao,
    this.documentos = const <TipoDocumento, String>{},
    this.dataSubmissao,
  });

  final String id;
  final String telefone;
  final String nomeCompleto;
  final String numeroBi;
  final String bairro;
  final String distrito;
  final String contactoEmergencia;
  final String? matricula;
  final String? marca;
  final String? modelo;
  final String? cor;
  final int? anoFabrico;
  final EstadoVerificacao estadoVerificacao;
  final String? motivoRejeicao;
  final Map<TipoDocumento, String> documentos;
  final DateTime? dataSubmissao;

  /// Passo em falta para um cadastro já iniciado (ver [Motoqueiro]).
  ///
  /// Um telefone sem nenhum [Motoqueiro] ainda (`cadastroAtual` devolve
  /// `null`) está sempre no passo [PassoCadastro.dados] — esse caso não
  /// passa por este getter, é tratado por quem chama o repositório.
  PassoCadastro get passoAtual {
    final bool dadosMotaCompletos =
        matricula != null &&
        marca != null &&
        modelo != null &&
        cor != null &&
        anoFabrico != null;
    if (!dadosMotaCompletos) {
      return PassoCadastro.mota;
    }
    return PassoCadastro.documentos;
  }

  Motoqueiro copiarCom({
    String? nomeCompleto,
    String? numeroBi,
    String? bairro,
    String? distrito,
    String? contactoEmergencia,
    String? matricula,
    String? marca,
    String? modelo,
    String? cor,
    int? anoFabrico,
    EstadoVerificacao? estadoVerificacao,
    String? motivoRejeicao,
    bool limparMotivoRejeicao = false,
    Map<TipoDocumento, String>? documentos,
    DateTime? dataSubmissao,
  }) {
    return Motoqueiro(
      id: id,
      telefone: telefone,
      nomeCompleto: nomeCompleto ?? this.nomeCompleto,
      numeroBi: numeroBi ?? this.numeroBi,
      bairro: bairro ?? this.bairro,
      distrito: distrito ?? this.distrito,
      contactoEmergencia: contactoEmergencia ?? this.contactoEmergencia,
      matricula: matricula ?? this.matricula,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      cor: cor ?? this.cor,
      anoFabrico: anoFabrico ?? this.anoFabrico,
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
