import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/corrida/apresentacao/controladores/controlador_corrida.dart';
import 'package:project_x/funcionalidades/corrida/dominio/corrida.dart';
import 'package:project_x/nucleo/utilitarios/formatadores.dart';
import 'package:project_x/partilhado/widgets/estado_vazio.dart';
import 'package:project_x/partilhado/widgets/ilustracao_veiculo.dart';
import 'package:project_x/partilhado/widgets/indicador_carregamento.dart';

class AbaViagens extends ConsumerWidget {
  const AbaViagens({required this.aoPedirViagem, super.key});

  final VoidCallback aoPedirViagem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Corrida>> historico = ref.watch(
      historicoCorridasProvider,
    );
    return historico.when(
      loading: () => const IndicadorCarregamento(),
      error: (Object _, StackTrace _) => EstadoVazio(
        icone: Icons.wifi_off,
        titulo: 'Não foi possível ver as viagens',
        descricao: 'Confirma a tua ligação e tenta de novo.',
        textoAcao: 'Tentar de novo',
        aoTocarAcao: () => ref.invalidate(historicoCorridasProvider),
      ),
      data: (List<Corrida> corridas) {
        if (corridas.isEmpty) {
          return EstadoVazio(
            icone: Icons.route_outlined,
            titulo: 'Ainda sem viagens',
            descricao: 'As viagens que fizeres aparecem aqui.',
            textoAcao: 'Pedir viagem',
            aoTocarAcao: aoPedirViagem,
          );
        }
        return ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            Text(
              'AS TUAS VIAGENS',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            for (final Corrida corrida in corridas)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: IlustracaoVeiculo(
                    tipo: corrida.pedido.tipoVeiculo,
                    tamanho: 32,
                  ),
                  title: Text(corrida.pedido.destinoNome),
                  subtitle: Text(
                    '${corrida.pedido.tipoVeiculo.nome} · '
                    '${formatarKm(corrida.distanciaKm)}',
                  ),
                  trailing: Text(
                    formatarMt(corrida.preco),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
