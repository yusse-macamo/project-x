import 'package:project_x/funcionalidades/inicio/dominio/tipo_veiculo.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';

class DisponibilidadeVeiculo {
  const DisponibilidadeVeiculo({required this.minutos, required this.livres});

  final int minutos;
  final int livres;
}

class Praca {
  const Praca({
    required this.nome,
    required this.referencia,
    required this.coordenada,
    required this.disponibilidade,
  });

  final String nome;
  final String referencia;
  final Coordenada coordenada;
  final Map<TipoVeiculo, DisponibilidadeVeiculo> disponibilidade;

  int get totalMotas => disponibilidade[TipoVeiculo.mota]?.livres ?? 0;
}
