import 'package:flutter/material.dart';

import 'package:project_x/funcionalidades/inicio/dominio/tipo_veiculo.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/nucleo/tema/tema_app.dart';

/// Fotografia do veículo com proporção 3:2; `tamanho` é a altura. A camioneta
/// não tem fotografia e mostra um ícone.
class IlustracaoVeiculo extends StatelessWidget {
  const IlustracaoVeiculo({required this.tipo, this.tamanho = 48, super.key});

  final TipoVeiculo tipo;
  final double tamanho;

  static String? _caminhoFoto(TipoVeiculo tipo) => switch (tipo) {
    TipoVeiculo.mota => 'assets/veiculos/mota.jpg',
    TipoVeiculo.txopela => 'assets/veiculos/txopela.jpg',
    TipoVeiculo.carro => 'assets/veiculos/taxi.jpg',
    TipoVeiculo.camioneta => null,
  };

  @override
  Widget build(BuildContext context) {
    final String? caminho = _caminhoFoto(tipo);
    if (caminho == null) {
      return Icon(
        Icons.local_shipping_rounded,
        size: tamanho,
        color: CoresApp.terracota,
      );
    }
    final double largura = tamanho * 1.5;
    final double raio = tamanho < 40 ? 6 : TemaApp.raioPequeno;
    return Semantics(
      label: tipo.nome,
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(raio),
        child: Image.asset(
          caminho,
          width: largura,
          height: tamanho,
          fit: BoxFit.cover,
          cacheWidth: (largura * MediaQuery.devicePixelRatioOf(context))
              .round(),
          errorBuilder: (BuildContext context, Object erro, StackTrace? _) =>
              SizedBox(
                width: largura,
                height: tamanho,
                child: Icon(
                  Icons.directions_car_outlined,
                  size: tamanho * 0.7,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
        ),
      ),
    );
  }
}
