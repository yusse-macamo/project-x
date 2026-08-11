import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/controladores/controlador_cadastro.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/widgets/indicador_passo.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/dados/selector_imagem.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/dominio/motoqueiro.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/nucleo/tema/tema_app.dart';
import 'package:project_x/partilhado/widgets/botao_principal.dart';

enum _OrigemImagem { camara, galeria }

class _InfoDocumento {
  const _InfoDocumento({
    required this.icone,
    required this.nome,
    required this.descricao,
  });

  final IconData icone;
  final String nome;
  final String descricao;
}

const Map<TipoDocumento, _InfoDocumento> _infoDocumentos =
    <TipoDocumento, _InfoDocumento>{
      TipoDocumento.cartaConducao: _InfoDocumento(
        icone: Icons.badge_outlined,
        nome: 'Carta de condução',
        descricao: 'Frente e verso legíveis',
      ),
      TipoDocumento.livrete: _InfoDocumento(
        icone: Icons.menu_book_outlined,
        nome: 'Livrete',
        descricao: 'Frente e verso legíveis',
      ),
      TipoDocumento.bilheteIdentidade: _InfoDocumento(
        icone: Icons.credit_card_outlined,
        nome: 'Bilhete de identidade',
        descricao: 'Frente e verso legíveis',
      ),
      TipoDocumento.selfie: _InfoDocumento(
        icone: Icons.face_outlined,
        nome: 'Fotografia sua',
        descricao: 'Rosto visível, sem óculos escuros',
      ),
    };

class EcraCadastroPassoDocumentos extends ConsumerStatefulWidget {
  const EcraCadastroPassoDocumentos({super.key});

  @override
  ConsumerState<EcraCadastroPassoDocumentos> createState() =>
      _EcraCadastroPassoDocumentosState();
}

