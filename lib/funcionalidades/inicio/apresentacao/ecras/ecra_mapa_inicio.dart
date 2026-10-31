import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/funcionalidades/inicio/apresentacao/widgets/seletor_tipo_veiculo.dart';
import 'package:project_x/funcionalidades/inicio/dominio/tipo_veiculo.dart';
import 'package:project_x/funcionalidades/localizacao/apresentacao/controladores/controlador_mapa.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/local.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/nucleo/tema/tema_app.dart';
import 'package:project_x/nucleo/utilitarios/formatadores.dart';
import 'package:project_x/partilhado/widgets/botao_principal.dart';
import 'package:project_x/rotas/rotas_app.dart';

class EcraMapaInicio extends ConsumerStatefulWidget {
  const EcraMapaInicio({super.key});

  @override
  ConsumerState<EcraMapaInicio> createState() => _EcraMapaInicioState();
}

class _EcraMapaInicioState extends ConsumerState<EcraMapaInicio> {
  static const LatLng _centroVilankulos = LatLng(-21.9833, 35.3167);
  static const double _zoomInicial = 15;

  final MapController _controladorMapa = MapController();
  TipoVeiculo _tipoVeiculoSelecionado = TipoVeiculo.mota;

  @override
  void initState() {
    super.initState();
    final EstadoMapa estado = ref.read(controladorMapaProvider);
    if (estado.posicaoAtual == null && !estado.aCarregar) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        ref.read(controladorMapaProvider.notifier).actualizarPosicao();
      });
    }
  }

  void _mostrarEmBreve() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Em breve.')),
    );
  }

  Future<void> _abrirPesquisa() async {
    final Local? escolhido = await context.push<Local>(Rotas.pesquisaDestino);
    if (escolhido != null) {
      ref.read(controladorMapaProvider.notifier).escolherDestino(escolhido);
    }
  }

  Future<void> _recentrar() async {
    await ref.read(controladorMapaProvider.notifier).actualizarPosicao();
    final Coordenada? posicao = ref.read(controladorMapaProvider).posicaoAtual;
    if (posicao != null) {
      _controladorMapa.move(
        LatLng(posicao.latitude, posicao.longitude),
        _zoomInicial,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final EstadoMapa estadoMapa = ref.watch(controladorMapaProvider);
    final String primeiroNome = ref.watch(
      controladorAutenticacaoProvider.select(
        (EstadoAutenticacao estado) => estado.utilizador?.primeiroNome ?? '',
      ),
    );

    final Coordenada? posicao = estadoMapa.posicaoAtual;
    final LatLng centro = posicao != null
        ? LatLng(posicao.latitude, posicao.longitude)
        : _centroVilankulos;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          FlutterMap(
            mapController: _controladorMapa,
            options: MapOptions(initialCenter: centro, initialZoom: _zoomInicial),
            children: <Widget>[
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.project_x',
              ),
              if (posicao != null)
                MarkerLayer(
                  markers: <Marker>[
                    Marker(
                      point: centro,
                      width: 44,
                      height: 44,
                      child: const _MarcadorPosicaoAtual(),
                    ),
                  ],
                ),
              const SimpleAttributionWidget(
                source: Text('OpenStreetMap contributors'),
              ),
            ],
          ),
          SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _BotaoFlutuante(
                        icone: Icons.menu,
                        aoTocar: _mostrarEmBreve,
                      ),
                    ],
                  ),
                ),
                if (posicao == null && !estadoMapa.aCarregar)
                  const _BarraInformativa(
                    icone: Icons.info_outline,
                    mensagem: 'Mostrando Vilankulos. A obter a sua posição…',
                  ),
                if (estadoMapa.aCarregar && posicao == null)
                  const LinearProgressIndicator(minHeight: 3),
                if (estadoMapa.erro != null)
                  _BarraInformativa(
                    icone: Icons.error_outline,
                    mensagem: estadoMapa.erro!,
                    textoAcao: 'Tentar de novo',
                    aoTocarAcao: () =>
                        ref.read(controladorMapaProvider.notifier).actualizarPosicao(),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _recentrar,
        backgroundColor: cores.primary,
        foregroundColor: cores.onPrimary,
        child: const Icon(Icons.my_location),
      ),
      bottomSheet: _FolhaInferior(
        primeiroNome: primeiroNome,
        destino: estadoMapa.destino,
        tipoVeiculoSelecionado: _tipoVeiculoSelecionado,
        precos: estadoMapa.precosEstimados,
        aCalcularPrecos: estadoMapa.aCalcularPrecos,
        aoTocarPesquisa: _abrirPesquisa,
        aoTocarAtalho: _mostrarEmBreve,
        aoTocarAdicionarParagem: _abrirPesquisa,
        aoLimparDestino: () =>
            ref.read(controladorMapaProvider.notifier).limparDestino(),
        aoSelecionarTipoVeiculo: (TipoVeiculo tipo) =>
            setState(() => _tipoVeiculoSelecionado = tipo),
        aoPedirViagem: _mostrarEmBreve,
      ),
    );
  }
}

