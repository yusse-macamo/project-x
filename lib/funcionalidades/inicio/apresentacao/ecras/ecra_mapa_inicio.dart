import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/funcionalidades/autenticacao/dominio/utilizador.dart';
import 'package:project_x/partilhado/widgets/estado_vazio.dart';

class EcraMapaInicio extends ConsumerWidget {
  const EcraMapaInicio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Utilizador? utilizador = ref.watch(
      controladorAutenticacaoProvider.select(
        (EstadoAutenticacao estado) => estado.utilizador,
      ),
    );
    final String primeiroNome = utilizador?.primeiroNome ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, $primeiroNome'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref
                .read(controladorAutenticacaoProvider.notifier)
                .terminarSessao(),
          ),
        ],
      ),
      body: const EstadoVazio(
        icone: Icons.map_outlined,
        titulo: 'O mapa chega no sprint 3',
        descricao:
            'Vai poder pedir uma mota daqui assim que ligarmos a '
            'localização e os motoqueiros.',
      ),
    );
  }
}
