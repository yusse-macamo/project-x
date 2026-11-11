enum TipoUtilizador { passageiro, motoqueiro }

class Utilizador {
  const Utilizador({
    required this.id,
    required this.telefone,
    this.tipo,
    this.nome,
    this.urlFoto,
  });

  final String id;
  final String telefone;

  /// `null` enquanto a pessoa não escolheu se usa a app como passageiro ou
  /// como motorista. Pode mudar a qualquer momento pelo menu.
  final TipoUtilizador? tipo;
  final String? nome;
  final String? urlFoto;

  bool get perfilCompleto => (nome?.length ?? 0) >= 3;

  String get primeiroNome {
    final String? valor = nome;
    if (valor == null || valor.isEmpty) {
      return '';
    }
    return valor.split(' ').first;
  }

  Utilizador copiarCom({
    String? id,
    String? telefone,
    TipoUtilizador? tipo,
    String? nome,
    String? urlFoto,
  }) {
    return Utilizador(
      id: id ?? this.id,
      telefone: telefone ?? this.telefone,
      tipo: tipo ?? this.tipo,
      nome: nome ?? this.nome,
      urlFoto: urlFoto ?? this.urlFoto,
    );
  }
}

class ExcecaoAutenticacao implements Exception {
  const ExcecaoAutenticacao(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}
