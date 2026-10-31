enum MotivoFalhaImagem {
  semAcessoCamara,
  semAcessoGaleria,
  semCamara,
  desconhecido,
}

class ExcecaoSelectorImagem implements Exception {
  const ExcecaoSelectorImagem(this.motivo);

  final MotivoFalhaImagem motivo;

  @override
  String toString() => 'ExcecaoSelectorImagem($motivo)';
}
