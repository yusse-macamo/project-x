import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class SelectorImagem {
  Future<String?> tirarFotografia();
  Future<String?> escolherDaGaleria();
}

class SelectorImagemSimulado implements SelectorImagem {
  static const Duration _atraso = Duration(milliseconds: 500);

  @override
  Future<String?> tirarFotografia() async {
    await Future<void>.delayed(_atraso);
    return 'camara-${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  @override
  Future<String?> escolherDaGaleria() async {
    await Future<void>.delayed(_atraso);
    return 'galeria-${DateTime.now().millisecondsSinceEpoch}.jpg';
  }
}

final Provider<SelectorImagem> selectorImagemProvider = Provider<SelectorImagem>(
  (Ref ref) => SelectorImagemSimulado(),
);
