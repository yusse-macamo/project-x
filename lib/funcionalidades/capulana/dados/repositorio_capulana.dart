import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/nucleo/constantes/padrao_capulana.dart';

class CapulanaEscolhida {
  const CapulanaEscolhida({required this.padrao, this.caminhoFoto});

  final PadraoCapulana padrao;
  final String? caminhoFoto;
}

abstract interface class RepositorioCapulana {
  Future<CapulanaEscolhida> obter();
  Future<void> guardar(CapulanaEscolhida capulana);
}

class RepositorioCapulanaSimulado implements RepositorioCapulana {
  CapulanaEscolhida _atual = const CapulanaEscolhida(
    padrao: PadraoCapulana.folhasDoMar,
  );

  @override
  Future<CapulanaEscolhida> obter() async => _atual;

  @override
  Future<void> guardar(CapulanaEscolhida capulana) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _atual = capulana;
  }
}

/// Sempre simulado: o servidor ainda não tem onde guardar a capulana.
final Provider<RepositorioCapulana> repositorioCapulanaProvider =
    Provider<RepositorioCapulana>((Ref ref) => RepositorioCapulanaSimulado());
