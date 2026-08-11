class ExcecaoLocalizacao implements Exception {
  const ExcecaoLocalizacao(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

class ExcecaoPesquisa implements Exception {
  const ExcecaoPesquisa(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}
