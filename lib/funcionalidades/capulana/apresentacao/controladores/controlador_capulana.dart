import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/capulana/dados/repositorio_capulana.dart';
import 'package:project_x/nucleo/constantes/padrao_capulana.dart';

class ControladorCapulana extends Notifier<CapulanaEscolhida> {
  @override
  CapulanaEscolhida build() {
    return const CapulanaEscolhida(padrao: PadraoCapulana.folhasDoMar);
  }

  Future<void> guardar(CapulanaEscolhida capulana) async {
    await ref.read(repositorioCapulanaProvider).guardar(capulana);
    state = capulana;
  }
}

final NotifierProvider<ControladorCapulana, CapulanaEscolhida>
controladorCapulanaProvider =
    NotifierProvider<ControladorCapulana, CapulanaEscolhida>(
      ControladorCapulana.new,
    );
