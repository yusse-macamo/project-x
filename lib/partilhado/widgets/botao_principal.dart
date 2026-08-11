import 'package:flutter/material.dart';

class BotaoPrincipal extends StatelessWidget {
  const BotaoPrincipal({
    required this.texto,
    this.aoPremir,
    this.aCarregar = false,
    this.icone,
    super.key,
  });

  final String texto;
  final VoidCallback? aoPremir;
  final bool aCarregar;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    return IgnorePointer(
      ignoring: aCarregar,
      child: FilledButton(
        onPressed: aoPremir,
        child: _ConteudoBotao(
          texto: texto,
          aCarregar: aCarregar,
          icone: icone,
          corIndicador: cores.onPrimary,
        ),
      ),
    );
  }
}

class BotaoSecundario extends StatelessWidget {
  const BotaoSecundario({
    required this.texto,
    this.aoPremir,
    this.aCarregar = false,
    this.icone,
    super.key,
  });

  final String texto;
  final VoidCallback? aoPremir;
  final bool aCarregar;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    return IgnorePointer(
      ignoring: aCarregar,
      child: OutlinedButton(
        onPressed: aoPremir,
        child: _ConteudoBotao(
          texto: texto,
          aCarregar: aCarregar,
          icone: icone,
          corIndicador: cores.primary,
        ),
      ),
    );
  }
}

class _ConteudoBotao extends StatelessWidget {
  const _ConteudoBotao({
    required this.texto,
    required this.aCarregar,
    required this.icone,
    required this.corIndicador,
  });

  final String texto;
  final bool aCarregar;
  final IconData? icone;
  final Color corIndicador;

  @override
  Widget build(BuildContext context) {
    if (aCarregar) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: corIndicador,
        ),
      );
    }
    if (icone == null) {
      return Text(texto);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone),
        const SizedBox(width: 8),
        Text(texto),
      ],
    );
  }
}
