import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/funcionalidades/autenticacao/dominio/utilizador.dart';
import 'package:project_x/funcionalidades/corrida/apresentacao/controladores/controlador_corrida.dart';
import 'package:project_x/funcionalidades/inicio/apresentacao/widgets/aba_perfil.dart';
import 'package:project_x/funcionalidades/inicio/apresentacao/widgets/folha_pedido_viagem.dart';
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
import 'package:project_x/partilhado/widgets/mapa_rota.dart';
import 'package:project_x/partilhado/widgets/marcadores_mapa.dart';
import 'package:project_x/rotas/rotas_app.dart';

class EcraMapaInicio extends ConsumerStatefulWidget {
  const EcraMapaInicio({super.key});

  @override
  ConsumerState<EcraMapaInicio> createState() => _EcraMapaInicioState();
}

class _EcraMapaInicioState extends ConsumerState<EcraMapaInicio> {
  static const double _zoomInicial = 15;
  static const Coordenada _centroVilankulos = Coordenada(
    latitude: -21.9833,
    longitude: 35.3167,
  );

  final MapController _controladorMapa = MapController();
  final GlobalKey<ScaffoldState> _chaveScaffold = GlobalKey<ScaffoldState>();
  final TextEditingController _campoDestino = TextEditingController();
  final FocusNode _focoDestino = FocusNode();

