import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/controladores/controlador_cadastro.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/widgets/campo_selecao.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/widgets/indicador_passo.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/dominio/motoqueiro.dart';
import 'package:project_x/nucleo/constantes/cores_veiculo.dart';
import 'package:project_x/nucleo/utilitarios/formatadores.dart';
import 'package:project_x/nucleo/utilitarios/validadores.dart';
import 'package:project_x/partilhado/widgets/botao_principal.dart';
import 'package:project_x/partilhado/widgets/campo_texto.dart';

class EcraCadastroPassoMota extends ConsumerStatefulWidget {
  const EcraCadastroPassoMota({super.key});

  @override
  ConsumerState<EcraCadastroPassoMota> createState() =>
      _EcraCadastroPassoMotaState();
}

class _EcraCadastroPassoMotaState
    extends ConsumerState<EcraCadastroPassoMota> {
  final TextEditingController _matricula = TextEditingController();
  final TextEditingController _marca = TextEditingController();
  final TextEditingController _modelo = TextEditingController();
  String? _cor;
  int? _anoFabrico;
  bool _valido = false;

  static final List<int> _anosDisponiveis = List<int>.generate(
    30,
    (int indice) => DateTime.now().year - indice,
  );

  @override
  void initState() {
    super.initState();
    final Motoqueiro? motoqueiro = ref.read(controladorCadastroProvider).motoqueiro;
    if (motoqueiro != null) {
      _preencherComMotoqueiro(motoqueiro);
    }
  }

  @override
  void dispose() {
    _matricula.dispose();
    _marca.dispose();
    _modelo.dispose();
    super.dispose();
  }

  void _preencherComMotoqueiro(Motoqueiro motoqueiro) {
    if (motoqueiro.matricula != null) {
      _matricula.text = motoqueiro.matricula!;
    }
    if (motoqueiro.marca != null) {
      _marca.text = motoqueiro.marca!;
    }
    if (motoqueiro.modelo != null) {
      _modelo.text = motoqueiro.modelo!;
    }
    _cor = motoqueiro.cor;
    _anoFabrico = motoqueiro.anoFabrico;
  }

  void _aoNormalizarMatricula(String valor) {
    final String normalizado = Validadores.normalizarMatricula(valor);
    if (normalizado != _matricula.text) {
      _matricula.value = _matricula.value.copyWith(
        text: normalizado,
        selection: TextSelection.collapsed(offset: normalizado.length),
      );
    }
  }

  void _recalcularValidade() {
    final bool valido =
        Validadores.validarMatricula(_matricula.text) == null &&
        _marca.text.trim().isNotEmpty &&
        _modelo.text.trim().isNotEmpty &&
        _cor != null &&
        _anoFabrico != null;
    if (valido != _valido) {
      setState(() => _valido = valido);
    }
  }

  void _aoSelecionarCor(String cor) {
    setState(() => _cor = cor);
    _recalcularValidade();
  }

  void _aoSelecionarAno(int ano) {
    setState(() => _anoFabrico = ano);
    _recalcularValidade();
  }

  void _voltar() {
    ref.read(controladorCadastroProvider.notifier).voltarPara(FaseCadastro.dados);
  }

  void _continuar() {
    ref
        .read(controladorCadastroProvider.notifier)
        .guardarDadosMota(
          matricula: Validadores.normalizarMatricula(_matricula.text),
          marca: _marca.text.trim(),
          modelo: _modelo.text.trim(),
          cor: _cor!,
          anoFabrico: _anoFabrico!,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<EstadoCadastro>(controladorCadastroProvider, (
      EstadoCadastro? anterior,
      EstadoCadastro atual,
    ) {
      if (atual.erro != null && atual.erro != anterior?.erro) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(atual.erro!)));
      }
    });

    final bool aProcessar = ref.watch(
      controladorCadastroProvider.select(
        (EstadoCadastro estado) => estado.aProcessar,
      ),
    );
    final TextTheme textos = Theme.of(context).textTheme;
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TextStyle? estiloMatricula = textos.bodyLarge?.copyWith(
      fontFamily: 'monospace',
      letterSpacing: 1.5,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _voltar,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const IndicadorPasso(passo: 2, total: 3),
              const SizedBox(height: 32),
              Text(
                'A sua mota',
                style: textos.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              CampoTexto(
                rotulo: 'Matrícula',
                controlador: _matricula,
                dica: 'ABC 123 IN',
                estilo: estiloMatricula,
                validador: Validadores.validarMatricula,
                formatadores: <TextInputFormatter>[
                  FormatadorMaiusculas(),
                  LengthLimitingTextInputFormatter(10),
                ],
                aoPerderFoco: _aoNormalizarMatricula,
                aoMudar: (String _) => _recalcularValidade(),
              ),
              const SizedBox(height: 8),
              Text(
                'O passageiro vê esta matrícula antes de embarcar. '
                'Confirme que está correta.',
                style: textos.bodySmall?.copyWith(
                  color: cores.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              CampoTexto(
                rotulo: 'Marca',
                controlador: _marca,
                dica: 'Honda, Yamaha, TVS...',
                aoMudar: (String _) => _recalcularValidade(),
              ),
              const SizedBox(height: 12),
              CampoTexto(
                rotulo: 'Modelo',
                controlador: _modelo,
                dica: 'CG 125',
                aoMudar: (String _) => _recalcularValidade(),
              ),
              const SizedBox(height: 12),
              CampoSelecao<String>(
                rotulo: 'Cor',
                opcoes: CoresVeiculo.todas,
                valor: _cor,
                dica: 'Selecionar cor',
                aoSelecionar: _aoSelecionarCor,
              ),
              const SizedBox(height: 12),
              CampoSelecao<int>(
                rotulo: 'Ano de fabrico',
                opcoes: _anosDisponiveis,
                valor: _anoFabrico,
                dica: 'Selecionar ano',
                aoSelecionar: _aoSelecionarAno,
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
