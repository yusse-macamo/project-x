import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/local.dart';
import 'package:project_x/funcionalidades/voz/dominio/nota_voz.dart';

enum CategoriaParagem {
  barraca('Barraca'),
  casa('Casa'),
  embondeiro('Embondeiro'),
  igreja('Igreja'),
  escola('Escola'),
  praia('Praia'),
  outro('Outro'),
  mercado('Mercado'),
  porto('Porto'),
  bombas('Bombas');

  const CategoriaParagem(this.nome);

  final String nome;
}

/// O que o passageiro pode escolher ao gravar. Mercado, porto e bombas são só
/// para os marcos conhecidos.
const List<CategoriaParagem> categoriasGravaveis = <CategoriaParagem>[
  CategoriaParagem.barraca,
  CategoriaParagem.casa,
  CategoriaParagem.embondeiro,
  CategoriaParagem.igreja,
  CategoriaParagem.escola,
  CategoriaParagem.praia,
  CategoriaParagem.outro,
];

class Paragem {
  const Paragem({
    required this.id,
    required this.nome,
    required this.coordenada,
    required this.categoria,
    this.descricao,
    this.confirmacoes = 0,
    this.partilhada = false,
    this.notaVoz,
    this.caminhoFoto,
  });

  static const int confirmacoesParaFicarVisivel = 3;

  final String id;
  final String nome;
  final String? descricao;
  final Coordenada coordenada;
  final CategoriaParagem categoria;
  final int confirmacoes;
  final bool partilhada;
  final NotaVoz? notaVoz;
  final String? caminhoFoto;

  bool get visivelNaComunidade =>
      partilhada && confirmacoes >= confirmacoesParaFicarVisivel;

  Local comoLocal() => Local(
    nome: nome,
    descricao: descricao,
    coordenada: coordenada,
    tipo: TipoLocal.favorito,
  );
}

class MarcoConhecido {
  const MarcoConhecido({
    required this.nome,
    required this.nomeCurto,
    required this.descricao,
    required this.coordenada,
    required this.categoria,
    this.horarios,
  });

  final CategoriaParagem categoria;
  final String nome;
  final String nomeCurto;
  final String descricao;
  final Coordenada coordenada;
  final String? horarios;

  Local comoLocal() => Local(
    nome: nome,
    descricao: descricao,
    coordenada: coordenada,
    tipo: TipoLocal.pesquisado,
  );
}
