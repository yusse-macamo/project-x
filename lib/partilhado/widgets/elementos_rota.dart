import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/nucleo/tema/tema_app.dart';

void mostrarAviso(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
}

/// Sem pacote para abrir o telefone ou o WhatsApp, copia e diz o que fazer.
Future<void> copiarEAvisar(
  BuildContext context,
  String texto,
  String aviso,
) async {
  await Clipboard.setData(ClipboardData(text: texto));
  if (context.mounted) {
    mostrarAviso(context, aviso);
  }
}

class LogoRota extends StatelessWidget {
  const LogoRota({this.invertido = false, this.tamanhoLetra = 22, super.key});

  /// Amarelo com letras azuis, para fundos escuros.
  final bool invertido;
  final double tamanhoLetra;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.03,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: tamanhoLetra * 0.65,
          vertical: tamanhoLetra * 0.35,
        ),
        decoration: BoxDecoration(
          color: invertido ? CoresApp.destaque : CoresApp.marinho,
          borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
        ),
        child: Text(
          'ROTA',
          style: TextStyle(
            color: invertido ? CoresApp.marinho : CoresApp.destaque,
            fontSize: tamanhoLetra,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class BotaoRedondo extends StatelessWidget {
  const BotaoRedondo({
    required this.icone,
    required this.aoTocar,
    this.dica,
    super.key,
  });

  final IconData icone;
  final VoidCallback aoTocar;
  final String? dica;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    return Material(
      color: cores.surfaceContainerHighest,
      shape: const CircleBorder(),
      elevation: 1,
      child: IconButton(
        tooltip: dica,
        icon: Icon(icone, color: cores.onSurface),
        onPressed: aoTocar,
      ),
    );
  }
}

class ChipOpcao extends StatelessWidget {
  const ChipOpcao({
    required this.texto,
    required this.selecionado,
    required this.aoTocar,
    this.corSelecionado,
    this.corTextoSelecionado,
    this.icone,
    super.key,
  });

  final String texto;
  final bool selecionado;
  final VoidCallback? aoTocar;
  final Color? corSelecionado;
  final Color? corTextoSelecionado;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final Color fundoAtivo = corSelecionado ?? cores.onSurface;
    final Color textoAtivo = corTextoSelecionado ?? cores.surface;
    final Color corTexto = selecionado
        ? textoAtivo
        : (aoTocar == null ? cores.onSurfaceVariant : cores.onSurface);
    return Material(
      color: selecionado ? fundoAtivo : cores.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
        side: BorderSide(
          color: selecionado ? fundoAtivo : cores.outline,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icone != null) ...<Widget>[
                Icon(icone, size: 18, color: corTexto),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  texto,
                  style: TextStyle(
                    color: corTexto,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SeloAmarelo extends StatelessWidget {
  const SeloAmarelo({
    required this.texto,
    this.tamanhoLetra = 15,
    this.inclinado = true,
    super.key,
  });

  final String texto;
  final double tamanhoLetra;
  final bool inclinado;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: inclinado ? -0.03 : 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: CoresApp.destaque,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: CoresApp.marinho,
            fontSize: tamanhoLetra,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class OndaAudio extends StatelessWidget {
  const OndaAudio({
    required this.corAtiva,
    this.corInativa,
    this.progresso = 1,
    this.barras = 24,
    this.altura = 32,
    super.key,
  });

  final Color corAtiva;
  final Color? corInativa;
  final double progresso;
  final int barras;
  final double altura;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < barras; i++)
          Container(
            width: 3,
            height: altura * (0.3 + 0.7 * sin(i * 1.7).abs()),
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: i / barras <= progresso
                  ? corAtiva
                  : (corInativa ?? corAtiva.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}

class AvatarIniciais extends StatelessWidget {
  const AvatarIniciais({
    required this.iniciais,
    required this.capulana,
    this.tamanho = 72,
    super.key,
  });

  final String iniciais;
  final Widget capulana;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: tamanho,
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            capulana,
            Center(
              child: Container(
                width: tamanho * 0.66,
                height: tamanho * 0.66,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: CoresApp.creme,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  iniciais,
                  style: TextStyle(
                    color: CoresApp.marinho,
                    fontSize: tamanho * 0.22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aviso visível enquanto os dados da corrida forem simulados: ninguém pode
/// confundir um motoqueiro de teste com um real.
class FaixaModoTeste extends StatelessWidget {
  const FaixaModoTeste({required this.mensagem, super.key});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CoresApp.destaqueClara,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.science_outlined,
            size: 18,
            color: CoresApp.destaqueEscura,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensagem,
              style: const TextStyle(
                color: CoresApp.marinho,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
