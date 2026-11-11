import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/cadastro_motoqueiro/dados/selector_imagem.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/dominio/excecao_selector_imagem.dart';
import 'package:project_x/funcionalidades/localizacao/apresentacao/controladores/controlador_mapa.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';
import 'package:project_x/funcionalidades/paragens/apresentacao/controladores/controlador_paragens.dart';
import 'package:project_x/funcionalidades/paragens/dominio/paragem.dart';
import 'package:project_x/funcionalidades/voz/apresentacao/controladores/controlador_gravacao.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/nucleo/tema/tema_app.dart';
import 'package:project_x/partilhado/widgets/botao_principal.dart';
import 'package:project_x/partilhado/widgets/elementos_rota.dart';
import 'package:project_x/partilhado/widgets/imagem_local.dart';
import 'package:project_x/partilhado/widgets/mapa_rota.dart';
import 'package:project_x/partilhado/widgets/painel_voz.dart';

/// De onde veio o ponto da paragem.
enum _OrigemPonto { gps, mapa }

class EcraGravarParagem extends ConsumerStatefulWidget {
  const EcraGravarParagem({super.key});

  @override
  ConsumerState<EcraGravarParagem> createState() => _EcraGravarParagemState();
}

class _EcraGravarParagemState extends ConsumerState<EcraGravarParagem> {
  static const Coordenada _centroVilankulos = Coordenada(
    latitude: -21.9833,
    longitude: 35.3167,
  );
  static const double _zoom = 17;

  final TextEditingController _nome = TextEditingController();
  final MapController _controladorMapa = MapController();
  late Coordenada _ponto;
  _OrigemPonto _origem = _OrigemPonto.mapa;
  bool _aLocalizar = false;
  String? _erroGps;
  CategoriaParagem _categoria = CategoriaParagem.barraca;
  bool _partilhar = true;
  String? _foto;

  @override
  void initState() {
    super.initState();
    _ponto =
        ref.read(controladorMapaProvider).posicaoAtual ?? _centroVilankulos;
    WidgetsBinding.instance.addPostFrameCallback(
      (Duration _) => _usarLocalizacaoAtual(),
    );
  }

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  /// Pede ao GPS a posição exata deste momento e põe o pin lá.
  Future<void> _usarLocalizacaoAtual() async {
    setState(() {
      _aLocalizar = true;
      _erroGps = null;
    });
    final ControladorMapa controlador = ref.read(
      controladorMapaProvider.notifier,
    );
    await controlador.actualizarPosicao();
    if (!mounted) {
      return;
    }
    final EstadoMapa estado = ref.read(controladorMapaProvider);
    final Coordenada? posicao = estado.posicaoAtual;
    setState(() {
      _aLocalizar = false;
      if (estado.erro != null || posicao == null) {
        _erroGps =
            estado.erro ??
            'Não foi possível obter a tua localização. Tenta de novo.';
        return;
      }
      _ponto = posicao;
      _origem = _OrigemPonto.gps;
    });
    if (posicao != null && estado.erro == null) {
      _controladorMapa.move(paraLatLng(posicao), _zoom);
    }
  }

  void _aoMoverMapa(MapCamera camera, bool comGesto) {
    if (!comGesto) {
      return;
    }
    setState(() {
      _ponto = Coordenada(
        latitude: camera.center.latitude,
        longitude: camera.center.longitude,
      );
      _origem = _OrigemPonto.mapa;
    });
  }

  Future<void> _tirarFoto() async {
    try {
      final String? caminho = await ref
          .read(selectorImagemProvider)
          .tirarFotografia();
      if (caminho != null && mounted) {
        setState(() => _foto = caminho);
      }
    } on ExcecaoSelectorImagem {
      if (mounted) {
        mostrarAviso(
          context,
          'Não foi possível abrir a câmara. Autoriza o acesso nas definições '
          'do telemóvel.',
        );
      }
    }
  }

