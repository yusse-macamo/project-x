import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';

LatLng paraLatLng(Coordenada coordenada) =>
    LatLng(coordenada.latitude, coordenada.longitude);

class MapaRota extends StatelessWidget {
  const MapaRota({
    required this.centro,
    this.zoom = 15,
    this.marcadores = const <Marker>[],
    this.linhas = const <Polyline<Object>>[],
    this.controlador,
    this.aoMover,
    this.alinhamentoCreditos = Alignment.bottomRight,
    this.margemCreditos = const EdgeInsets.all(4),
    super.key,
  });

  final Coordenada centro;
  final double zoom;
  final List<Marker> marcadores;
  final List<Polyline<Object>> linhas;
  final MapController? controlador;
  final void Function(MapCamera camera, bool comGesto)? aoMover;

  /// Onde fica o crédito do OpenStreetMap (obrigatório pela licença dos
  /// mapas): ecrãs com uma folha em baixo põem-no em cima.
  final Alignment alinhamentoCreditos;
  final EdgeInsets margemCreditos;

  @override
  Widget build(BuildContext context) {
    final bool escuro = Theme.of(context).brightness == Brightness.dark;
    return FlutterMap(
      mapController: controlador,
      options: MapOptions(
        initialCenter: paraLatLng(centro),
        initialZoom: zoom,
        onPositionChanged: aoMover,
      ),
      children: <Widget>[
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            escuro ? CoresApp.marinhoClaro : CoresApp.areia,
            BlendMode.multiply,
          ),
          child: TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.project_x',
          ),
        ),
        if (linhas.isNotEmpty) PolylineLayer<Object>(polylines: linhas),
        if (marcadores.isNotEmpty) MarkerLayer(markers: marcadores),
        Align(
          alignment: alinhamentoCreditos,
          child: Padding(
            padding: margemCreditos,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: CoresApp.creme.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  '© OpenStreetMap',
                  style: TextStyle(color: CoresApp.marinho, fontSize: 10),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
