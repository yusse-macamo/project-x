import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/correspondencia_texto.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/excecoes.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/local.dart';

abstract interface class RepositorioLugares {
  Future<List<Local>> pesquisar(String termo, {Coordenada? perto});
  Future<Local?> localEmCoordenada(Coordenada coordenada);
}

/// Usa a API pública do Nominatim (OpenStreetMap).
///
/// AVISO: o serviço público do Nominatim não é aceitável para produção com
/// volume real — a política de uso limita a uma pesquisa por segundo e proíbe
/// uso intensivo. Antes do lançamento é preciso uma instância própria ou um
/// fornecedor pago. O mesmo se aplica aos mosaicos do mapa.
class RepositorioLugaresNominatim implements RepositorioLugares {
  RepositorioLugaresNominatim({http.Client? cliente})
    : _cliente = cliente ?? http.Client();

  static const String _userAgent =
      'MotoTaxiInhambane/1.0 (contacto@mototaxi-inhambane.co.mz)';
  static const int _limite = 8;
  static const double _margemViewboxGraus = 0.15;
  static const Duration _intervaloMinimoEntrePedidos = Duration(seconds: 1);

  final http.Client _cliente;
  final Map<String, List<Local>> _cache = <String, List<Local>>{};
  DateTime? _ultimoPedidoEm;

  Future<void> _respeitarLimiteDeTaxa() async {
    final DateTime? ultimo = _ultimoPedidoEm;
    if (ultimo != null) {
      final Duration decorrido = DateTime.now().difference(ultimo);
      if (decorrido < _intervaloMinimoEntrePedidos) {
        await Future<void>.delayed(_intervaloMinimoEntrePedidos - decorrido);
      }
    }
    _ultimoPedidoEm = DateTime.now();
  }

  @override
  Future<List<Local>> pesquisar(String termo, {Coordenada? perto}) async {
    final String chave = '$termo|${perto?.latitude}|${perto?.longitude}';
    final List<Local>? emCache = _cache[chave];
    if (emCache != null) {
      return emCache;
    }

    final Map<String, String> parametros = <String, String>{
      'q': termo,
      'format': 'jsonv2',
      'countrycodes': 'mz',
      'limit': '$_limite',
      'addressdetails': '1',
    };
    if (perto != null) {
      parametros['viewbox'] = _viewboxA(perto);
      parametros['bounded'] = '0';
    }

    await _respeitarLimiteDeTaxa();
    try {
      final http.Response resposta = await _cliente.get(
        Uri.https('nominatim.openstreetmap.org', '/search', parametros),
        headers: const <String, String>{'User-Agent': _userAgent},
      );
      if (resposta.statusCode != 200) {
        throw const ExcecaoPesquisa(
          'Não foi possível pesquisar agora. Tenta de novo.',
        );
      }
      final List<dynamic> dados = jsonDecode(resposta.body) as List<dynamic>;
      final List<Local> locais = dados
          .map((dynamic item) => _paraLocal(item as Map<String, dynamic>))
          .toList();
      _cache[chave] = locais;
      return locais;
    } on ExcecaoPesquisa {
      rethrow;
    } catch (_) {
      throw const ExcecaoPesquisa('Sem ligação à internet. Tenta de novo.');
    }
  }

  String _viewboxA(Coordenada centro) {
    final double oeste = centro.longitude - _margemViewboxGraus;
    final double norte = centro.latitude + _margemViewboxGraus;
    final double este = centro.longitude + _margemViewboxGraus;
    final double sul = centro.latitude - _margemViewboxGraus;
    return '$oeste,$norte,$este,$sul';
  }

  Local _paraLocal(Map<String, dynamic> mapa) {
    final String nomeCompleto = mapa['display_name'] as String;
    final String? nomeCurto = mapa['name'] as String?;
    return Local(
      nome: (nomeCurto != null && nomeCurto.isNotEmpty)
          ? nomeCurto
          : nomeCompleto.split(',').first,
      descricao: nomeCompleto,
      coordenada: Coordenada(
        latitude: double.parse(mapa['lat'] as String),
        longitude: double.parse(mapa['lon'] as String),
      ),
      tipo: TipoLocal.pesquisado,
    );
  }

