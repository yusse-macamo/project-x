import 'package:flutter/material.dart';

import 'package:project_x/funcionalidades/inicio/dominio/tipo_veiculo.dart';
import 'package:project_x/nucleo/tema/tema_app.dart';
import 'package:project_x/nucleo/utilitarios/formatadores.dart';

extension _DetalhesTipoVeiculo on TipoVeiculo {
  IconData get icone => switch (this) {
    TipoVeiculo.camioneta => Icons.local_shipping_rounded,
    TipoVeiculo.txopela => Icons.electric_rickshaw_rounded,
    TipoVeiculo.mota => Icons.two_wheeler_rounded,
    TipoVeiculo.carro => Icons.directions_car_rounded,
  };

  String get nome => switch (this) {
    TipoVeiculo.camioneta => 'Camioneta',
    TipoVeiculo.txopela => 'Txopela',
    TipoVeiculo.mota => 'Mota',
    TipoVeiculo.carro => 'Carro',
  };

  String get descricao => switch (this) {
    TipoVeiculo.camioneta => 'Cargas',
    TipoVeiculo.txopela => 'Viagem',
    TipoVeiculo.mota => 'Viagem mais rápida',
    TipoVeiculo.carro => 'Viagem mais confortável',
  };
}

class SeletorTipoVeiculo extends StatelessWidget {
  const SeletorTipoVeiculo({
    required this.selecionado,
    required this.aoSelecionar,
    this.precos,
    this.aCalcularPrecos = false,
    super.key,
  });

  final TipoVeiculo selecionado;
  final ValueChanged<TipoVeiculo> aoSelecionar;
  final Map<TipoVeiculo, double>? precos;
  final bool aCalcularPrecos;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 134,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: TipoVeiculo.values.length,
        separatorBuilder: (BuildContext context, int indice) =>
            const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int indice) {
          final TipoVeiculo tipo = TipoVeiculo.values[indice];
          return _CartaoTipoVeiculo(
            tipo: tipo,
            selecionado: tipo == selecionado,
            preco: precos?[tipo],
            aCalcular: aCalcularPrecos,
            aoTocar: () => aoSelecionar(tipo),
          );
        },
      ),
    );
  }
}

class _CartaoTipoVeiculo extends StatelessWidget {
  const _CartaoTipoVeiculo({
    required this.tipo,
    required this.selecionado,
    required this.preco,
    required this.aCalcular,
    required this.aoTocar,
  });

  final TipoVeiculo tipo;
  final bool selecionado;
  final double? preco;
  final bool aCalcular;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TextTheme textos = Theme.of(context).textTheme;
    final Color corDestaque = selecionado ? cores.primary : cores.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
      onTap: aoTocar,
      child: Container(
        width: 88,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: selecionado ? cores.primaryContainer : cores.surface,
          borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
          border: Border.all(
            color: selecionado ? cores.primary : cores.outline,
            width: selecionado ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(tipo.icone, size: 22, color: corDestaque),
            const SizedBox(height: 4),
            Text(
              tipo.nome,
              style: textos.labelMedium?.copyWith(
                fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tipo.descricao,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textos.labelSmall?.copyWith(color: cores.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            if (aCalcular)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cores.onSurfaceVariant,
                ),
              )
            else if (preco != null)
              Text(
                formatarMt(preco!),
                style: textos.labelMedium?.copyWith(
                  color: corDestaque,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
