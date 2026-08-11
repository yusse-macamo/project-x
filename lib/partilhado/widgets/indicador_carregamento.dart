import 'package:flutter/material.dart';

class IndicadorCarregamento extends StatelessWidget {
  const IndicadorCarregamento({this.mensagem, super.key});

  final String? mensagem;

  @override
  Widget build(BuildContext context) {
    final String? texto = mensagem;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (texto != null) ...[
            const SizedBox(height: 12),
            Text(
              texto,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
