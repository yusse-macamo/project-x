import 'package:flutter/material.dart';

import 'package:project_x/nucleo/tema/cores_app.dart';

class IndicadorPasso extends StatelessWidget {
  const IndicadorPasso({required this.passo, required this.total, super.key});

  final int passo;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Passo $passo de $total',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: cores.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: passo / total,
            minHeight: 4,
            backgroundColor: cores.surfaceContainerHighest,
            valueColor: const AlwaysStoppedAnimation<Color>(CoresApp.primaria),
          ),
        ),
      ],
    );
  }
}
