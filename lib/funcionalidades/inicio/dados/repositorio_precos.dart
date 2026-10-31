import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project_x/funcionalidades/inicio/dominio/excecao_precos.dart';
import 'package:project_x/funcionalidades/inicio/dominio/tipo_veiculo.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';
import 'package:project_x/nucleo/configuracao/configuracao_supabase.dart';
import 'package:project_x/nucleo/supabase/cliente_supabase.dart';

abstract interface class RepositorioPrecos {
  /// Estimativa por tipo de veículo, em meticais (MT). O valor final é
  /// sempre calculado no servidor — isto é só uma pré-visualização para o
  /// passageiro decidir o veículo.
  Future<Map<TipoVeiculo, double>> estimarPrecos({
    required Coordenada origem,
    required Coordenada destino,
  });
}

class RepositorioPrecosSimulado implements RepositorioPrecos {
  static const Duration _atraso = Duration(milliseconds: 500);

  // (tarifa base, tarifa por quilómetro), em meticais. Mesmos valores que a
  // tabela `tarifas` no servidor.
  static const Map<TipoVeiculo, (double, double)> _tarifas =
      <TipoVeiculo, (double, double)>{
        TipoVeiculo.mota: (30, 15),
        TipoVeiculo.txopela: (40, 12),
        TipoVeiculo.carro: (70, 22),
        TipoVeiculo.camioneta: (150, 35),
      };

  @override
  Future<Map<TipoVeiculo, double>> estimarPrecos({
    required Coordenada origem,
    required Coordenada destino,
  }) async {
    await Future<void>.delayed(_atraso);
    final double distanciaEmKm = origem.distanciaEmMetrosAte(destino) / 1000;
    return <TipoVeiculo, double>{
      for (final MapEntry<TipoVeiculo, (double, double)> entrada
          in _tarifas.entries)
        entrada.key:
            entrada.value.$1 +
            entrada.value.$2 * distanciaEmKm.clamp(0.5, double.infinity),
    };
  }
}

class RepositorioPrecosSupabase implements RepositorioPrecos {
  RepositorioPrecosSupabase({required this._cliente});

  final SupabaseClient _cliente;

  @override
  Future<Map<TipoVeiculo, double>> estimarPrecos({
    required Coordenada origem,
    required Coordenada destino,
  }) async {
    try {
      final List<dynamic> linhas = await _cliente.rpc<List<dynamic>>(
        'estimar_precos',
        params: <String, Object?>{
          'origem_latitude': origem.latitude,
          'origem_longitude': origem.longitude,
          'destino_latitude': destino.latitude,
          'destino_longitude': destino.longitude,
        },
      );
      return <TipoVeiculo, double>{
        for (final dynamic linha in linhas)
          TipoVeiculo.values.byName(
            (linha as Map<String, dynamic>)['tipo_veiculo'] as String,
          ): (linha['preco'] as num)
              .toDouble(),
      };
    } catch (erro) {
      throw ExcecaoPrecos(
        traduzirErroSupabase(
          erro,
          porOmissao:
              'Não foi possível calcular o preço. Escolha o destino de novo.',
        ),
      );
    }
  }
}

final Provider<RepositorioPrecos> repositorioPrecosProvider =
    Provider<RepositorioPrecos>(
      (Ref ref) => ConfiguracaoSupabase.configurado
          ? RepositorioPrecosSupabase(
              cliente: ref.watch(clienteSupabaseProvider),
            )
          : RepositorioPrecosSimulado(),
    );
