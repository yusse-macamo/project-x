import 'package:flutter/material.dart';

import 'package:project_x/funcionalidades/paragens/dominio/paragem.dart';

IconData iconeDaCategoria(CategoriaParagem categoria) => switch (categoria) {
  CategoriaParagem.barraca => Icons.storefront_outlined,
  CategoriaParagem.casa => Icons.home_outlined,
  CategoriaParagem.embondeiro => Icons.park_outlined,
  CategoriaParagem.igreja => Icons.church_outlined,
  CategoriaParagem.escola => Icons.school_outlined,
  CategoriaParagem.praia => Icons.beach_access_outlined,
  CategoriaParagem.outro => Icons.bookmark_border,
  CategoriaParagem.mercado => Icons.store_mall_directory_outlined,
  CategoriaParagem.porto => Icons.sailing_outlined,
  CategoriaParagem.bombas => Icons.local_gas_station_outlined,
};
