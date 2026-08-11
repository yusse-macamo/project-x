import 'dart:math';

class Coordenada {
  const Coordenada({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  static const double _raioTerraMetros = 6371000;

  double distanciaEmMetrosAte(Coordenada outra) {
    final double lat1 = latitude * (pi / 180);
    final double lat2 = outra.latitude * (pi / 180);
    final double deltaLat = (outra.latitude - latitude) * (pi / 180);
    final double deltaLon = (outra.longitude - longitude) * (pi / 180);

    final double a =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _raioTerraMetros * c;
  }

  @override
  bool operator ==(Object other) {
    return other is Coordenada &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'Coordenada($latitude, $longitude)';
}
