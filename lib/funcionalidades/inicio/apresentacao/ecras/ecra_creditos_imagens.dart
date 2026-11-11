import 'package:flutter/material.dart';

import 'package:project_x/nucleo/constantes/creditos_imagens.dart';

class EcraCreditosImagens extends StatelessWidget {
  const EcraCreditosImagens({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textos = Theme.of(context).textTheme;
    final ColorScheme cores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Créditos das imagens')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            for (final CreditoImagem credito in creditosImagens) ...<Widget>[
              Text(
                credito.titulo,
                style: textos.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text('${credito.autor} · ${credito.licenca}'),
              SelectableText(
                credito.origem,
                style: textos.bodySmall?.copyWith(
                  color: cores.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              textoLicencaCcBySa,
              style: textos.bodySmall?.copyWith(color: cores.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
