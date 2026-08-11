import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/funcionalidades/autenticacao/apresentacao/widgets/campo_codigo.dart';
import 'package:project_x/nucleo/utilitarios/validadores.dart';
import 'package:project_x/partilhado/widgets/indicador_carregamento.dart';

class EcraVerificacaoOtp extends ConsumerStatefulWidget {
  const EcraVerificacaoOtp({super.key});

  @override
  ConsumerState<EcraVerificacaoOtp> createState() =>
      _EcraVerificacaoOtpState();
}

class _EcraVerificacaoOtpState extends ConsumerState<EcraVerificacaoOtp> {
  static const int _duracaoContador = 60;

  Timer? _temporizador;
  int _segundosRestantes = _duracaoContador;
  int _tentativa = 0;

  @override
  void initState() {
    super.initState();
    _iniciarContador();
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  void _iniciarContador() {
    _segundosRestantes = _duracaoContador;
    _temporizador?.cancel();
    _temporizador = Timer.periodic(const Duration(seconds: 1), (
      Timer temporizador,
    ) {
      if (_segundosRestantes <= 1) {
        temporizador.cancel();
        setState(() => _segundosRestantes = 0);
        return;
      }
      setState(() => _segundosRestantes--);
    });
  }

  void _confirmar(String codigo) {
    ref.read(controladorAutenticacaoProvider.notifier).confirmarCodigo(codigo);
  }

  void _reenviar() {
    ref.read(controladorAutenticacaoProvider.notifier).reenviarCodigo();
    setState(() => _tentativa++);
    _iniciarContador();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<EstadoAutenticacao>(controladorAutenticacaoProvider, (
      EstadoAutenticacao? anterior,
      EstadoAutenticacao atual,
    ) {
      if (atual.erro != null && atual.erro != anterior?.erro) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(atual.erro!)));
        setState(() => _tentativa++);
      }
    });

    final EstadoAutenticacao estado = ref.watch(controladorAutenticacaoProvider);
    final bool aProcessar = estado.aProcessar;
    final String telefoneFormatado = Validadores.formatarTelefone(
      estado.telefone ?? '',
    );
    final TextTheme textos = Theme.of(context).textTheme;
    final ColorScheme cores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              ref.read(controladorAutenticacaoProvider.notifier).voltarAoNumero(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Introduza o código',
                style: textos.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enviámos um código de 6 dígitos para $telefoneFormatado.',
                style: textos.bodyMedium?.copyWith(
                  color: cores.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              CampoCodigo(
                key: ValueKey<int>(_tentativa),
                ativo: !aProcessar,
                aoCompletar: _confirmar,
              ),
              const SizedBox(height: 24),
              if (aProcessar)
                const IndicadorCarregamento()
              else
                Center(
                  child: _segundosRestantes > 0
                      ? Text(
                          'Reenviar código em $_segundosRestantes s',
                          style: textos.bodyMedium?.copyWith(
                            color: cores.onSurfaceVariant,
                          ),
                        )
                      : TextButton(
                          onPressed: _reenviar,
                          child: const Text('Reenviar código'),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
