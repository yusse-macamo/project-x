import 'dart:math';

import 'package:flutter/material.dart';

import 'package:project_x/nucleo/constantes/padrao_capulana.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/partilhado/widgets/imagem_local.dart';

class FundoCapulana extends StatelessWidget {
  const FundoCapulana({required this.padrao, this.caminhoFoto, super.key});

  final PadraoCapulana padrao;
  final String? caminhoFoto;

  @override
  Widget build(BuildContext context) {
    final Widget pintura = RepaintBoundary(
      child: CustomPaint(painter: _PintorCapulana(padrao), size: Size.infinite),
    );
    final String? foto = caminhoFoto;
    if (foto == null) {
      return pintura;
    }
    return ImagemLocal(
      caminho: foto,
      largura: double.infinity,
      altura: double.infinity,
      alternativa: pintura,
    );
  }
}

class _PintorCapulana extends CustomPainter {
  const _PintorCapulana(this.padrao);

  final PadraoCapulana padrao;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    // Em miniaturas e faixas, encolhe o padrão para continuar reconhecível.
    final double escala = (size.shortestSide / 150).clamp(0.3, 1.0);
    canvas.scale(escala);
    final Size area = size / escala;
    switch (padrao) {
      case PadraoCapulana.folhasDoMar:
        _pintarFolhas(canvas, area);
      case PadraoCapulana.rodasAzuis:
        _pintarRodas(canvas, area);
      case PadraoCapulana.cesto:
        _pintarCesto(canvas, area);
      case PadraoCapulana.sol:
        _pintarSol(canvas, area);
      case PadraoCapulana.flores:
        _pintarFlores(canvas, area);
    }
    canvas.restore();
  }

  void _anelDePontos(
    Canvas canvas,
    Offset centro,
    double raio,
    int quantidade,
    double raioPonto,
    Color cor,
  ) {
    final Paint tinta = Paint()..color = cor;
    for (int i = 0; i < quantidade; i++) {
      final double angulo = 2 * pi * i / quantidade;
      canvas.drawCircle(
        centro + Offset(cos(angulo), sin(angulo)) * raio,
        raioPonto,
        tinta,
      );
    }
  }

  void _pintarFolhas(Canvas canvas, Size size) {
    const double lado = 92;
    canvas.drawRect(Offset.zero & size, Paint()..color = CoresApp.marinho);
    final Paint traco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;
    for (int linha = 0; linha * lado < size.height + lado; linha++) {
      for (int coluna = 0; coluna * lado < size.width + lado; coluna++) {
        final Offset centro = Offset(coluna * lado, linha * lado);
        final bool turquesa = (linha + coluna).isEven;
        traco.color = turquesa
            ? CoresApp.capulanaTurquesa
            : CoresApp.capulanaLaranja;
        final double sentido = turquesa ? -1 : 1;
        for (double s = 14; s < 44; s += 9) {
          canvas.drawPath(
            Path()
              ..moveTo(centro.dx - s, centro.dy + 12 * sentido)
              ..lineTo(centro.dx, centro.dy + (12 + s) * sentido)
              ..lineTo(centro.dx + s, centro.dy + 12 * sentido),
            traco,
          );
        }
        canvas.drawRect(
          Rect.fromCenter(
            center: centro + const Offset(lado / 2, 0),
            width: 4,
            height: lado * 0.75,
          ),
          Paint()..color = CoresApp.branco,
        );
        final Offset medalhao = centro + const Offset(lado / 2, lado / 2);
        canvas.drawCircle(medalhao, 15, Paint()..color = CoresApp.marinho);
        _anelDePontos(canvas, medalhao, 14, 16, 1.4, CoresApp.branco);
        canvas.drawCircle(
          medalhao,
          9,
          Paint()..color = CoresApp.capulanaTurquesa,
        );
        canvas.drawCircle(medalhao, 4, Paint()..color = CoresApp.marinho);
      }
    }
  }

  void _pintarRodas(Canvas canvas, Size size) {
    const double lado = 84;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = CoresApp.capulanaAmarelo,
    );
    final Paint ponto = Paint()..color = CoresApp.marinho;
    for (double y = 4; y < size.height; y += 8) {
      for (double x = (y ~/ 8).isEven ? 4 : 8; x < size.width; x += 8) {
        canvas.drawCircle(Offset(x, y), 1.1, ponto);
      }
    }
    for (int linha = 0; linha * lado < size.height + lado; linha++) {
      for (int coluna = 0; coluna * lado < size.width + lado; coluna++) {
        final Offset centro = Offset(
          coluna * lado + (linha.isOdd ? lado / 2 : 0),
          linha * lado,
        );
        canvas.drawCircle(centro, 32, Paint()..color = CoresApp.capulanaAzul);
        _anelDePontos(canvas, centro, 25, 20, 1.6, CoresApp.branco);
        canvas.drawCircle(centro, 14, Paint()..color = CoresApp.marinho);
        canvas.drawCircle(centro, 5, Paint()..color = CoresApp.capulanaAmarelo);
      }
    }
  }

  void _pintarCesto(Canvas canvas, Size size) {
    const double alturaFiada = 14;
    const double larguraTijolo = 32;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = CoresApp.capulanaAmarelo,
    );
    final Paint junta = Paint()
      ..color = CoresApp.capulanaLaranja
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final int fiadas = size.height ~/ alturaFiada + 1;
    for (int fiada = 0; fiada < fiadas; fiada++) {
      final double y = fiada * alturaFiada;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), junta);
      final double inicio = fiada.isEven ? 0 : larguraTijolo / 2;
      for (double x = inicio; x < size.width; x += larguraTijolo) {
        canvas.drawLine(Offset(x, y), Offset(x, y + alturaFiada), junta);
      }
    }
    final Paint faixa = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (
      double base = -size.height * 0.2;
      base < size.height * 1.2;
      base += 120
    ) {
      faixa
        ..color = CoresApp.marinho
        ..strokeWidth = 26;
      final Path curva = Path()
        ..moveTo(-20, base + 60)
        ..quadraticBezierTo(
          size.width / 2,
          base - 40,
          size.width + 20,
          base + 50,
        );
      canvas.drawPath(curva, faixa);
      faixa
        ..color = CoresApp.capulanaVermelho
        ..strokeWidth = 14;
      canvas.drawPath(curva, faixa);
    }
  }

  void _pintarSol(Canvas canvas, Size size) {
    const double lado = 112;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = CoresApp.capulanaLaranja,
    );
    for (int linha = 0; linha * lado < size.height + lado; linha++) {
      for (int coluna = 0; coluna * lado < size.width + lado; coluna++) {
        final Offset centro = Offset(
          coluna * lado + (linha.isOdd ? lado / 2 : 0),
          linha * lado,
        );
        canvas.drawCircle(
          centro,
          52,
          Paint()..color = CoresApp.capulanaAmarelo,
        );
        canvas.drawCircle(
          centro,
          52,
          Paint()
            ..color = CoresApp.marinho
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5,
        );
        _anelDePontos(canvas, centro, 42, 28, 1.8, CoresApp.marinho);
        _anelDePontos(canvas, centro, 33, 22, 1.8, CoresApp.marinho);
        canvas.drawCircle(
          centro,
          24,
          Paint()..color = CoresApp.capulanaLaranja,
        );
        _anelDePontos(canvas, centro, 17, 14, 2, CoresApp.marinho);
        canvas.drawCircle(centro, 8, Paint()..color = CoresApp.marinho);
      }
    }
  }

  void _pintarFlores(Canvas canvas, Size size) {
    const double lado = 76;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = CoresApp.capulanaVermelho,
    );
    final Paint folha = Paint()..color = CoresApp.capulanaTurquesa;
    for (int linha = 0; linha * lado < size.height + lado; linha++) {
      for (int coluna = 0; coluna * lado < size.width + lado; coluna++) {
        final Offset centro = Offset(
          coluna * lado + (linha.isOdd ? lado / 2 : 0),
          linha * lado,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: centro + const Offset(30, 28),
            width: 26,
            height: 9,
          ),
          folha,
        );
        final Paint petala = Paint()
          ..color = (linha + coluna).isEven
              ? CoresApp.capulanaLaranja
              : CoresApp.capulanaAmarelo;
        for (int i = 0; i < 6; i++) {
          final double angulo = 2 * pi * i / 6;
          canvas.drawCircle(
            centro + Offset(cos(angulo), sin(angulo)) * 15,
            10,
            petala,
          );
        }
        canvas.drawCircle(centro, 8, Paint()..color = CoresApp.marinho);
        _anelDePontos(canvas, centro, 5, 8, 0.9, CoresApp.capulanaAmarelo);
      }
    }
  }

  @override
  bool shouldRepaint(_PintorCapulana anterior) => anterior.padrao != padrao;
}
