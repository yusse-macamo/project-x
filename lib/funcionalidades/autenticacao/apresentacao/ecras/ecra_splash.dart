import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';

class EcraSplash extends ConsumerStatefulWidget {
  const EcraSplash({super.key});

  @override
  ConsumerState<EcraSplash> createState() => _EcraSplashState();
}

class _EcraSplashState extends ConsumerState<EcraSplash> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      ref.read(controladorAutenticacaoProvider.notifier).verificarSessao();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.primariaEscura,
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: CustomPaint(painter: _PintorEstrada())),
          const SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: _ConteudoSplash(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConteudoSplash extends StatelessWidget {
  const _ConteudoSplash();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CoresApp.destaque,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.two_wheeler,
            color: CoresApp.onPrimaria,
            size: 28,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'VilaMova',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: CoresApp.onPrimaria,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Vilankulos · Inhambane',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: CoresApp.onPrimaria.withValues(alpha: 0.78),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              CoresApp.onPrimaria.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}

/// Estrada costeira ao entardecer, a caminho de Vilankulos — cenário do
/// splash desenhado em código, sem imagem, só com cores do [CoresApp].
class _PintorEstrada extends CustomPainter {
  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect area = Offset.zero & size;
    final double horizonte = size.height * 0.42;
    final double centroX = size.width / 2;

    canvas.drawRect(
      area,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[CoresApp.primariaEscura, CoresApp.destaque],
        ).createShader(area),
    );

    canvas.drawRect(
      area,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            CoresApp.destaqueClara.withValues(alpha: 0.5),
            CoresApp.destaqueClara.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(centroX, horizonte),
            radius: size.width * 0.55,
          ),
        ),
    );

    double xEsquerdaEm(double y) {
      final double t = (y - horizonte) / (size.height - horizonte);
      return _lerp(centroX - 10, size.width * -0.1, t);
    }

    double xDireitaEm(double y) {
      final double t = (y - horizonte) / (size.height - horizonte);
      return _lerp(centroX + 10, size.width * 1.1, t);
    }

    final Path estrada = Path()
      ..moveTo(centroX - 10, horizonte)
      ..lineTo(centroX + 10, horizonte)
      ..lineTo(xDireitaEm(size.height), size.height)
      ..lineTo(xEsquerdaEm(size.height), size.height)
      ..close();
    canvas.drawPath(estrada, Paint()..color = CoresApp.bordaEscuro);

    final Paint tinta = Paint()..color = CoresApp.onPrimaria.withValues(alpha: 0.85);
    const int numeroDeTracos = 6;
    for (int i = 0; i < numeroDeTracos; i++) {
      final double t0 = i / numeroDeTracos;
      final double t1 = (i + 0.5) / numeroDeTracos;
      final double y0 = _lerp(horizonte, size.height, t0);
      final double y1 = _lerp(horizonte, size.height, t1);
      final double largura0 = _lerp(1, 7, t0);
      final double largura1 = _lerp(1, 7, t1);
      final Path traco = Path()
        ..moveTo(centroX - largura0 / 2, y0)
        ..lineTo(centroX + largura0 / 2, y0)
        ..lineTo(centroX + largura1 / 2, y1)
        ..lineTo(centroX - largura1 / 2, y1)
        ..close();
      canvas.drawPath(traco, tinta);
    }

    void desenharCoqueiro(double t, bool esquerda) {
      final double y = _lerp(horizonte + 6, size.height - 10, t);
      final double margem = esquerda ? xEsquerdaEm(y) : xDireitaEm(y);
      final double sinal = esquerda ? -1 : 1;
      final double altura = _lerp(20, 84, t);
      final double x = margem - sinal * _lerp(4, 20, t);
      final Offset base = Offset(x, y);
      final Offset copa = Offset(x + sinal * altura * 0.12, y - altura);

      final Paint traco = Paint()
        ..color = CoresApp.fundoEscuro
        ..style = PaintingStyle.stroke
        ..strokeWidth = altura * 0.09
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(
            base.dx + sinal * altura * 0.18,
            base.dy - altura * 0.6,
            copa.dx,
            copa.dy,
          ),
        traco,
      );

      final Paint folha = Paint()
        ..color = CoresApp.fundoEscuro
        ..style = PaintingStyle.stroke
        ..strokeWidth = altura * 0.1
        ..strokeCap = StrokeCap.round;
      for (final double deslocamento in <double>[-0.7, -0.25, 0.25, 0.7]) {
        final Offset ponta = copa +
            Offset(
              sinal * altura * 0.55,
              -altura * 0.18 + deslocamento * altura * 0.4,
            );
        canvas.drawPath(
          Path()
            ..moveTo(copa.dx, copa.dy)
            ..quadraticBezierTo(
              copa.dx + sinal * altura * 0.25,
              copa.dy - altura * 0.18,
              ponta.dx,
              ponta.dy,
            ),
          folha,
        );
      }
    }

    for (final double t in <double>[0.2, 0.55, 0.85]) {
      desenharCoqueiro(t, true);
      desenharCoqueiro(t, false);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
