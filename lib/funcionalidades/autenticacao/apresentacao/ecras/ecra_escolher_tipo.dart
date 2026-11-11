import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/funcionalidades/autenticacao/dominio/utilizador.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/controladores/controlador_cadastro.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/dominio/motoqueiro.dart';
import 'package:project_x/funcionalidades/inicio/dominio/tipo_veiculo.dart';
import 'package:project_x/nucleo/tema/tema_app.dart';
import 'package:project_x/partilhado/widgets/dialogo_confirmacao.dart';
import 'package:project_x/partilhado/widgets/elementos_rota.dart';
import 'package:project_x/partilhado/widgets/ilustracao_veiculo.dart';

/// Uma das quatro opções: passageiro ou motorista de um dos veículos.
class _Opcao {
  const _Opcao({required this.titulo, required this.descricao, this.veiculo});

  final String titulo;
  final String descricao;

  /// `null` para o passageiro.
  final TipoVeiculo? veiculo;
}

String _pedidos(TipoVeiculo tipo) {
  final List<String> itens = <String>[
    'cor, placa e fotos',
    if (documentosExigidos(tipo).contains(TipoDocumento.cartaConducao))
      'carta de condução',
    if (exigeMarcaModelo(tipo)) 'marca e modelo',
  ];
  return 'Cadastro: ${itens.join(', ')}. Aprovado antes de começares.';
}

final List<_Opcao> _opcoes = <_Opcao>[
  const _Opcao(
    titulo: 'Passageiro',
    descricao: 'Pede mota, txopela ou táxi e vê o preço antes.',
  ),
  _Opcao(
    titulo: 'Mototaxista',
    descricao: _pedidos(TipoVeiculo.mota),
    veiculo: TipoVeiculo.mota,
  ),
  _Opcao(
    titulo: 'Txopelista',
    descricao: _pedidos(TipoVeiculo.txopela),
    veiculo: TipoVeiculo.txopela,
  ),
  _Opcao(
    titulo: 'Taxista',
    descricao: _pedidos(TipoVeiculo.carro),
    veiculo: TipoVeiculo.carro,
  ),
];

class EcraEscolherTipo extends ConsumerStatefulWidget {
  const EcraEscolherTipo({super.key});

  @override
  ConsumerState<EcraEscolherTipo> createState() => _EcraEscolherTipoState();
}

class _EcraEscolherTipoState extends ConsumerState<EcraEscolherTipo> {
  _Opcao? _aGuardar;

  Future<void> _escolher(_Opcao opcao) async {
    setState(() => _aGuardar = opcao);
    final TipoVeiculo? veiculo = opcao.veiculo;
    if (veiculo != null) {
      ref
          .read(controladorCadastroProvider.notifier)
          .escolherTipoVeiculo(veiculo);
    }
    await ref
        .read(controladorAutenticacaoProvider.notifier)
        .escolherTipo(
          veiculo == null
              ? TipoUtilizador.passageiro
              : TipoUtilizador.motoqueiro,
        );
    if (mounted) {
      setState(() => _aGuardar = null);
    }
  }

  Future<void> _voltar() async {
    if (ref
        .read(controladorAutenticacaoProvider.notifier)
        .cancelarEscolhaTipo()) {
      return;
    }
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
    ref.listen<String?>(
      controladorAutenticacaoProvider.select((EstadoAutenticacao e) => e.erro),
      (String? anterior, String? erro) {
        if (erro != null && erro != anterior) {
          mostrarAviso(context, erro);
        }
      },
    );

    final bool aProcessar = _aGuardar != null;
    final TextTheme textos = Theme.of(context).textTheme;
    final ColorScheme cores = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool saiu, Object? _) {
        if (!saiu && !aProcessar) {
          _voltar();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Voltar',
            onPressed: aProcessar ? null : _voltar,
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: <Widget>[
              Text(
                'COMO QUERES USAR A ROTA?',
                style: textos.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Podes mudar mais tarde no menu.',
                style: textos.bodyMedium?.copyWith(
                  color: cores.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              for (final _Opcao opcao in _opcoes) ...<Widget>[
                _CartaoOpcao(
                  opcao: opcao,
                  aCarregar: _aGuardar == opcao,
                  aoTocar: aProcessar ? null : () => _escolher(opcao),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CartaoOpcao extends StatelessWidget {
  const _CartaoOpcao({
    required this.opcao,
    required this.aCarregar,
    required this.aoTocar,
  });

  final _Opcao opcao;
  final bool aCarregar;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final TextTheme textos = Theme.of(context).textTheme;
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TipoVeiculo? veiculo = opcao.veiculo;
    return Material(
      color: cores.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TemaApp.raio),
        side: BorderSide(color: cores.outlineVariant),
      ),
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(TemaApp.raio),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              if (veiculo == null)
                SizedBox(
                  width: 72,
                  height: 48,
                  child: Icon(
                    Icons.person_pin_circle_outlined,
                    size: 40,
                    color: cores.primary,
                  ),
                )
              else
                IlustracaoVeiculo(tipo: veiculo, tamanho: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      opcao.titulo,
                      style: textos.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      opcao.descricao,
                      style: textos.bodySmall?.copyWith(
                        color: cores.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (aCarregar)
                const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else
                Icon(Icons.chevron_right, color: cores.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
