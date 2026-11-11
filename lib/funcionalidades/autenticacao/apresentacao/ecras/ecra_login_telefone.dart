import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/nucleo/constantes/contactos_app.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/nucleo/tema/tema_app.dart';
import 'package:project_x/nucleo/utilitarios/validadores.dart';
import 'package:project_x/partilhado/widgets/botao_principal.dart';
import 'package:project_x/partilhado/widgets/elementos_rota.dart';
import 'package:project_x/partilhado/widgets/faixa_capulana.dart';

class _TextosEntrada {
  const _TextosEntrada({
    required this.titulo,
    required this.descricao,
    required this.rotuloTelefone,
    required this.botao,
    required this.termos,
    required this.semDados,
  });

  final String titulo;
  final String descricao;
  final String rotuloTelefone;
  final String botao;
  final String termos;
  final String Function(String? linha) semDados;
}

const _TextosEntrada _portugues = _TextosEntrada(
  titulo: 'TÁS ONDE? NÓS TE LEVAMOS.',
  descricao:
      'Mota, txopela ou táxi em Vilankulo. Diz a referência do lugar e vês o '
      'preço antes de subir.',
  rotuloTelefone: 'Número de telemóvel',
  botao: 'Entrar',
  termos: 'Ao entrar, aceitas os Termos e a Política de Privacidade.',
  semDados: _semDadosPortugues,
);

const _TextosEntrada _ingles = _TextosEntrada(
  titulo: 'WHERE ARE YOU? WE’LL TAKE YOU.',
  descricao:
      'Motorbike, tuk-tuk or taxi in Vilankulo. Name a nearby landmark and '
      'see the price before you get on.',
  rotuloTelefone: 'Mobile number',
  botao: 'Sign in',
  termos: 'By signing in, you accept the Terms and Privacy Policy.',
  semDados: _semDadosIngles,
);

String _semDadosPortugues(String? linha) => linha == null
    ? 'Sem dados? Em breve vais poder pedir por chamada ou SMS.'
    : 'Sem dados? Liga $linha ou manda SMS com o teu destino.';

String _semDadosIngles(String? linha) => linha == null
    ? 'No data? Soon you’ll be able to request by call or SMS.'
    : 'No data? Call $linha or text your destination.';

class EcraLoginTelefone extends ConsumerStatefulWidget {
  const EcraLoginTelefone({super.key});

  @override
  ConsumerState<EcraLoginTelefone> createState() => _EcraLoginTelefoneState();
}

class _EcraLoginTelefoneState extends ConsumerState<EcraLoginTelefone> {
  final TextEditingController _controlador = TextEditingController();
  bool _valido = false;
  bool _emIngles = false;
  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _aoMudarTelefone(String valor) {
    setState(() {
      _valido = Validadores.telefoneValido(valor);
    });
  }