  @override
  void initState() {
    super.initState();
    _focoDestino.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      final EstadoMapa estado = ref.read(controladorMapaProvider);
      if (estado.posicaoAtual == null && !estado.aCarregar) {
        ref.read(controladorMapaProvider.notifier).actualizarPosicao();
      }
      ref.read(controladorParagensProvider.notifier).carregar();
    });
  }

  @override
  void dispose() {
    _campoDestino.dispose();
    _focoDestino.dispose();
    super.dispose();
  }

  bool get _emProcura =>
      _focoDestino.hasFocus ||
      _campoDestino.text.isNotEmpty ||
      ref.read(controladorDitadoProvider).aOuvir ||
      ref.read(controladorDitadoProvider).erro != null;

  void _aoMudarTexto(String termo) {
    setState(() {});
    ref
        .read(controladorPesquisaDestinoProvider.notifier)
        .mudarTermo(
          termo,
          perto: ref.read(controladorMapaProvider).posicaoAtual,
        );
  }

  void _escolherDestino(Local local) {
    _sairDaProcura();
    ref.read(controladorMapaProvider.notifier).escolherDestino(local);
  }

  void _sairDaProcura() {
    _focoDestino.unfocus();
    _campoDestino.clear();
    ref.read(controladorPesquisaDestinoProvider.notifier).mudarTermo('');
    ref.read(controladorDitadoProvider.notifier).limpar();
    setState(() {});
  }

  /// Mudar o destino já escolhido: volta à caixa de texto, no mesmo ecrã.
  void _mudarDestino() {
    ref.read(controladorMapaProvider.notifier).limparDestino();
    _focoDestino.requestFocus();
  }

  Future<void> _marcarNoMapa() async {
    _focoDestino.unfocus();
    final Local? escolhido = await context.push<Local>(Rotas.ajustarPonto);
    if (escolhido != null && mounted) {
      _escolherDestino(escolhido);
    }
  }

  /// Diz o destino, pesquisa-o e, se houver correspondência, marca-o logo
  /// — a folha passa a mostrar os veículos e os preços.
  Future<void> _ditar() async {
    _focoDestino.unfocus();
    final EstadoParagens paragens = ref.read(controladorParagensProvider);
    setState(() {});
    final String? frase = await ref
        .read(controladorDitadoProvider.notifier)
        .ditar(
          frasesProvaveis: <String>[
            for (final MarcoConhecido marco in paragens.marcos) marco.nomeCurto,
            for (final Paragem paragem in paragens.minhas) paragem.nome,
          ],
        );
    if (!mounted) {
      return;
    }
    if (frase == null) {
      setState(() {});
      return;
    }
    final Local? local = await ref
        .read(controladorPesquisaDestinoProvider.notifier)
        .pesquisarPorVoz(
          frase,
          perto: ref.read(controladorMapaProvider).posicaoAtual,
          conhecidos: <Local>[
            for (final MarcoConhecido marco in paragens.marcos)
              marco.comoLocal(),
            for (final Paragem paragem in paragens.minhas) paragem.comoLocal(),
            for (final Paragem paragem in paragens.comunidade)
              paragem.comoLocal(),
          ],
        );
    if (!mounted) {
      return;
    }
    if (local != null) {
      _escolherDestino(local);
      return;
    }
    setState(
      () => _campoDestino.text = ref
          .read(controladorPesquisaDestinoProvider)
          .termo,
    );
  }

  Future<void> _recentrar() async {
    await ref.read(controladorMapaProvider.notifier).actualizarPosicao();
    final Coordenada? posicao = ref.read(controladorMapaProvider).posicaoAtual;
    if (posicao != null) {
      _controladorMapa.move(paraLatLng(posicao), _zoomInicial);
    }
  }

  void _abrirDoMenu(String rota) {
    _chaveScaffold.currentState?.closeDrawer();
    context.push(rota);
  }

  void _enquadrarRota(Coordenada origem, Coordenada destino) {
    final double alturaFolha = MediaQuery.sizeOf(context).height * 0.55;
    _controladorMapa.fitCamera(
      CameraFit.coordinates(
        coordinates: <LatLng>[paraLatLng(origem), paraLatLng(destino)],
        padding: EdgeInsets.fromLTRB(48, 120, 48, alturaFolha),
        maxZoom: 16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      controladorCorridaProvider.select((EstadoCorrida e) => e.erro),
      (String? anterior, String? erro) {
        if (erro != null) {
          mostrarAviso(context, erro);
          ref.read(controladorCorridaProvider.notifier).limparErro();
        }
      },
    );
    ref.listen<Local?>(
      controladorMapaProvider.select((EstadoMapa e) => e.destino),
      (Local? anterior, Local? destino) {
        final Coordenada origem =
            ref.read(controladorMapaProvider).posicaoAtual ?? _centroVilankulos;
        if (destino != null) {
          _enquadrarRota(origem, destino.coordenada);
        } else {
          _controladorMapa.move(paraLatLng(origem), _zoomInicial);
        }
      },
    );

    final EstadoMapa mapa = ref.watch(controladorMapaProvider);
    final EstadoParagens paragens = ref.watch(controladorParagensProvider);
    // Mantém o ditado vivo enquanto este ecrã estiver aberto.
    ref.watch(controladorDitadoProvider);
    final bool emProcura = _emProcura;
    final bool aPedir = ref.watch(
      controladorCorridaProvider.select((EstadoCorrida e) => e.aProcessar),
    );
    final Utilizador? utilizador = ref.watch(
      controladorAutenticacaoProvider.select(
        (EstadoAutenticacao estado) => estado.utilizador,
      ),
    );
    final Coordenada? posicao = mapa.posicaoAtual;
    final Coordenada origem = posicao ?? _centroVilankulos;
    final Local? destino = mapa.destino;
    final MarcoConhecido? marcoPerto = posicao == null
        ? null
        : paragens.marcoMaisProximo(posicao);

    return PopScope(
      canPop: destino == null && !emProcura,
      onPopInvokedWithResult: (bool saiu, Object? _) {
        if (saiu || aPedir) {
          return;
        }
        if (emProcura) {
          _sairDaProcura();
        } else {
          ref.read(controladorMapaProvider.notifier).limparDestino();
        }
      },
      child: Scaffold(
        key: _chaveScaffold,
        drawer: _MenuLateral(utilizador: utilizador, aoAbrir: _abrirDoMenu),
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned.fill(
              child: MapaRota(
                centro: origem,
                zoom: _zoomInicial,
                controlador: _controladorMapa,
                alinhamentoCreditos: Alignment.topRight,
                margemCreditos: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top + 68,
                  right: 16,
                ),
                linhas: <Polyline<Object>>[
                  if (destino != null)
                    Polyline<Object>(
                      points: <LatLng>[
                        paraLatLng(origem),
                        paraLatLng(destino.coordenada),
                      ],
                      color: CoresApp.marinho,
                      strokeWidth: 5,
                    ),
                ],
                marcadores: <Marker>[
                  if (posicao != null || destino != null)
                    Marker(
                      point: paraLatLng(origem),
                      width: 56,
                      height: 56,
                      child: const MarcadorPosicao(),
                    ),
                  if (destino != null)
                    Marker(
                      point: paraLatLng(destino.coordenada),
                      width: 36,
                      height: 36,
                      child: const MarcadorDestino(),
                    ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: <Widget>[
                      BotaoRedondo(
                        icone: Icons.menu,
                        dica: 'Abrir menu',
                        aoTocar: () =>
                            _chaveScaffold.currentState?.openDrawer(),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: _PilulaPosicao(
                          texto: posicao == null
                              ? 'A mostrar Vilankulo'
                              : marcoPerto == null
                              ? 'A tua posição'
                              : 'Perto de: ${marcoPerto.nomeCurto}',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (!emProcura)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Expanded(
                            child: destino != null || mapa.erro == null
                                ? const SizedBox.shrink()
                                : _AvisoErro(
                                    mensagem: mapa.erro!,
                                    aoRepetir: _recentrar,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          BotaoRedondo(
                            icone: Icons.my_location,
                            dica: 'Ir para a minha posição',
                            aoTocar: _recentrar,
                          ),
                        ],
                      ),
                    ),
                  FolhaPedidoViagem(
                    primeiroNome: utilizador?.primeiroNome,
                    origemNome: marcoPerto?.nomeCurto ?? 'Aqui',
                    distanciaKm: destino == null
                        ? null
                        : origem.distanciaEmMetrosAte(destino.coordenada) /
                              1000,
                    referencia: origem,
                    campoTexto: _campoDestino,
                    foco: _focoDestino,
                    emProcura: emProcura,
                    aoMudarTexto: _aoMudarTexto,
                    aoDitar: _ditar,
                    aoEscolherDestino: _escolherDestino,
                    aoMarcarNoMapa: _marcarNoMapa,
                    aoMudarDestino: _mudarDestino,
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

class _PilulaPosicao extends StatelessWidget {
  const _PilulaPosicao({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CoresApp.creme,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.place_outlined, size: 18, color: CoresApp.primaria),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CoresApp.marinho,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoErro extends StatelessWidget {
  const _AvisoErro({required this.mensagem, required this.aoRepetir});

  final String mensagem;
  final VoidCallback aoRepetir;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 2, 2, 2),
      decoration: BoxDecoration(
        color: CoresApp.creme,
        borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              mensagem,
              style: const TextStyle(color: CoresApp.marinho, fontSize: 12),
            ),
          ),
          TextButton(onPressed: aoRepetir, child: const Text('Repetir')),
        ],
      ),
    );
  }
}

class _MenuLateral extends ConsumerWidget {
  const _MenuLateral({required this.utilizador, required this.aoAbrir});

  final Utilizador? utilizador;
  final ValueChanged<String> aoAbrir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textos = Theme.of(context).textTheme;
    final ColorScheme cores = Theme.of(context).colorScheme;
    final Utilizador? atual = utilizador;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const LogoRota(),
                  const SizedBox(height: 16),
                  Text(
                    atual?.nome ?? 'Sem nome',
                    style: textos.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Perfil'),
              onTap: () => aoAbrir(Rotas.perfilPassageiro),
            ),
            ListTile(
              leading: const Icon(Icons.route_outlined),
              title: const Text('As tuas viagens'),
              onTap: () => aoAbrir(Rotas.viagens),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text('Paragens'),
              onTap: () => aoAbrir(Rotas.paragens),
            ),
            ListTile(
              leading: const Icon(Icons.two_wheeler_outlined),
              title: const Text('Trabalhar como motorista'),
              subtitle: const Text('Mototaxista, txopelista ou taxista'),
              onTap: () {
                Scaffold.of(context).closeDrawer();
                ref
                    .read(controladorAutenticacaoProvider.notifier)
                    .voltarAEscolherTipo();
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Créditos das imagens'),
              onTap: () => aoAbrir(Rotas.creditosImagens),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: cores.error),
              title: Text(
                'Terminar sessão',
                style: TextStyle(color: cores.error),
              ),
              onTap: () => terminarSessaoComConfirmacao(context, ref),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
