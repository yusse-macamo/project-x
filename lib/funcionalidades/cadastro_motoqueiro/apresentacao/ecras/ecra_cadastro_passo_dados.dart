import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/controladores/controlador_cadastro.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/widgets/campo_selecao.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/widgets/indicador_passo.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/dominio/motoqueiro.dart';
import 'package:project_x/nucleo/constantes/distritos_inhambane.dart';
import 'package:project_x/nucleo/utilitarios/formatadores.dart';
import 'package:project_x/nucleo/utilitarios/validadores.dart';
import 'package:project_x/partilhado/widgets/botao_principal.dart';
import 'package:project_x/partilhado/widgets/campo_texto.dart';

class EcraCadastroPassoDados extends ConsumerStatefulWidget {
  const EcraCadastroPassoDados({super.key});

  @override
  ConsumerState<EcraCadastroPassoDados> createState() =>
      _EcraCadastroPassoDadosState();
}

class _EcraCadastroPassoDadosState
    extends ConsumerState<EcraCadastroPassoDados> {
  final TextEditingController _nomeCompleto = TextEditingController();
  final TextEditingController _numeroBi = TextEditingController();
  final TextEditingController _bairro = TextEditingController();
  final TextEditingController _contactoEmergencia = TextEditingController();
  String? _distrito;
  bool _valido = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      ref.read(controladorCadastroProvider.notifier).verificarCadastro();
    });
  }

  @override
  void dispose() {
    _nomeCompleto.dispose();
    _numeroBi.dispose();
    _bairro.dispose();
    _contactoEmergencia.dispose();
    super.dispose();
  }

  void _preencherComMotoqueiro(Motoqueiro motoqueiro) {
    if (_nomeCompleto.text != motoqueiro.nomeCompleto) {
      _nomeCompleto.text = motoqueiro.nomeCompleto;
    }
    if (_numeroBi.text != motoqueiro.numeroBi) {
      _numeroBi.text = motoqueiro.numeroBi;
    }
    if (_bairro.text != motoqueiro.bairro) {
      _bairro.text = motoqueiro.bairro;
    }
    if (_contactoEmergencia.text != motoqueiro.contactoEmergencia) {
      _contactoEmergencia.text = motoqueiro.contactoEmergencia;
    }
    setState(() => _distrito = motoqueiro.distrito);
    _recalcularValidade(telefoneProprio: null);
  }

  void _recalcularValidade({required String? telefoneProprio}) {
    final bool valido =
        Validadores.validarNome(_nomeCompleto.text) == null &&
        Validadores.validarNumeroBi(_numeroBi.text) == null &&
        _bairro.text.trim().isNotEmpty &&
        _distrito != null &&
        Validadores.validarTelefone(
              _contactoEmergencia.text,
              telefoneProprio: telefoneProprio,
            ) ==
            null;
    if (valido != _valido) {
      setState(() => _valido = valido);
    }
  }

  void _aoSelecionarDistrito(String distrito, String? telefoneProprio) {
    setState(() => _distrito = distrito);
    _recalcularValidade(telefoneProprio: telefoneProprio);
  }

  void _continuar() {
    ref
        .read(controladorCadastroProvider.notifier)
        .guardarDadosPessoais(
          nomeCompleto: _nomeCompleto.text.trim(),
          numeroBi: _numeroBi.text.trim(),
          bairro: _bairro.text.trim(),
          distrito: _distrito!,
          contactoEmergencia: _contactoEmergencia.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final String? telefoneProprio = ref.watch(
      controladorAutenticacaoProvider.select(
        (EstadoAutenticacao estado) => estado.telefone,
      ),
    );

    ref.listen<EstadoCadastro>(controladorCadastroProvider, (
      EstadoCadastro? anterior,
      EstadoCadastro atual,
    ) {
      if (atual.erro != null && atual.erro != anterior?.erro) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(atual.erro!)));
      }
      final Motoqueiro? motoqueiro = atual.motoqueiro;
      if (motoqueiro != null && motoqueiro != anterior?.motoqueiro) {
        _preencherComMotoqueiro(motoqueiro);
      }
    });

    final bool aProcessar = ref.watch(
      controladorCadastroProvider.select(
        (EstadoCadastro estado) => estado.aProcessar,
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
              const IndicadorPasso(passo: 1, total: 3),
              const SizedBox(height: 32),
              Text(
                'Os seus dados',
                style: textos.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Precisamos de confirmar quem conduz a mota.',
                style: textos.bodyMedium?.copyWith(
                  color: cores.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              CampoTexto(
                rotulo: 'Nome completo',
                controlador: _nomeCompleto,
                dica: 'Nome e apelido',
                validador: Validadores.validarNome,
                formatadores: <TextInputFormatter>[
                  FormatadorCapitalizacaoPalavras(),
                ],
                aoMudar: (String _) =>
                    _recalcularValidade(telefoneProprio: telefoneProprio),
              ),
              const SizedBox(height: 12),
              CampoTexto(
                rotulo: 'Número do BI',
                controlador: _numeroBi,
                dica: '110100195438A',
                validador: Validadores.validarNumeroBi,
                formatadores: <TextInputFormatter>[
                  FormatadorMaiusculas(),
                  LengthLimitingTextInputFormatter(13),
                ],
                aoMudar: (String _) =>
                    _recalcularValidade(telefoneProprio: telefoneProprio),
              ),
              const SizedBox(height: 12),
              CampoTexto(
                rotulo: 'Bairro',
                controlador: _bairro,
                dica: 'Nome do bairro',
                validador: (String? valor) => (valor?.trim().isEmpty ?? true)
                    ? 'Introduza o bairro.'
                    : null,
                aoMudar: (String _) =>
                    _recalcularValidade(telefoneProprio: telefoneProprio),
              ),
              const SizedBox(height: 12),
              CampoSelecao<String>(
                rotulo: 'Distrito',
                opcoes: DistritosInhambane.todos,
                valor: _distrito,
                dica: 'Selecionar distrito',
                aoSelecionar: (String distrito) =>
                    _aoSelecionarDistrito(distrito, telefoneProprio),
              ),
              const SizedBox(height: 12),
              CampoTexto(
                rotulo: 'Contacto de emergência',
                controlador: _contactoEmergencia,
                dica: '84 123 4567',
                prefixo: '${Validadores.indicativo} ',
                teclado: TextInputType.number,
                formatadores: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                validador: (String? valor) => Validadores.validarTelefone(
                  valor,
                  telefoneProprio: telefoneProprio,
                ),
                aoMudar: (String _) =>
                    _recalcularValidade(telefoneProprio: telefoneProprio),
              ),
              const SizedBox(height: 32),
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
