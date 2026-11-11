import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/nucleo/utilitarios/validadores.dart';
import 'package:project_x/partilhado/widgets/botao_principal.dart';
import 'package:project_x/partilhado/widgets/campo_texto.dart';
import 'package:project_x/partilhado/widgets/dialogo_confirmacao.dart';

class EcraCompletarPerfil extends ConsumerStatefulWidget {
  const EcraCompletarPerfil({super.key});

  @override
  ConsumerState<EcraCompletarPerfil> createState() =>
      _EcraCompletarPerfilState();
}

class _EcraCompletarPerfilState extends ConsumerState<EcraCompletarPerfil> {
  final TextEditingController _controlador = TextEditingController();
  bool _valido = false;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _aoMudarNome(String valor) {
    setState(() {
      _valido = Validadores.validarNome(valor) == null;
    });
  }

  void _concluir() {
    ref
        .read(controladorAutenticacaoProvider.notifier)
        .guardarNome(_controlador.text.trim());
  }

  Future<void> _mudarNumero() async {
    final bool confirmado = await mostrarDialogoConfirmacao(
      context,
      titulo: 'Usar outro número?',
      mensagem:
          'Voltas ao ecrã do número. Para continuar com este número, vais '
          'precisar de um novo código.',
      rotuloConfirmar: 'Mudar o número',
    );
    if (!confirmado || !mounted) {
      return;
    }
    await ref.read(controladorAutenticacaoProvider.notifier).terminarSessao();
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
      }
    });

    final bool aProcessar = ref.watch(
      controladorAutenticacaoProvider.select(
        (EstadoAutenticacao estado) => estado.aProcessar,
      ),
    );
    final TextTheme textos = Theme.of(context).textTheme;
    final ColorScheme cores = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool saiu, Object? _) {
        if (!saiu && !aProcessar) {
          _mudarNumero();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Mudar o número',
            onPressed: aProcessar ? null : _mudarNumero,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'COMO TE CHAMAS?',
                  style: textos.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'O motoqueiro vê o teu nome para te encontrar no ponto de '
                  'recolha.',
                  style: textos.bodyMedium?.copyWith(
                    color: cores.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                CampoTexto(
                  rotulo: 'Nome completo',
                  controlador: _controlador,
                  dica: 'Nome e apelido',
                  autoFoco: true,
                  aoMudar: _aoMudarNome,
                ),
                const SizedBox(height: 32),
                BotaoPrincipal(
                  texto: 'Concluir',
                  aoPremir: _valido ? _concluir : null,
                  aCarregar: aProcessar,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
