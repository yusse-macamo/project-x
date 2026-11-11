import 'package:flutter/material.dart';

import 'package:project_x/funcionalidades/inicio/apresentacao/widgets/aba_perfil.dart';

class EcraPerfil extends StatelessWidget {
  const EcraPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const SafeArea(child: AbaPerfil()),
    );
  }
}
