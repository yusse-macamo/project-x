import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/inicio/dados/repositorio_pracas.dart';
import 'package:project_x/funcionalidades/inicio/dominio/praca.dart';
import 'package:project_x/funcionalidades/localizacao/apresentacao/controladores/controlador_mapa.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';

const Coordenada _centroVilankulos = Coordenada(
  latitude: -21.9833,
  longitude: 35.3167,
);

final FutureProvider<List<Praca>> pracasPertoProvider =
    FutureProvider<List<Praca>>((Ref ref) {
      final Coordenada? posicao = ref.watch(
        controladorMapaProvider.select((EstadoMapa e) => e.posicaoAtual),
      );
      return ref
          .read(repositorioPracasProvider)
          .listarPerto(posicao ?? _centroVilankulos);
    });
