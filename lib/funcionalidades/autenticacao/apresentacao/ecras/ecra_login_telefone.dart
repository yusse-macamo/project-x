import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/nucleo/utilitarios/validadores.dart';
import 'package:project_x/partilhado/widgets/botao_principal.dart';
import 'package:project_x/partilhado/widgets/campo_texto.dart';

class EcraLoginTelefone extends ConsumerStatefulWidget {
  const EcraLoginTelefone({super.key});

  @override
  ConsumerState<EcraLoginTelefone> createState() => _EcraLoginTelefoneState();
}

class _EcraLoginTelefoneState extends ConsumerState<EcraLoginTelefone> {
  final TextEditingController _controlador = TextEditingController();
  bool _valido = false;

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
        .pedirCodigo(_controlador.text);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<EstadoAutenticacao>(controladorAutenticacaoProvider, (
      EstadoAutenticacao? anterior,
      EstadoAutenticacao atual,
    ) {
      if (atual.erro != null && atual.erro != anterior?.erro) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(atual.erro!)),
        );
      }
    });

    final bool aProcessar = ref.watch(
      controladorAutenticacaoProvider.select(
        (EstadoAutenticacao estado) => estado.aProcessar,
      ),
    );
    final TextTheme textos = Theme.of(context).textTheme;
    final ColorScheme cores = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'O seu número',
                style: textos.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enviamos um código por SMS para confirmar que o número é '
                'seu.',
                style: textos.bodyMedium?.copyWith(
                  color: cores.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              CampoTexto(
                rotulo: 'Número de telemóvel',
                controlador: _controlador,
                dica: '84 123 4567',
                prefixo: '${Validadores.indicativo} ',
                teclado: TextInputType.number,
                formatadores: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                aoMudar: _aoMudarTelefone,
              ),
              const SizedBox(height: 32),
              Text(
                'Ao continuar, aceita os Termos e a Política de Privacidade.',
                textAlign: TextAlign.center,
                style: textos.bodySmall?.copyWith(
                  color: cores.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              BotaoPrincipal(
                texto: 'Continuar',
                aoPremir: _valido ? _continuar : null,
                aCarregar: aProcessar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