  void _continuar() {
    ref
        .read(controladorAutenticacaoProvider.notifier)
        .continuarParaCodigo(_controlador.text);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<EstadoAutenticacao>(controladorAutenticacaoProvider, (
      EstadoAutenticacao? anterior,
      EstadoAutenticacao atual,
    ) {
      if (atual.erro != null && atual.erro != anterior?.erro) {
        mostrarAviso(context, atual.erro!);
      }
    });

    final bool aProcessar = ref.watch(
      controladorAutenticacaoProvider.select(
        (EstadoAutenticacao estado) => estado.aProcessar,
      ),
    );
    final TextTheme textos = Theme.of(context).textTheme;
    final ColorScheme cores = Theme.of(context).colorScheme;
    final _TextosEntrada texto = _emIngles ? _ingles : _portugues;
    final double alturaCena = MediaQuery.sizeOf(context).height * 0.34;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: alturaCena,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  CustomPaint(painter: _PintorPraia()),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const LogoRota(tamanhoLetra: 24),
                          _SeletorIdioma(
                            emIngles: _emIngles,
                            aoMudar: (bool valor) =>
                                setState(() => _emIngles = valor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const FaixaCapulana(texto: 'Quem tem boca vai a Roma'),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(texto.titulo, style: textos.headlineMedium),
                  const SizedBox(height: 12),
                  Text(
                    texto.descricao,
                    style: textos.bodyLarge?.copyWith(
                      color: cores.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(texto.rotuloTelefone, style: textos.labelLarge),
                  const SizedBox(height: 8),
                  _CampoTelefone(
                    controlador: _controlador,
                    aoMudar: _aoMudarTelefone,
                  ),
                  const SizedBox(height: 12),
                  BotaoPrincipal(
                    texto: texto.botao,
                    aoPremir: _valido ? _continuar : null,
                    aCarregar: aProcessar,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    texto.termos,
                    textAlign: TextAlign.center,
                    style: textos.bodySmall?.copyWith(
                      color: cores.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
                      border: Border.all(color: cores.outline),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.wifi, color: CoresApp.terracota),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            texto.semDados(ContactosApp.linhaPedidos),
                            style: textos.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeletorIdioma extends StatelessWidget {
  const _SeletorIdioma({required this.emIngles, required this.aoMudar});

  final bool emIngles;
  final ValueChanged<bool> aoMudar;

  Widget _opcao(String texto, bool ativa, VoidCallback aoTocar) {
    return GestureDetector(
      onTap: aoTocar,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: ativa ? CoresApp.marinho : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: ativa ? CoresApp.creme : CoresApp.marinho,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CoresApp.creme,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _opcao('PT', !emIngles, () => aoMudar(false)),
          _opcao('EN', emIngles, () => aoMudar(true)),
        ],
      ),
    );
  }
}

class _CampoTelefone extends StatelessWidget {
  const _CampoTelefone({required this.controlador, required this.aoMudar});

  final TextEditingController controlador;
  final ValueChanged<String> aoMudar;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cores.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
        border: Border.all(color: cores.onSurface, width: 1.5),
      ),
      child: Row(
        children: <Widget>[
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            color: CoresApp.destaque,
            child: Text(
              Validadores.indicativo,
              style: const TextStyle(
                color: CoresApp.marinho,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controlador,
              onChanged: aoMudar,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              decoration: const InputDecoration(
                hintText: '84 123 4567',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cena de praia desenhada em código, enquanto não houver fotografia própria.
class _PintorPraia extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double horizonte = size.height * 0.16;
    final double linhaAreia = size.height * 0.78;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, horizonte),
      Paint()..color = CoresApp.ceu,
    );
    final Rect mar = Rect.fromLTRB(0, horizonte, size.width, linhaAreia);
    canvas.drawRect(
      mar,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[CoresApp.marProfundo, CoresApp.mar],
        ).createShader(mar),
    );
    canvas.drawRect(
      Rect.fromLTRB(0, linhaAreia, size.width, size.height),
      Paint()..color = CoresApp.areia,
    );

    final Offset barco = Offset(size.width * 0.56, size.height * 0.52);
    canvas.drawLine(
      barco,
      barco - Offset(0, size.height * 0.36),
      Paint()
        ..color = CoresApp.madeira
        ..strokeWidth = 3,
    );
    canvas.drawPath(
      Path()
        ..moveTo(barco.dx + 3, barco.dy - size.height * 0.34)
        ..lineTo(barco.dx + 44, barco.dy - 8)
        ..lineTo(barco.dx + 3, barco.dy - 8)
        ..close(),
      Paint()..color = CoresApp.creme,
    );
    canvas.drawPath(
      Path()
        ..moveTo(barco.dx - 48, barco.dy)
        ..lineTo(barco.dx + 54, barco.dy)
        ..lineTo(barco.dx + 36, barco.dy + 18)
        ..lineTo(barco.dx - 34, barco.dy + 18)
        ..close(),
      Paint()..color = CoresApp.capulanaVermelho,
    );
    canvas.drawRect(
      Rect.fromLTWH(barco.dx - 44, barco.dy + 3, 94, 5),
      Paint()..color = CoresApp.destaque,
    );

    final Paint poste = Paint()..color = CoresApp.madeira;
    for (final double x in <double>[0.02, 0.09, 0.16, 0.86, 0.93]) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * x,
          size.height * 0.34,
          size.width * 0.04,
          size.height * 0.66,
        ),
        poste,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.48, size.width * 0.22, 8),
      poste,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.84,
        size.height * 0.48,
        size.width * 0.16,
        8,
      ),
      poste,
    );
  }

  @override
  bool shouldRepaint(_PintorPraia anterior) => false;
}
