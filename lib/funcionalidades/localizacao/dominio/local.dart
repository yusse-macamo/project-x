import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';

enum TipoLocal { pesquisado, favorito, recente, pontoNoMapa }

class Local {
  const Local({
    required this.nome,
    this.descricao,
    required this.coordenada,
    required this.tipo,
  });

  final String nome;
  final String? descricao;
  final Coordenada coordenada;
  final TipoLocal tipo;
}
