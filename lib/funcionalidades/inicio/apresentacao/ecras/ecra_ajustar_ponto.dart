import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:project_x/funcionalidades/localizacao/apresentacao/controladores/controlador_mapa.dart';
import 'package:project_x/funcionalidades/localizacao/dados/repositorio_lugares.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/local.dart';
import 'package:project_x/nucleo/tema/tema_app.dart';
import 'package:project_x/partilhado/widgets/botao_principal.dart';

class EcraAjustarPonto extends ConsumerStatefulWidget {
  const EcraAjustarPonto({super.key});

  static const Coordenada _centroVilankulos = Coordenada(
    latitude: -21.9833,
    longitude: 35.3167,
  );

  @override
  ConsumerState<EcraAjustarPonto> createState() => _EcraAjustarPontoState();
}

class _EcraAjustarPontoState extends ConsumerState<EcraAjustarPonto> {
  static const Duration _atrasoAposParar = Duration(milliseconds: 400);

  Timer? _temporizador;
  int _geracao = 0;
  bool _aMover = true;
  Local? _localAtual;

  Coordenada get _centroInicial =>
      ref.read(controladorMapaProvider).posicaoAtual ??
      EcraAjustarPonto._centroVilankulos;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      _resolverEndereco(_centroInicial);
    });
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  void _aoMoverMapa(MapCamera camera, bool comGesto) {
    _temporizador?.cancel();
    if (!_aMover) {
      setState(() => _aMover = true);
    }
    _temporizador = Timer(_atrasoAposParar, () {
      _resolverEndereco(
        Coordenada(
          latitude: camera.center.latitude,
          longitude: camera.center.longitude,
        ),
      );
    });
  }

  Future<void> _resolverEndereco(Coordenada coordenada) async {
    final int geracaoDoPedido = ++_geracao;
    final Local? local = await ref
        .read(repositorioLugaresProvider)
        .localEmCoordenada(coordenada);
    if (!mounted || geracaoDoPedido != _geracao) {
      return;
    }
    setState(() {
      _aMover = false;
      _localAtual = local;
    });
  }

  void _confirmar() {
    final Local? local = _localAtual;
    if (local != null) {
      Navigator.of(context).pop(local);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final Coordenada centro = _centroInicial;

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(centro.latitude, centro.longitude),
              initialZoom: 16,
              onPositionChanged: _aoMoverMapa,
            ),
            children: <Widget>[
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.project_x',
              ),
              const SimpleAttributionWidget(
                source: Text('OpenStreetMap contributors'),
              ),
            ],
          ),
          IgnorePointer(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Icon(Icons.location_pin, size: 44, color: cores.primary),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Material(
                  color: cores.surface,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: cores.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _CartaoConfirmacao(
              aMover: _aMover,
              local: _localAtual,
              aoConfirmar: _confirmar,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoConfirmacao extends StatelessWidget {
  const _CartaoConfirmacao({
    required this.aMover,
    required this.local,
    required this.aoConfirmar,
  });

  final bool aMover;
  final Local? local;
  final VoidCallback aoConfirmar;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TextTheme textos = Theme.of(context).textTheme;
    final Local? localAtual = local;

    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (aMover || localAtual == null)
            Row(
              children: <Widget>[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cores.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'A obter morada…',
                  style: textos.bodyMedium?.copyWith(
                    color: cores.onSurfaceVariant,
                  ),
                ),
              ],
            )
          else ...<Widget>[
            Text(localAtual.nome, style: textos.titleMedium),
            if (localAtual.descricao != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                localAtual.descricao!,
                style: textos.bodySmall?.copyWith(
                  color: cores.onSurfaceVariant,
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          BotaoPrincipal(
            texto: 'Confirmar',
            aoPremir: (!aMover && localAtual != null) ? aoConfirmar : null,
          ),
        ],
      ),
    );
  }
}
