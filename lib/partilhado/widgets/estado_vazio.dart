import 'package:flutter/material.dart';
import 'package:project_x/partilhado/widgets/botao_principal.dart';

class EstadoVazio extends StatelessWidget {
  const EstadoVazio({
    required this.icone,
    required this.titulo,
    required this.descricao,
    this.textoAcao,
    this.aoTocarAcao,
    super.key,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final String? textoAcao;
  final VoidCallback? aoTocarAcao;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TextTheme textos = Theme.of(context).textTheme;
    final String? acao = textoAcao;
    final VoidCallback? aoTocar = aoTocarAcao;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 56, color: cores.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: textos.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              descricao,
              style: textos.bodyMedium?.copyWith(color: cores.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (acao != null && aoTocar != null) ...[
              const SizedBox(height: 32),
              BotaoPrincipal(texto: acao, aoPremir: aoTocar),
            ],
          ],
        ),
      ),
    );
  }
}
