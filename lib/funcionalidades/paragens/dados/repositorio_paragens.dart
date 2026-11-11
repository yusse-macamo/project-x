import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';
import 'package:project_x/funcionalidades/paragens/dominio/paragem.dart';
import 'package:project_x/funcionalidades/voz/dominio/nota_voz.dart';

abstract interface class RepositorioParagens {
  Future<List<MarcoConhecido>> listarMarcos();
  Future<List<Paragem>> listarComunidade();
  Future<List<Paragem>> listarMinhas();
  Future<Paragem> gravar({
    required String nome,
    required Coordenada coordenada,
    required CategoriaParagem categoria,
    required bool partilhar,
    NotaVoz? notaVoz,
    String? caminhoFoto,
  });
}

/// Dados de demonstração das maquetes: as coordenadas são aproximadas e não
/// foram confirmadas no terreno.
class RepositorioParagensSimulado implements RepositorioParagens {
  static const Duration _atraso = Duration(milliseconds: 400);

  final List<Paragem> _minhas = <Paragem>[
    const Paragem(
      id: 'casa',
      nome: 'Casa',
      coordenada: Coordenada(latitude: -21.9880, longitude: 35.3150),
      categoria: CategoriaParagem.casa,
    ),
    const Paragem(
      id: 'tia-rosa-minha',
      nome: 'Barraca da Tia Rosa',
      descricao: 'Ao lado do embondeiro seco',
      coordenada: Coordenada(latitude: -21.9815, longitude: 35.3160),
      categoria: CategoriaParagem.barraca,
    ),
  ];

  @override
  Future<List<MarcoConhecido>> listarMarcos() async {
    await Future<void>.delayed(_atraso);
    return const <MarcoConhecido>[
      MarcoConhecido(
        nome: 'Mercado Municipal',
        nomeCurto: 'Mercado',
        descricao: 'Centro · banca do peixe ao lado',
        coordenada: Coordenada(latitude: -21.9745, longitude: 35.3205),
        categoria: CategoriaParagem.mercado,
      ),
      MarcoConhecido(
        nome: 'Porto de Vilankulo',
        nomeCurto: 'Porto',
        descricao: 'Marginal · saída dos dhows',
        coordenada: Coordenada(latitude: -21.9790, longitude: 35.3235),
        categoria: CategoriaParagem.porto,
        horarios: 'Barcos p/ Bazaruto · 07:30 · 08:00',
      ),
      MarcoConhecido(
        nome: 'Bombas da entrada',
        nomeCurto: 'Bombas',
        descricao: 'Estrada para a EN1',
        coordenada: Coordenada(latitude: -21.9868, longitude: 35.3120),
        categoria: CategoriaParagem.bombas,
      ),
      MarcoConhecido(
        nome: 'Igreja',
        nomeCurto: 'Igreja',
        descricao: 'Rua de areia, perto do centro',
        coordenada: Coordenada(latitude: -21.9805, longitude: 35.3110),
        categoria: CategoriaParagem.igreja,
      ),
      MarcoConhecido(
        nome: 'Embondeiro seco',
        nomeCurto: 'Embondeiro',
        descricao: 'Toda a gente o conhece',
        coordenada: Coordenada(latitude: -21.9838, longitude: 35.3172),
        categoria: CategoriaParagem.embondeiro,
      ),
    ];
  }

  @override
  Future<List<Paragem>> listarComunidade() async {
    await Future<void>.delayed(_atraso);
    return const <Paragem>[
      Paragem(
        id: 'tia-rosa',
        nome: 'Barraca da Tia Rosa',
        descricao: 'Ao lado do embondeiro seco',
        coordenada: Coordenada(latitude: -21.9815, longitude: 35.3160),
        categoria: CategoriaParagem.barraca,
        confirmacoes: 12,
        partilhada: true,
        notaVoz: NotaVoz(caminho: 'tia-rosa.m4a', duracaoSegundos: 7),
      ),
      Paragem(
        id: 'portao-azul',
        nome: 'Casa de portão azul',
        descricao: 'Atrás da igreja, rua de areia',
        coordenada: Coordenada(latitude: -21.9798, longitude: 35.3122),
        categoria: CategoriaParagem.casa,
        confirmacoes: 5,
        partilhada: true,
        notaVoz: NotaVoz(caminho: 'portao-azul.m4a', duracaoSegundos: 9),
      ),
    ];
  }

  @override
  Future<List<Paragem>> listarMinhas() async {
    await Future<void>.delayed(_atraso);
    return List<Paragem>.unmodifiable(_minhas);
  }

  @override
  Future<Paragem> gravar({
    required String nome,
    required Coordenada coordenada,
    required CategoriaParagem categoria,
    required bool partilhar,
    NotaVoz? notaVoz,
    String? caminhoFoto,
  }) async {
    await Future<void>.delayed(_atraso);
    final Paragem paragem = Paragem(
      id: 'p-${DateTime.now().millisecondsSinceEpoch}',
      nome: nome,
      coordenada: coordenada,
      categoria: categoria,
      partilhada: partilhar,
      notaVoz: notaVoz,
      caminhoFoto: caminhoFoto,
    );
    _minhas.add(paragem);
    return paragem;
  }
}

final Provider<RepositorioParagens> repositorioParagensProvider =
    Provider<RepositorioParagens>((Ref ref) => RepositorioParagensSimulado());
