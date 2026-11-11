import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:project_x/funcionalidades/inicio/apresentacao/widgets/aba_paragens.dart';
import 'package:project_x/rotas/rotas_app.dart';

class EcraParagens extends StatelessWidget {
  const EcraParagens({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: AbaParagens(aoGravar: () => context.push(Rotas.gravarParagem)),
      ),
    );
  }
}
