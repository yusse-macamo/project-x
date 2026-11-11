import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/paragens/apresentacao/controladores/controlador_paragens.dart';
import 'package:project_x/funcionalidades/paragens/dominio/paragem.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/partilhado/widgets/botao_principal.dart';
import 'package:project_x/partilhado/widgets/estado_vazio.dart';
import 'package:project_x/partilhado/widgets/icones_paragem.dart';
import 'package:project_x/partilhado/widgets/indicador_carregamento.dart';

class AbaParagens extends ConsumerWidget {
  const AbaParagens({required this.aoGravar, super.key});

  final VoidCallback aoGravar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EstadoParagens estado = ref.watch(controladorParagensProvider);
    final TextTheme textos = Theme.of(context).textTheme;
    final bool semNada = estado.minhas.isEmpty && estado.comunidade.isEmpty;

    if (estado.erro != null && semNada) {
      return EstadoVazio(
        icone: Icons.wifi_off,
        titulo: 'Não foi possível ver as paragens',
        descricao: estado.erro!,
        textoAcao: 'Tentar de novo',
        aoTocarAcao: () =>
            ref.read(controladorParagensProvider.notifier).carregar(),
      );
    }
    if (estado.aCarregar && semNada) {
      return const IndicadorCarregamento();
    }
    if (semNada) {
      return EstadoVazio(
        icone: Icons.bookmark_border,
        titulo: 'Ainda sem paragens',
        descricao:
            'Grava os lugares que usas, com o nome que toda a gente '
            'conhece.',
        textoAcao: 'Gravar paragem',
        aoTocarAcao: aoGravar,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text('AS TUAS PARAGENS', style: textos.headlineSmall),
        const SizedBox(height: 12),
        for (final Paragem paragem in estado.minhas)
          _LinhaParagem(paragem: paragem),
        const SizedBox(height: 16),
        Text('DA COMUNIDADE', style: textos.titleMedium),
        const SizedBox(height: 8),
        for (final Paragem paragem in estado.comunidade)
          _LinhaParagem(paragem: paragem),
        const SizedBox(height: 16),
        BotaoPrincipal(texto: 'Gravar paragem', aoPremir: aoGravar),
      ],
    );
  }
}

class _LinhaParagem extends StatelessWidget {
  const _LinhaParagem({required this.paragem});

  final Paragem paragem;

  @override
  Widget build(BuildContext context) {
    final String? descricao = paragem.descricao;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        iconeDaCategoria(paragem.categoria),
        color: CoresApp.terracota,
      ),
      title: Text(
        paragem.nome,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: paragem.confirmacoes > 0
          ? Text('Confirmada por ${paragem.confirmacoes} motoqueiros')
          : (descricao == null ? null : Text(descricao)),
    );
  }
}