  Future<void> _gravar() async {
    final Paragem? paragem = await ref
        .read(controladorParagensProvider.notifier)
        .gravar(
          nome: _nome.text,
          coordenada: _ponto,
          categoria: _categoria,
          partilhar: _partilhar,
          notaVoz: ref.read(controladorGravacaoProvider).nota,
          caminhoFoto: _foto,
        );
    if (!mounted) {
      return;
    }
    if (paragem == null) {
      final String? erro = ref.read(controladorParagensProvider).erro;
      if (erro != null) {
        mostrarAviso(context, erro);
      }
      return;
    }
    Navigator.of(context).pop(paragem);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textos = Theme.of(context).textTheme;
    final bool aGravar = ref.watch(
      controladorParagensProvider.select((EstadoParagens e) => e.aGravar),
    );
    final double alturaMapa = MediaQuery.sizeOf(context).height * 0.32;

    return Scaffold(
      body: Column(
        children: <Widget>[
          SizedBox(
            height: alturaMapa,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                MapaRota(
                  centro: _ponto,
                  zoom: _zoom,
                  controlador: _controladorMapa,
                  aoMover: _aoMoverMapa,
                ),
                const Center(
                  child: Padding(
                    // A ponta do pin fica no centro do mapa.
                    padding: EdgeInsets.only(bottom: 40),
                    child: IgnorePointer(
                      child: Icon(
                        Icons.location_pin,
                        size: 44,
                        color: CoresApp.terracota,
                      ),
                    ),
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
                            icone: Icons.arrow_back_ios_new,
                            dica: 'Voltar',
                            aoTocar: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: CoresApp.marinho,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Arrasta o mapa para acertar o pin',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: CoresApp.creme,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              children: <Widget>[
                Text('GRAVAR PARAGEM', style: textos.headlineSmall),
                const SizedBox(height: 16),
                Text('Onde fica?', style: textos.labelLarge),
                const SizedBox(height: 8),
                _CartaoLocal(
                  origem: _origem,
                  aLocalizar: _aLocalizar,
                  erro: _erroGps,
                  aoUsarLocalizacao: _usarLocalizacaoAtual,
                ),
                const SizedBox(height: 16),
                Text('Nome que toda a gente conhece', style: textos.labelLarge),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _nome,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Barraca da Tia Rosa',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _BotaoFoto(foto: _foto, aoTocar: _tirarFoto),
                  ],
                ),
                const SizedBox(height: 12),
                const PainelVoz(
                  dica: 'Grava como se chega lá, com as tuas palavras.',
                ),
                const SizedBox(height: 12),
                Text('Que lugar é?', style: textos.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final CategoriaParagem categoria
                        in categoriasGravaveis)
                      ChipOpcao(
                        texto: categoria.nome,
                        selecionado: categoria == _categoria,
                        aoTocar: () => setState(() => _categoria = categoria),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _LinhaPartilhar(
                  valor: _partilhar,
                  aoMudar: (bool valor) => setState(() => _partilhar = valor),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: BotaoPrincipal(
                texto: 'Gravar paragem',
                aCarregar: aGravar,
                aoPremir: _aLocalizar ? null : _gravar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoLocal extends StatelessWidget {
  const _CartaoLocal({
    required this.origem,
    required this.aLocalizar,
    required this.erro,
    required this.aoUsarLocalizacao,
  });

  final _OrigemPonto origem;
  final bool aLocalizar;
  final String? erro;
  final VoidCallback aoUsarLocalizacao;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TextTheme textos = Theme.of(context).textTheme;
    final String? mensagemErro = erro;

    final (IconData icone, String titulo, String descricao) = aLocalizar
        ? (
            Icons.gps_not_fixed,
            'A procurar a tua localização…',
            'Fica ao ar livre para o GPS ser mais exato.',
          )
        : mensagemErro != null
        ? (Icons.gps_off, 'Sem localização', mensagemErro)
        : origem == _OrigemPonto.gps
        ? (
            Icons.my_location,
            'A tua localização atual',
            'Se a paragem fica noutro sítio, arrasta o mapa.',
          )
        : (
            Icons.place_outlined,
            'Ponto escolhido no mapa',
            'Estás no lugar da paragem? Usa a tua localização.',
          );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mensagemErro != null && !aLocalizar
            ? cores.errorContainer
            : cores.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (aLocalizar)
                const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else
                Icon(icone, color: cores.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      titulo,
                      style: textos.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      descricao,
                      style: textos.bodySmall?.copyWith(
                        color: cores.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!aLocalizar && origem != _OrigemPonto.gps) ...<Widget>[
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
                ),
              ),
              onPressed: aoUsarLocalizacao,
              icon: const Icon(Icons.my_location),
              label: Text(
                mensagemErro != null
                    ? 'Tentar de novo'
                    : 'Usar a minha localização atual',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BotaoFoto extends StatelessWidget {
  const _BotaoFoto({required this.foto, required this.aoTocar});

  final String? foto;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final String? caminho = foto;
    return InkWell(
      onTap: aoTocar,
      borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
      child: Container(
        width: 84,
        height: 56,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cores.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
          border: Border.all(color: cores.outline, width: 1.5),
        ),
        child: caminho == null
            ? const Icon(Icons.add_a_photo_outlined, color: CoresApp.terracota)
            : ImagemLocal(
                caminho: caminho,
                alternativa: const Icon(
                  Icons.image_outlined,
                  color: CoresApp.terracota,
                ),
              ),
      ),
    );
  }
}

class _LinhaPartilhar extends StatelessWidget {
  const _LinhaPartilhar({required this.valor, required this.aoMudar});

  final bool valor;
  final ValueChanged<bool> aoMudar;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TextTheme textos = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cores.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Partilhar com a comunidade',
                  style: textos.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Fica visível quando '
                  '${Paragem.confirmacoesParaFicarVisivel} motoqueiros '
                  'confirmarem',
                  style: textos.bodySmall?.copyWith(
                    color: cores.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: valor, onChanged: aoMudar),
        ],
      ),
    );
  }
}