class _MarcadorPosicaoAtual extends StatelessWidget {
  const _MarcadorPosicaoAtual();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: CoresApp.destaqueClara,
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: CoresApp.destaque,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _BotaoFlutuante extends StatelessWidget {
  const _BotaoFlutuante({required this.icone, required this.aoTocar});

  final IconData icone;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    return Material(
      color: cores.surface,
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(icon: Icon(icone, color: cores.onSurface), onPressed: aoTocar),
    );
  }
}

class _BarraInformativa extends StatelessWidget {
  const _BarraInformativa({
    required this.icone,
    required this.mensagem,
    this.textoAcao,
    this.aoTocarAcao,
  });

  final IconData icone;
  final String mensagem;
  final String? textoAcao;
  final VoidCallback? aoTocarAcao;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TextTheme textos = Theme.of(context).textTheme;
    final String? acao = textoAcao;
    final VoidCallback? aoTocar = aoTocarAcao;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: cores.surface,
      child: Row(
        children: <Widget>[
          Icon(icone, size: 18, color: cores.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensagem,
              style: textos.bodySmall?.copyWith(color: cores.onSurfaceVariant),
            ),
          ),
          if (acao != null && aoTocar != null)
            TextButton(onPressed: aoTocar, child: Text(acao)),
        ],
      ),
    );
  }
}

class _FolhaInferior extends StatelessWidget {
  const _FolhaInferior({
    required this.primeiroNome,
    required this.destino,
    required this.tipoVeiculoSelecionado,
    required this.precos,
    required this.aCalcularPrecos,
    required this.aoTocarPesquisa,
    required this.aoTocarAtalho,
    required this.aoTocarAdicionarParagem,
    required this.aoLimparDestino,
    required this.aoSelecionarTipoVeiculo,
    required this.aoPedirViagem,
  });

  final String primeiroNome;
  final Local? destino;
  final TipoVeiculo tipoVeiculoSelecionado;
  final Map<TipoVeiculo, double>? precos;
  final bool aCalcularPrecos;
  final VoidCallback aoTocarPesquisa;
  final VoidCallback aoTocarAtalho;
  final VoidCallback aoTocarAdicionarParagem;
  final VoidCallback aoLimparDestino;
  final ValueChanged<TipoVeiculo> aoSelecionarTipoVeiculo;
  final VoidCallback aoPedirViagem;

  String _textoBotaoPedir(double? preco) {
    return preco == null ? 'Pedir viagem' : 'Pedir viagem · ${formatarMt(preco)}';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TextTheme textos = Theme.of(context).textTheme;
    final Local? destinoEscolhido = destino;

    return Container(
      decoration: BoxDecoration(
        color: cores.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(TemaApp.raio),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: destinoEscolhido == null
            ? <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Olá, $primeiroNome', style: textos.titleMedium),
                ),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
                  onTap: aoTocarPesquisa,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: cores.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(
                        TemaApp.raioPequeno,
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.search, color: cores.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Text(
                          'Para onde vai?',
                          style: textos.bodyMedium?.copyWith(
                            color: cores.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _AtalhoDestino(
                        icone: Icons.home_outlined,
                        texto: 'Casa',
                        aoTocar: aoTocarAtalho,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AtalhoDestino(
                        icone: Icons.work_outline,
                        texto: 'Trabalho',
                        aoTocar: aoTocarAtalho,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AtalhoDestino(
                        icone: Icons.add_location_alt_outlined,
                        texto: 'Adicionar paragem',
                        aoTocar: aoTocarAdicionarParagem,
                      ),
                    ),
                  ],
                ),
              ]
            : <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.place, color: cores.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        destinoEscolhido.nome,
                        style: textos.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: aoLimparDestino,
                      color: cores.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SeletorTipoVeiculo(
                  selecionado: tipoVeiculoSelecionado,
                  aoSelecionar: aoSelecionarTipoVeiculo,
                  precos: precos,
                  aCalcularPrecos: aCalcularPrecos,
                ),
                const SizedBox(height: 16),
                BotaoPrincipal(
                  texto: _textoBotaoPedir(precos?[tipoVeiculoSelecionado]),
                  aoPremir: aoPedirViagem,
                  aCarregar: aCalcularPrecos,
                ),
              ],
      ),
    );
  }
}

class _AtalhoDestino extends StatelessWidget {
  const _AtalhoDestino({
    required this.icone,
    required this.texto,
    required this.aoTocar,
  });

  final IconData icone;
  final String texto;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
      onTap: aoTocar,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: cores.outline),
          borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
        ),
        child: Row(
          children: <Widget>[
            Icon(icone, size: 18, color: cores.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                texto,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
