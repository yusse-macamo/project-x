import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TipoAplicacao { passageiro, motoqueiro }

final Provider<TipoAplicacao> tipoAplicacaoProvider = Provider<TipoAplicacao>(
  (Ref ref) {
    throw UnimplementedError(
      'tipoAplicacaoProvider tem de ser sobreposto em arrancarApp().',
    );
  },
);
