import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/funcionalidades/autenticacao/apresentacao/widgets/campo_codigo.dart';
import 'package:project_x/funcionalidades/autenticacao/dominio/canal_codigo.dart';
import 'package:project_x/nucleo/tema/tema_app.dart';
import 'package:project_x/nucleo/utilitarios/validadores.dart';
import 'package:project_x/partilhado/widgets/indicador_carregamento.dart';

class EcraVerificacaoOtp extends ConsumerStatefulWidget {
  const EcraVerificacaoOtp({super.key});

  @override
  ConsumerState<EcraVerificacaoOtp> createState() => _EcraVerificacaoOtpState();
}

class _EcraVerificacaoOtpState extends ConsumerState<EcraVerificacaoOtp> {
  static const int _duracaoContador = 60;

  Timer? _temporizador;
  int _segundosRestantes = 0;
  int _tentativa = 0;

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

  Future<void> _enviar(CanalCodigo canal) async {
    await ref
        .read(controladorAutenticacaoProvider.notifier)
        .enviarCodigo(canal);
    if (!mounted || ref.read(controladorAutenticacaoProvider).erro != null) {
      return;
    }
    setState(() {
      _tentativa++;
      _iniciarContador();
    });
  }

  void _confirmar(String codigo) {
    ref.read(controladorAutenticacaoProvider.notifier).confirmarCodigo(codigo);
  }

  void _voltarAoNumero() {
    ref.read(controladorAutenticacaoProvider.notifier).voltarAoNumero();
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
        if (atual.codigoEnviado) {
          setState(() => _tentativa++);
        }
      }
    });

    final EstadoAutenticacao estado = ref.watch(
      controladorAutenticacaoProvider,
    );
    final bool enviado = estado.codigoEnviado;
    final bool podePedir = !estado.aProcessar && _segundosRestantes == 0;
    final String telefoneFormatado =
        '${Validadores.indicativo} '
        '${Validadores.formatarTelefone(estado.telefone ?? '')}';
    final String? codigoDeTeste = ref
        .read(controladorAutenticacaoProvider.notifier)
        .codigoDeTeste;
    final TextTheme textos = Theme.of(context).textTheme;
    final ColorScheme cores = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool saiu, Object? _) {
        if (!saiu) {
          _voltarAoNumero();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Mudar o número',
            onPressed: _voltarAoNumero,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'INTRODUZ O CÓDIGO',
                  style: textos.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  enviado
                      ? 'Enviámos um código de 6 dígitos por '
                            '${estado.canal.nome} para $telefoneFormatado.'
                      : 'Escolhe por onde queres receber o código de 6 '
                            'dígitos para $telefoneFormatado.',
                  style: textos.bodyMedium?.copyWith(
                    color: cores.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _BotaoCanal(
                        canal: CanalCodigo.sms,
                        icone: Icons.sms_outlined,
                        destacado: enviado && estado.canal == CanalCodigo.sms,
                        aEnviar:
                            estado.aProcessar &&
                            !enviado &&
                            estado.canal == CanalCodigo.sms,
                        aoPremir: podePedir
                            ? () => _enviar(CanalCodigo.sms)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BotaoCanal(
                        canal: CanalCodigo.whatsapp,
                        icone: Icons.chat_outlined,
                        destacado:
                            enviado && estado.canal == CanalCodigo.whatsapp,
                        aEnviar:
                            estado.aProcessar &&
                            !enviado &&
                            estado.canal == CanalCodigo.whatsapp,
                        aoPremir: podePedir
                            ? () => _enviar(CanalCodigo.whatsapp)
                            : null,
                      ),
                    ),
                  ],
                ),
                if (enviado) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    _segundosRestantes > 0
                        ? 'Podes pedir outro código em $_segundosRestantes s.'
                        : 'Não recebeste? Toca em SMS ou WhatsApp para '
                              'pedir outro.',
                    textAlign: TextAlign.center,
                    style: textos.bodySmall?.copyWith(
                      color: cores.onSurfaceVariant,
                    ),
                  ),
                ],
                if (codigoDeTeste != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: cores.secondaryContainer,
                      borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
                    ),
                    child: Text(
                      'Modo de teste: nenhuma mensagem é enviada. '
                      'O código é $codigoDeTeste.',
                      style: textos.bodySmall?.copyWith(
                        color: cores.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                CampoCodigo(
                  key: ValueKey<int>(_tentativa),
                  ativo: enviado && !estado.aProcessar,
                  aoCompletar: _confirmar,
                ),
                if (enviado && estado.aProcessar) ...<Widget>[
                  const SizedBox(height: 24),
                  const IndicadorCarregamento(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BotaoCanal extends StatelessWidget {
  const _BotaoCanal({
    required this.canal,
    required this.icone,
    required this.destacado,
    required this.aEnviar,
    required this.aoPremir,
  });

  final CanalCodigo canal;
  final IconData icone;
  final bool destacado;
  final bool aEnviar;
  final VoidCallback? aoPremir;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final Widget conteudo = aEnviar
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(destacado ? Icons.check_circle : icone, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  canal.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
    final ButtonStyle estilo = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
      ),
      backgroundColor: destacado ? cores.primaryContainer : null,
      foregroundColor: destacado ? cores.onPrimaryContainer : null,
      side: BorderSide(
        color: destacado ? cores.primary : cores.outline,
        width: destacado ? 2 : 1,
      ),
    );
    return OutlinedButton(onPressed: aoPremir, style: estilo, child: conteudo);
  }
}
