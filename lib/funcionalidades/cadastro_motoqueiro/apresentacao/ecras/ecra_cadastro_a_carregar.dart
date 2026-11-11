import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/controladores/controlador_cadastro.dart';
import 'package:project_x/partilhado/widgets/estado_vazio.dart';
import 'package:project_x/partilhado/widgets/indicador_carregamento.dart';

/// Motorista que volta à app sem o tipo de veículo escolhido nesta sessão:
/// carrega o cadastro guardado para o `redirect` saber que formulário abrir.
class EcraCadastroACarregar extends ConsumerStatefulWidget {
  const EcraCadastroACarregar({super.key});

  @override
  ConsumerState<EcraCadastroACarregar> createState() =>
      _EcraCadastroACarregarState();
}

class _EcraCadastroACarregarState extends ConsumerState<EcraCadastroACarregar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (ref.read(controladorCadastroProvider).fase == FaseCadastro.inicial) {
        ref.read(controladorCadastroProvider.notifier).verificarCadastro();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? erro = ref.watch(
      controladorCadastroProvider.select((EstadoCadastro e) => e.erro),
    );
    return Scaffold(
      body: SafeArea(
        child: erro == null
            ? const IndicadorCarregamento()
            : EstadoVazio(
                icone: Icons.wifi_off,
                titulo: 'Não foi possível abrir o cadastro',
                descricao: erro,
                textoAcao: 'Tentar de novo',
                aoTocarAcao: () => ref
                    .read(controladorCadastroProvider.notifier)
                    .verificarCadastro(),
              ),
      ),
    );
  }
}