  @override
  Future<Local?> localEmCoordenada(Coordenada coordenada) async {
    await _respeitarLimiteDeTaxa();
    try {
      final http.Response resposta = await _cliente.get(
        Uri.https('nominatim.openstreetmap.org', '/reverse', <String, String>{
          'lat': '${coordenada.latitude}',
          'lon': '${coordenada.longitude}',
          'format': 'jsonv2',
        }),
        headers: const <String, String>{'User-Agent': _userAgent},
      );
      if (resposta.statusCode != 200) {
        return null;
      }
      final Map<String, dynamic> mapa =
          jsonDecode(resposta.body) as Map<String, dynamic>;
      final String? nomeCompleto = mapa['display_name'] as String?;
      if (nomeCompleto == null) {
        return null;
      }
      return Local(
        nome: nomeCompleto.split(',').first,
        descricao: nomeCompleto,
        coordenada: coordenada,
        tipo: TipoLocal.pontoNoMapa,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Locais reais de Vilankulos, Inhambane e Maxixe, para desenvolvimento sem
/// rede. Vilankulos vem primeiro — é o que aparece nas sugestões com o
/// campo de pesquisa vazio. Coordenadas aproximadas.
class RepositorioLugaresSimulado implements RepositorioLugares {
  static const Duration _atraso = Duration(milliseconds: 400);

  static const List<Local> _locais = <Local>[
    Local(
      nome: 'Mercado Central',
      descricao: 'Avenida da Independência, Inhambane',
      coordenada: Coordenada(latitude: -23.8657, longitude: 35.3839),
      tipo: TipoLocal.pesquisado,
    ),
    Local(
      nome: 'Casa Rex',
      descricao: 'Vilankulos',
      coordenada: Coordenada(latitude: -21.9808, longitude: 35.3129),
      tipo: TipoLocal.pesquisado,
    ),
    Local(
      nome: 'Beach Lodge',
      descricao: 'Vilankulos',
      coordenada: Coordenada(latitude: -21.9760, longitude: 35.3210),
      tipo: TipoLocal.pesquisado,
    ),
    Local(
      nome: 'Hospital Rural de Vilankulos',
      descricao: 'Vilankulos',
      coordenada: Coordenada(latitude: -21.9875, longitude: 35.3117),
      tipo: TipoLocal.pesquisado,
    ),
    Local(
      nome: 'Aeroporto de Vilankulos',
      descricao: 'Vilankulos',
      coordenada: Coordenada(latitude: -22.0090, longitude: 35.3110),
      tipo: TipoLocal.pesquisado,
    ),
    Local(
      nome: 'Porto de Vilankulos',
      descricao: 'Cais dos dhows para o arquipélago do Bazaruto, Vilankulos',
      coordenada: Coordenada(latitude: -21.9822, longitude: 35.3145),
      tipo: TipoLocal.pesquisado,
    ),
    Local(
      nome: 'Mercado Central de Vilankulos',
      descricao: 'Vilankulos',
      coordenada: Coordenada(latitude: -21.9847, longitude: 35.3138),
      tipo: TipoLocal.pesquisado,
    ),
    Local(
      nome: 'Praia do Paraíso',
      descricao: 'Vilankulos',
      coordenada: Coordenada(latitude: -22.0064, longitude: 35.3197),
      tipo: TipoLocal.pesquisado,
    ),
    Local(
      nome: 'Cais dos Dhows',
      descricao: 'Baía de Inhambane, Inhambane',
      coordenada: Coordenada(latitude: -23.8646, longitude: 35.3822),
      tipo: TipoLocal.pesquisado,
    ),
    Local(
      nome: 'Hospital Provincial de Inhambane',
      descricao: 'Bairro Balane, Inhambane',
      coordenada: Coordenada(latitude: -23.8698, longitude: 35.3872),
      tipo: TipoLocal.pesquisado,
    ),
    Local(
      nome: 'Aeroporto de Inhambane',
      descricao: 'Estrada Nacional 1, Inhambane',
      coordenada: Coordenada(latitude: -23.8760, longitude: 35.4088),
      tipo: TipoLocal.pesquisado,
    ),
    Local(
      nome: 'Instituto Industrial e Comercial de Inhambane',
      descricao: 'Bairro Chamane, Inhambane',
      coordenada: Coordenada(latitude: -23.8581, longitude: 35.3791),
      tipo: TipoLocal.pesquisado,
    ),
    Local(
      nome: 'Terminal do Ferry Boat',
      descricao: 'Baía de Maxixe, Maxixe',
      coordenada: Coordenada(latitude: -23.8607, longitude: 35.3479),
      tipo: TipoLocal.pesquisado,
    ),
    Local(
      nome: 'Mercado Central da Maxixe',
      descricao: 'Avenida Eduardo Mondlane, Maxixe',
      coordenada: Coordenada(latitude: -23.8597, longitude: 35.3459),
      tipo: TipoLocal.pesquisado,
    ),
    Local(
      nome: 'Hospital Rural da Maxixe',
      descricao: 'Bairro 1° de Maio, Maxixe',
      coordenada: Coordenada(latitude: -23.8632, longitude: 35.3491),
      tipo: TipoLocal.pesquisado,
    ),
    Local(
      nome: 'Praia do Tofo',
      descricao: 'Distrito de Inhambane',
      coordenada: Coordenada(latitude: -23.8543, longitude: 35.5453),
      tipo: TipoLocal.pesquisado,
    ),
    Local(
      nome: 'Praia da Barra',
      descricao: 'Distrito de Inhambane',
      coordenada: Coordenada(latitude: -23.8090, longitude: 35.4890),
      tipo: TipoLocal.pesquisado,
    ),
  ];

  @override
  Future<List<Local>> pesquisar(String termo, {Coordenada? perto}) async {
    await Future<void>.delayed(_atraso);
    if (termo.trim().isEmpty) {
      return _locais.take(5).toList();
    }
    // Palavra a palavra: "mercado municipal" encontra os mercados, mesmo sem
    // nenhum se chamar exatamente assim. Mais palavras em comum primeiro;
    // em empate, o mais perto.
    final List<(Local, int)> pontuados = <(Local, int)>[
      for (final Local local in _locais)
        (
          local,
          pontuarCorrespondencia(
            termo,
            '${local.nome} ${local.descricao ?? ''}',
          ),
        ),
    ].where(((Local, int) par) => par.$2 > 0).toList();
    pontuados.sort(((Local, int) a, (Local, int) b) {
      final int porPontos = b.$2.compareTo(a.$2);
      if (porPontos != 0 || perto == null) {
        return porPontos;
      }
      return a.$1.coordenada
          .distanciaEmMetrosAte(perto)
          .compareTo(b.$1.coordenada.distanciaEmMetrosAte(perto));
    });
    return <Local>[for (final (Local, int) par in pontuados) par.$1];
  }

  @override
  Future<Local?> localEmCoordenada(Coordenada coordenada) async {
    await Future<void>.delayed(_atraso);
    Local maisPerto = _locais.first;
    double menorDistancia = maisPerto.coordenada.distanciaEmMetrosAte(
      coordenada,
    );
    for (final Local local in _locais.skip(1)) {
      final double distancia = local.coordenada.distanciaEmMetrosAte(
        coordenada,
      );
      if (distancia < menorDistancia) {
        menorDistancia = distancia;
        maisPerto = local;
      }
    }
    return Local(
      nome: maisPerto.nome,
      descricao: maisPerto.descricao,
      coordenada: coordenada,
      tipo: TipoLocal.pontoNoMapa,
    );
  }
}

final Provider<RepositorioLugares> repositorioLugaresProvider =
    Provider<RepositorioLugares>((Ref ref) => RepositorioLugaresSimulado());
