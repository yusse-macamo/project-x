class ExcecaoVoz implements Exception {
  const ExcecaoVoz(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}
