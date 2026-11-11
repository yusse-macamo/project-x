import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/inicio/dominio/praca.dart';
import 'package:project_x/funcionalidades/inicio/dominio/tipo_veiculo.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';

abstract interface class RepositorioPracas {
  /// Ordenadas da mais próxima para a mais distante.
  Future<List<Praca>> listarPerto(Coordenada posicao);
}

class RepositorioPracasSimulado implements RepositorioPracas {
  static const List<Praca> _pracas = <Praca>[
    Praca(
      nome: 'Praça das Bombas',
      referencia: 'ao pé das Bombas',
      coordenada: Coordenada(latitude: -21.9860, longitude: 35.3130),
      disponibilidade: <TipoVeiculo, DisponibilidadeVeiculo>{
        TipoVeiculo.mota: DisponibilidadeVeiculo(minutos: 2, livres: 4),
        TipoVeiculo.txopela: DisponibilidadeVeiculo(minutos: 4, livres: 2),
        TipoVeiculo.carro: DisponibilidadeVeiculo(minutos: 9, livres: 1),
      },
    ),
    Praca(
      nome: 'Praça do Mercado',
      referencia: 'ao pé do Mercado',
      coordenada: Coordenada(latitude: -21.9760, longitude: 35.3195),
      disponibilidade: <TipoVeiculo, DisponibilidadeVeiculo>{
        TipoVeiculo.mota: DisponibilidadeVeiculo(minutos: 6, livres: 6),
        TipoVeiculo.txopela: DisponibilidadeVeiculo(minutos: 8, livres: 1),
        TipoVeiculo.carro: DisponibilidadeVeiculo(minutos: 12, livres: 1),
      },
    ),
  ];

  @override
  Future<List<Praca>> listarPerto(Coordenada posicao) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return <Praca>[..._pracas]..sort(
      (Praca a, Praca b) => a.coordenada
          .distanciaEmMetrosAte(posicao)
          .compareTo(b.coordenada.distanciaEmMetrosAte(posicao)),
    );
  }
}

final Provider<RepositorioPracas> repositorioPracasProvider =
    Provider<RepositorioPracas>((Ref ref) => RepositorioPracasSimulado());
