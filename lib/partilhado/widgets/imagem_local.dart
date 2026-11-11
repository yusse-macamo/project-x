import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Mostra uma fotografia escolhida no dispositivo. No browser o `caminho` é
/// um endereço `blob:` (o `image_picker` não dá acesso ao disco), por isso
/// lê-se pela rede em vez de por ficheiro.
class ImagemLocal extends StatelessWidget {
  const ImagemLocal({
    required this.caminho,
    required this.alternativa,
    this.fit = BoxFit.cover,
    this.largura,
    this.altura,
    this.larguraCache,
    super.key,
  });

  final String caminho;
  final Widget alternativa;
  final BoxFit fit;
  final double? largura;
  final double? altura;
  final int? larguraCache;

  @override
  Widget build(BuildContext context) {
    Widget seFalhar(BuildContext _, Object _, StackTrace? _) => alternativa;

    if (kIsWeb) {
      return Image.network(
        caminho,
        fit: fit,
        width: largura,
        height: altura,
        cacheWidth: larguraCache,
        errorBuilder: seFalhar,
      );
    }
    return Image.file(
      File(caminho),
      fit: fit,
      width: largura,
      height: altura,
      cacheWidth: larguraCache,
      errorBuilder: seFalhar,
    );
  }
}