class _EcraCadastroPassoDocumentosState
    extends ConsumerState<EcraCadastroPassoDocumentos> {
  late Map<TipoDocumento, Documento> _documentos;
  final Set<TipoDocumento> _aEnviar = <TipoDocumento>{};

  @override
  void initState() {
    super.initState();
    final Motoqueiro? motoqueiro = ref.read(controladorCadastroProvider).motoqueiro;
    _documentos = <TipoDocumento, Documento>{
      for (final TipoDocumento tipo in TipoDocumento.values)
        tipo: Documento(
          tipo: tipo,
          caminhoLocal: motoqueiro?.documentos[tipo],
          enviado: motoqueiro?.documentos.containsKey(tipo) ?? false,
        ),
    };
  }

  Future<void> _abrirFolhaOpcoes(TipoDocumento tipo) async {
    final _OrigemImagem? origem = await showModalBottomSheet<_OrigemImagem>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Tirar fotografia'),
                onTap: () => Navigator.of(context).pop(_OrigemImagem.camara),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Escolher da galeria'),
                onTap: () => Navigator.of(context).pop(_OrigemImagem.galeria),
              ),
            ],
          ),
        );
      },
    );
    if (origem == null || !mounted) {
      return;
    }
    final SelectorImagem seletor = ref.read(selectorImagemProvider);
    final String? caminho = origem == _OrigemImagem.camara
        ? await seletor.tirarFotografia()
        : await seletor.escolherDaGaleria();
    if (caminho == null || !mounted) {
      return;
    }
    await _enviarDocumento(tipo, caminho);
  }

  Future<void> _tentarNovamente(TipoDocumento tipo) async {
    final String? caminho = _documentos[tipo]?.caminhoLocal;
    if (caminho == null) {
      return;
    }
    await _enviarDocumento(tipo, caminho);
  }

  Future<void> _enviarDocumento(TipoDocumento tipo, String caminho) async {
    setState(() {
      _aEnviar.add(tipo);
      _documentos[tipo] = _documentos[tipo]!.copiarCom(
        caminhoLocal: caminho,
        limparErro: true,
      );
    });
    final ControladorCadastro controlador = ref.read(
      controladorCadastroProvider.notifier,
    );
    await controlador.enviarDocumento(tipo: tipo, caminho: caminho);
    if (!mounted) {
      return;
    }
    final EstadoCadastro estado = ref.read(controladorCadastroProvider);
    setState(() {
      _aEnviar.remove(tipo);
      _documentos[tipo] = estado.erro != null
          ? _documentos[tipo]!.copiarCom(erro: estado.erro)
          : _documentos[tipo]!.copiarCom(enviado: true, limparErro: true);
    });
    if (estado.erro != null) {
      controlador.limparErro();
    }
  }

  Future<void> _confirmarESubmeter(Motoqueiro motoqueiro) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Submeter para aprovação'),
          content: Text(
            'Nome: ${motoqueiro.nomeCompleto}\n'
            'Matrícula: ${motoqueiro.matricula}\n'
            'Documentos: ${motoqueiro.documentos.length} de '
            '${TipoDocumento.values.length}',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Submeter'),
            ),
          ],
        );
      },
    );
    if (confirmado != true || !mounted) {
      return;
    }
    final ControladorCadastro controlador = ref.read(
      controladorCadastroProvider.notifier,
    );
    await controlador.submeterParaAprovacao();
    if (!mounted) {
      return;
    }
    final EstadoCadastro estado = ref.read(controladorCadastroProvider);
    if (estado.erro != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(estado.erro!)));
      controlador.limparErro();
    }
  }

  Widget _construirIndicadorEstado(Documento documento, bool aEnviar) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    if (aEnviar) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }
    if (documento.enviado) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cores.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
            ),
            child: Icon(
              Icons.image_outlined,
              size: 18,
              color: cores.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.check_circle, color: CoresApp.sucesso),
        ],
      );
    }
    if (documento.erro != null) {
      return const Icon(Icons.error_outline, color: CoresApp.erro);
    }
    return Icon(Icons.upload_outlined, color: cores.onSurfaceVariant);
  }

  Widget _construirCartao(TipoDocumento tipo) {
    final _InfoDocumento info = _infoDocumentos[tipo]!;
    final Documento documento = _documentos[tipo]!;
    final bool aEnviar = _aEnviar.contains(tipo);
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TextTheme textos = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(TemaApp.raio),
        onTap: (documento.enviado || aEnviar)
            ? null
            : () => _abrirFolhaOpcoes(tipo),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(info.icone, color: cores.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(info.nome, style: textos.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          info.descricao,
                          style: textos.bodySmall?.copyWith(
                            color: cores.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _construirIndicadorEstado(documento, aEnviar),
                ],
              ),
              if (documento.erro != null && !aEnviar) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  documento.erro!,
                  style: textos.bodySmall?.copyWith(color: CoresApp.erro),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => _tentarNovamente(tipo),
                    child: const Text('Tentar de novo'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool aProcessar = ref.watch(
      controladorCadastroProvider.select(
        (EstadoCadastro estado) => estado.aProcessar,
      ),
    );
    final Motoqueiro? motoqueiro = ref.watch(
      controladorCadastroProvider.select(
        (EstadoCadastro estado) => estado.motoqueiro,
      ),
    );
    final bool todosEnviados = _documentos.values.every(
      (Documento documento) => documento.enviado,
    );
    final TextTheme textos = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const IndicadorPasso(passo: 3, total: 3),
                  const SizedBox(height: 32),
                  Text(
                    'Documentos',
                    style: textos.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                itemCount: TipoDocumento.values.length,
                separatorBuilder: (BuildContext context, int indice) =>
                    const SizedBox(height: 12),
                itemBuilder: (BuildContext context, int indice) =>
                    _construirCartao(TipoDocumento.values[indice]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: BotaoPrincipal(
                texto: 'Submeter para aprovação',
                aoPremir: todosEnviados && motoqueiro != null
                    ? () => _confirmarESubmeter(motoqueiro)
                    : null,
                aCarregar: aProcessar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
