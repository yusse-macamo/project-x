import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/localizacao/apresentacao/controladores/controlador_pesquisa_destino.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/local.dart';
import 'package:project_x/funcionalidades/paragens/apresentacao/controladores/controlador_paragens.dart';
import 'package:project_x/funcionalidades/paragens/dominio/paragem.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/nucleo/tema/tema_app.dart';
import 'package:project_x/nucleo/utilitarios/formatadores.dart';
import 'package:project_x/partilhado/widgets/estado_vazio.dart';
import 'package:project_x/partilhado/widgets/indicador_carregamento.dart';

/// Lugares sugeridos (marcos e paragens da comunidade) e resultados da
/// pesquisa de destino. Usados no ecrã principal e em "Vais onde?".
class ListaLugares extends ConsumerWidget {
  const ListaLugares({
    required this.referencia,
    required this.aoEscolher,
    super.key,
  });

  final Coordenada referencia;
  final ValueChanged<Local> aoEscolher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EstadoParagens estado = ref.watch(controladorParagensProvider);
    final bool semNada = estado.marcos.isEmpty && estado.comunidade.isEmpty;

    if (estado.erro != null && semNada) {
      return EstadoVazio(
        icone: Icons.wifi_off,
        titulo: 'Não foi possível ver os lugares',
        descricao: estado.erro!,
        textoAcao: 'Tentar de novo',
        aoTocarAcao: () =>
            ref.read(controladorParagensProvider.notifier).carregar(),
      );
    }
    if (estado.aCarregar && semNada) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: IndicadorCarregamento(),
      );
    }
    if (semNada) {
      return const EstadoVazio(
        icone: Icons.place_outlined,
        titulo: 'Ainda sem lugares aqui',
        descricao: 'Escreve o destino ou marca-o no mapa.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _Seccao('MARCOS CONHECIDOS'),
        for (final MarcoConhecido marco in estado.marcos)
          _LinhaLugar(
            inicial: marco.nome[0],
            titulo: marco.nome,
            descricao: marco.descricao,
            etiqueta: marco.horarios,
            metros: marco.coordenada.distanciaEmMetrosAte(referencia),
            aoTocar: () => aoEscolher(marco.comoLocal()),
          ),
        const SizedBox(height: 12),
        const _Seccao('PARAGENS DA COMUNIDADE · NÃO ESTÃO NO MAPA'),
        for (final Paragem paragem in estado.comunidade)
          _LinhaLugar(
            inicial: paragem.nome[0],
            comSom: paragem.notaVoz != null,
            titulo: paragem.nome,
            descricao: paragem.descricao,
            confirmacoes: paragem.confirmacoes,
            metros: paragem.coordenada.distanciaEmMetrosAte(referencia),
            aoTocar: () => aoEscolher(paragem.comoLocal()),
          ),
      ],
    );
  }
}

class _Seccao extends StatelessWidget {
  const _Seccao(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LinhaLugar extends StatelessWidget {
  const _LinhaLugar({
    required this.inicial,
    required this.titulo,
    required this.metros,
    required this.aoTocar,
    this.descricao,
    this.etiqueta,
    this.confirmacoes = 0,
    this.comSom = false,
  });

  final String inicial;
  final String titulo;
  final String? descricao;
  final String? etiqueta;
  final int confirmacoes;
  final bool comSom;
  final double metros;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TextTheme textos = Theme.of(context).textTheme;
    final String? texto = descricao;
    final String? rotulo = etiqueta;
    return InkWell(
      onTap: aoTocar,
      borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cores.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
              ),
              child: comSom
                  ? const Icon(Icons.play_arrow, color: CoresApp.terracota)
                  : Text(
                      inicial,
                      style: const TextStyle(
                        color: CoresApp.terracota,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    titulo,
                    style: textos.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (texto != null)
                    Text(
                      texto,
                      style: textos.bodySmall?.copyWith(
                        color: cores.onSurfaceVariant,
                      ),
                    ),
                  if (rotulo != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CoresApp.primaria,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        rotulo,
                        style: const TextStyle(
                          color: CoresApp.branco,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (confirmacoes > 0)
                    Text(
                      '✓ Confirmada por $confirmacoes motoqueiros',
                      style: textos.bodySmall?.copyWith(
                        color: CoresApp.primaria,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatarDistancia(metros),
              style: textos.labelLarge?.copyWith(color: cores.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultadosPesquisa extends StatelessWidget {
  const ResultadosPesquisa({
    required this.estado,
    required this.aoEscolher,
    required this.aoEscolherNoMapa,
    required this.aoRepetir,
    super.key,
  });

  final EstadoPesquisaDestino estado;
  final ValueChanged<Local> aoEscolher;
  final VoidCallback aoEscolherNoMapa;
  final VoidCallback aoRepetir;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    if (estado.erro != null) {
      return EstadoVazio(
        icone: Icons.wifi_off,
        titulo: 'Não foi possível pesquisar',
        descricao: estado.erro!,
        textoAcao: 'Tentar de novo',
        aoTocarAcao: aoRepetir,
      );
    }
    if (estado.aPesquisar) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: IndicadorCarregamento(),
      );
    }
    if (estado.jaPesquisouAlgumaVez && estado.resultados.isEmpty) {
      return EstadoVazio(
        icone: Icons.search_off,
        titulo: 'Sem resultados',
        descricao: 'Não encontrámos nenhum lugar com esse nome.',
        textoAcao: 'Marcar no mapa',
        aoTocarAcao: aoEscolherNoMapa,
      );
    }
    return Column(
      children: <Widget>[
        for (final Local local in estado.resultados)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.location_on_outlined,
              color: cores.onSurfaceVariant,
            ),
            title: Text(local.nome),
            subtitle: local.descricao == null ? null : Text(local.descricao!),
            onTap: () => aoEscolher(local),
          ),
      ],
    );
  }
}
