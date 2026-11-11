import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:project_x/funcionalidades/inicio/apresentacao/widgets/aba_viagens.dart';

class EcraViagens extends StatelessWidget {
  const EcraViagens({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(child: AbaViagens(aoPedirViagem: () => context.pop())),
    );
  }
}
