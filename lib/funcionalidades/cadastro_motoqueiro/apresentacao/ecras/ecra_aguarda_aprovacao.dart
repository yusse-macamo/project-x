import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/widgets/mudar_tipo.dart';
import 'package:project_x/funcionalidades/autenticacao/dominio/utilizador.dart';
import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/controladores/controlador_cadastro.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/dominio/motoqueiro.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/partilhado/widgets/botao_principal.dart';
import 'package:project_x/partilhado/widgets/dialogo_confirmacao.dart';

const List<String> _meses = <String>[
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

class EcraAguardaAprovacao extends ConsumerStatefulWidget {
  const EcraAguardaAprovacao({super.key});

  @override
  ConsumerState<EcraAguardaAprovacao> createState() =>
      _EcraAguardaAprovacaoState();
}

class _EcraAguardaAprovacaoState extends ConsumerState<EcraAguardaAprovacao> {
  Timer? _temporizador;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) async {
      await ref.read(controladorCadastroProvider.notifier).verificarCadastro();
      if (!mounted) {
        return;
      }
      _iniciarConsultaSeNecessario();
    });
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  void _iniciarConsultaSeNecessario() {
    if (ref.read(controladorCadastroProvider).fase != FaseCadastro.pendente) {
      return;
    }
    _temporizador = Timer.periodic(const Duration(seconds: 15), (
      Timer temporizador,
    ) async {
      await ref.read(controladorCadastroProvider.notifier).verificarCadastro();
      if (!mounted) {
        return;
      }
      if (ref.read(controladorCadastroProvider).fase != FaseCadastro.pendente) {
        temporizador.cancel();
      }
    });
  }

  void _falarComSuporte() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contacto de suporte a chegar em breve.')),
    );
  }

  Future<void> _terminarSessao() async {
    if (!await confirmarTerminarSessao(context) || !mounted) {
      return;
    }
    await ref.read(controladorAutenticacaoProvider.notifier).terminarSessao();
    final String? erro = ref.read(controladorAutenticacaoProvider).erro;
    if (erro == null || !mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
    ref.read(controladorAutenticacaoProvider.notifier).limparErro();
  }

  Widget _botaoTerminarSessao() {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Terminar sessão',
      onPressed: _terminarSessao,
    );
  }

  Widget _botaoMudarParaPassageiro() {
    return IconButton(
      icon: const Icon(Icons.person_pin_circle_outlined),
      tooltip: 'Mudar para passageiro',
      onPressed: () =>
          mudarTipoComConfirmacao(context, ref, TipoUtilizador.passageiro),
    );
  }

  void _comecarATrabalhar() {
    ref.read(controladorCadastroProvider.notifier).confirmarAprovacao();
  }

  void _corrigirDados() {
    ref.read(controladorCadastroProvider.notifier).corrigir();
  }

  String _formatarData(DateTime data) {
    return '${data.day} de ${_meses[data.month - 1]} de ${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    final EstadoCadastro estado = ref.watch(controladorCadastroProvider);
    return switch (estado.fase) {
      FaseCadastro.rejeitado => _construirRejeitado(context, estado.motoqueiro),
      FaseCadastro.aprovado => _construirAprovado(context),
      _ => _construirPendente(context, estado.motoqueiro),
    };
  }

  Widget _construirPendente(BuildContext context, Motoqueiro? motoqueiro) {
    final TextTheme textos = Theme.of(context).textTheme;
    final ColorScheme cores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[_botaoMudarParaPassageiro(), _botaoTerminarSessao()],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.hourglass_top_outlined,
                        size: 88,
                        color: cores.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Em análise',
                        style: textos.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Estamos a confirmar os teus dados e fotografias. Costuma '
                        'demorar até 24 horas.',
                        style: textos.bodyMedium?.copyWith(
                          color: cores.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (motoqueiro?.dataSubmissao != null) ...<Widget>[
                        const SizedBox(height: 24),
                        Text(
                          'Submetido em '
                          '${_formatarData(motoqueiro!.dataSubmissao!)}',
                          style: textos.bodySmall?.copyWith(
                            color: cores.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              BotaoSecundario(
                texto: 'Falar com o suporte',
                aoPremir: _falarComSuporte,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirRejeitado(BuildContext context, Motoqueiro? motoqueiro) {
    final TextTheme textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: CoresApp.erroClaro,
        foregroundColor: CoresApp.erro,
        title: const Text('Cadastro não aprovado'),
        actions: <Widget>[_botaoMudarParaPassageiro(), _botaoTerminarSessao()],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CoresApp.erroClaro,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  motoqueiro?.motivoRejeicao ?? 'Motivo não especificado.',
                  style: textos.bodyMedium?.copyWith(color: CoresApp.erro),
                ),
              ),
              const Spacer(),
              BotaoPrincipal(
                texto: 'Corrigir dados',
                aoPremir: () => _corrigirDados(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirAprovado(BuildContext context) {
    final TextTheme textos = Theme.of(context).textTheme;
    final ColorScheme cores = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.check_circle_outline,
                        size: 88,
                        color: CoresApp.sucesso,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Estás aprovado',
                        style: textos.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Já podes começar a receber pedidos de corrida.',
                        style: textos.bodyMedium?.copyWith(
                          color: cores.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              BotaoPrincipal(
                texto: 'Começar a trabalhar',
                aoPremir: _comecarATrabalhar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
