class ExcecaoPrecos implements Exception {
  const ExcecaoPrecos(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}
