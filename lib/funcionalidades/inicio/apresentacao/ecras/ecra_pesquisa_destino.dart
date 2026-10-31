import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:project_x/funcionalidades/localizacao/apresentacao/controladores/controlador_mapa.dart';
import 'package:project_x/funcionalidades/localizacao/apresentacao/controladores/controlador_pesquisa_destino.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/local.dart';
import 'package:project_x/partilhado/widgets/estado_vazio.dart';
import 'package:project_x/rotas/rotas_app.dart';

class EcraPesquisaDestino extends ConsumerStatefulWidget {
  const EcraPesquisaDestino({super.key});

  @override
  ConsumerState<EcraPesquisaDestino> createState() =>
      _EcraPesquisaDestinoState();
}

class _EcraPesquisaDestinoState extends ConsumerState<EcraPesquisaDestino> {
  final TextEditingController _controlador = TextEditingController();

  Coordenada? get _posicaoDeReferencia =>
      ref.read(controladorMapaProvider).posicaoAtual;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      ref
          .read(controladorPesquisaDestinoProvider.notifier)
          .carregarSugestoesIniciais(perto: _posicaoDeReferencia);
    });
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _escolherNoMapa() async {
    final Local? escolhido = await context.push<Local>(Rotas.ajustarPonto);
    if (escolhido != null && mounted) {
      Navigator.of(context).pop(escolhido);
    }
  }

  void _escolherLocal(Local local) {
    Navigator.of(context).pop(local);
  }

  @override
  Widget build(BuildContext context) {
    final EstadoPesquisaDestino estado = ref.watch(
      controladorPesquisaDestinoProvider,
    );
    final ColorScheme cores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controlador,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Para onde vai?',
            border: InputBorder.none,
          ),
          onChanged: (String termo) => ref
              .read(controladorPesquisaDestinoProvider.notifier)
              .mudarTermo(termo, perto: _posicaoDeReferencia),
        ),
      ),
      body: _Corpo(
        estado: estado,
        cores: cores,
        aoTentarNovamente: () => ref
            .read(controladorPesquisaDestinoProvider.notifier)
            .tentarNovamente(perto: _posicaoDeReferencia),
        aoEscolherLocal: _escolherLocal,
        aoEscolherNoMapa: _escolherNoMapa,
      ),
    );
  }
}

class _Corpo extends StatelessWidget {
  const _Corpo({
    required this.estado,
    required this.cores,
    required this.aoTentarNovamente,
    required this.aoEscolherLocal,
    required this.aoEscolherNoMapa,
  });

  final EstadoPesquisaDestino estado;
  final ColorScheme cores;
  final VoidCallback aoTentarNovamente;
  final ValueChanged<Local> aoEscolherLocal;
  final VoidCallback aoEscolherNoMapa;

  bool get _pesquisaAtiva => estado.termo.trim().length >= 3;

  @override
  Widget build(BuildContext context) {
    if (estado.erro != null) {
      return _EstadoErro(mensagem: estado.erro!, aoTentarNovamente: aoTentarNovamente);
    }

    if (estado.aPesquisar) {
      return const _EsqueletoResultados();
    }

    if (_pesquisaAtiva && estado.jaPesquisouAlgumaVez && estado.resultados.isEmpty) {
      return EstadoVazio(
        icone: Icons.search_off,
        titulo: 'Sem resultados',
        descricao: 'Não encontrámos nenhum lugar com esse nome.',
        textoAcao: 'Escolher no mapa',
        aoTocarAcao: aoEscolherNoMapa,
      );
    }

    return ListView.separated(
      itemCount: estado.resultados.length + 1,
      separatorBuilder: (BuildContext context, int indice) =>
          const Divider(height: 1),
      itemBuilder: (BuildContext context, int indice) {
        if (indice == estado.resultados.length) {
          return ListTile(
            leading: Icon(Icons.map_outlined, color: cores.primary),
            title: const Text('Escolher no mapa'),
            onTap: aoEscolherNoMapa,
          );
        }
        final Local local = estado.resultados[indice];
        return ListTile(
          leading: Icon(Icons.location_on_outlined, color: cores.onSurfaceVariant),
          title: Text(local.nome),
          subtitle: local.descricao != null
              ? Text(
                  local.descricao!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cores.onSurfaceVariant),
                )
              : null,
          onTap: () => aoEscolherLocal(local),
        );
      },
    );
  }
}

class _EsqueletoResultados extends StatelessWidget {
  const _EsqueletoResultados();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 3,
      separatorBuilder: (BuildContext context, int indice) =>
          const SizedBox(height: 4),
      itemBuilder: (BuildContext context, int indice) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: <Widget>[
              CircleAvatar(radius: 12, backgroundColor: cores.surfaceContainerHighest),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      height: 12,
                      width: 160,
                      color: cores.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 220,
                      color: cores.surfaceContainerHighest,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EstadoErro extends StatelessWidget {
  const _EstadoErro({required this.mensagem, required this.aoTentarNovamente});

  final String mensagem;
  final VoidCallback aoTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return EstadoVazio(
      icone: Icons.wifi_off,
      titulo: 'Não foi possível pesquisar',
      descricao: mensagem,
      textoAcao: 'Tentar de novo',
      aoTocarAcao: aoTentarNovamente,
    );
  }
}
