import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:project_x/funcionalidades/inicio/apresentacao/widgets/lista_destinos.dart';
import 'package:project_x/funcionalidades/localizacao/apresentacao/controladores/controlador_mapa.dart';
import 'package:project_x/funcionalidades/localizacao/apresentacao/controladores/controlador_pesquisa_destino.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/local.dart';
import 'package:project_x/funcionalidades/paragens/apresentacao/controladores/controlador_paragens.dart';
import 'package:project_x/funcionalidades/paragens/dominio/paragem.dart';
import 'package:project_x/funcionalidades/voz/apresentacao/controladores/controlador_ditado.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/nucleo/tema/tema_app.dart';
import 'package:project_x/partilhado/widgets/elementos_rota.dart';
import 'package:project_x/rotas/rotas_app.dart';

class EcraPesquisaDestino extends ConsumerStatefulWidget {
  const EcraPesquisaDestino({super.key});

  @override
  ConsumerState<EcraPesquisaDestino> createState() =>
      _EcraPesquisaDestinoState();
}

class _EcraPesquisaDestinoState extends ConsumerState<EcraPesquisaDestino> {
  static const Coordenada _centroVilankulos = Coordenada(
    latitude: -21.9833,
    longitude: 35.3167,
  );

  final TextEditingController _controlador = TextEditingController();

  Coordenada? get _posicaoDeReferencia =>
      ref.read(controladorMapaProvider).posicaoAtual;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      final EstadoParagens paragens = ref.read(controladorParagensProvider);
      if (paragens.marcos.isEmpty && !paragens.aCarregar) {
        ref.read(controladorParagensProvider.notifier).carregar();
      }
      ref
          .read(controladorPesquisaDestinoProvider.notifier)
          .mudarTermo('', perto: _posicaoDeReferencia);
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

  Future<void> _gravarParagem() async {
    final Paragem? paragem = await context.push<Paragem>(Rotas.gravarParagem);
    if (paragem != null && mounted) {
      Navigator.of(context).pop(paragem.comoLocal());
    }
  }

  /// Diz o destino, pesquisa-o e, se houver correspondência, marca-o logo:
  /// o ecrã principal mostra então os veículos e os preços.
  Future<void> _ditar() async {
    final EstadoParagens paragens = ref.read(controladorParagensProvider);
    final String? frase = await ref
        .read(controladorDitadoProvider.notifier)
        .ditar(
          frasesProvaveis: <String>[
            for (final MarcoConhecido marco in paragens.marcos) marco.nomeCurto,
            for (final Paragem paragem in paragens.minhas) paragem.nome,
          ],
        );
    if (frase == null || !mounted) {
      return;
    }
    final Local? local = await ref
        .read(controladorPesquisaDestinoProvider.notifier)
        .pesquisarPorVoz(frase, perto: _posicaoDeReferencia);
    if (!mounted) {
      return;
    }
    setState(
      () => _controlador.text = ref
          .read(controladorPesquisaDestinoProvider)
          .termo,
    );
    if (local != null) {
      _escolher(local);
    }
  }

  void _escolher(Local local) => Navigator.of(context).pop(local);

  @override
  Widget build(BuildContext context) {
    final TextTheme textos = Theme.of(context).textTheme;
    final EstadoPesquisaDestino pesquisa = ref.watch(
      controladorPesquisaDestinoProvider,
    );
    final bool aPesquisar = _controlador.text.trim().length >= 3;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      BotaoRedondo(
                        icone: Icons.arrow_back_ios_new,
                        dica: 'Voltar',
                        aoTocar: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('VAIS ONDE?', style: textos.headlineMedium),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _CartaoDitado(aoTocar: _ditar),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controlador,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Ou escreve: mercado, porto, barraca…',
                    ),
                    onChanged: (String termo) {
                      setState(() {});
                      ref
                          .read(controladorPesquisaDestinoProvider.notifier)
                          .mudarTermo(termo, perto: _posicaoDeReferencia);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (aPesquisar)
                    ResultadosPesquisa(
                      estado: pesquisa,
                      aoEscolher: _escolher,
                      aoEscolherNoMapa: _escolherNoMapa,
                      aoRepetir: () => ref
                          .read(controladorPesquisaDestinoProvider.notifier)
                          .tentarNovamente(perto: _posicaoDeReferencia),
                    )
                  else
                    ListaLugares(
                      referencia: _posicaoDeReferencia ?? _centroVilankulos,
                      aoEscolher: _escolher,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _escolherNoMapa,
                      child: const Text('Marcar no mapa'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: CoresApp.marinho,
                        foregroundColor: CoresApp.creme,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: _gravarParagem,
                      child: const Text('+ Paragem nova'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoDitado extends ConsumerWidget {
  const _CartaoDitado({required this.aoTocar});

  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EstadoDitado estado = ref.watch(controladorDitadoProvider);
    final bool aProcurar =
        !estado.aOuvir &&
        estado.erro == null &&
        estado.textoParcial.isNotEmpty &&
        ref.watch(
          controladorPesquisaDestinoProvider.select(
            (EstadoPesquisaDestino e) => e.aPesquisar,
          ),
        );
    final String? erro = estado.erro;
    final String texto = estado.aOuvir
        ? (estado.textoParcial.isEmpty
              ? 'A ouvir… diz para onde vais.'
              : '«${estado.textoParcial}»')
        : aProcurar
        ? 'A procurar «${estado.textoParcial}»…'
        : 'Toca no microfone e diz para onde vais. Por exemplo: '
              '«mercado municipal».';

    return Material(
      color: CoresApp.marinho,
      borderRadius: BorderRadius.circular(TemaApp.raio),
      child: InkWell(
        onTap: aProcurar ? null : aoTocar,
        borderRadius: BorderRadius.circular(TemaApp.raio),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: estado.aOuvir ? CoresApp.destaque : CoresApp.terracota,
                  border: Border.all(color: CoresApp.destaque, width: 3),
                ),
                child: aProcurar
                    ? const Padding(
                        padding: EdgeInsets.all(18),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: CoresApp.branco,
                        ),
                      )
                    : Icon(
                        estado.aOuvir ? Icons.stop_rounded : Icons.mic_rounded,
                        size: 34,
                        color: estado.aOuvir
                            ? CoresApp.marinho
                            : CoresApp.branco,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      estado.aOuvir ? 'A OUVIR' : 'DIZ O DESTINO',
                      style: const TextStyle(
                        color: CoresApp.destaque,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      texto,
                      style: const TextStyle(
                        color: CoresApp.creme,
                        fontSize: 15,
                      ),
                    ),
                    if (erro != null && !estado.aOuvir)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          erro,
                          style: const TextStyle(
                            color: CoresApp.destaque,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
