import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/controladores/controlador_cadastro.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/widgets/campo_selecao.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/dados/selector_imagem.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/dominio/excecao_selector_imagem.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/dominio/motoqueiro.dart';
import 'package:project_x/funcionalidades/inicio/dominio/tipo_veiculo.dart';
import 'package:project_x/nucleo/constantes/cores_veiculo.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/nucleo/tema/tema_app.dart';
import 'package:project_x/nucleo/utilitarios/formatadores.dart';
import 'package:project_x/nucleo/utilitarios/validadores.dart';
import 'package:project_x/partilhado/widgets/botao_principal.dart';
import 'package:project_x/partilhado/widgets/campo_texto.dart';
import 'package:project_x/partilhado/widgets/estado_vazio.dart';
import 'package:project_x/partilhado/widgets/ilustracao_veiculo.dart';
import 'package:project_x/partilhado/widgets/imagem_local.dart';
import 'package:project_x/partilhado/widgets/indicador_carregamento.dart';

enum _OrigemImagem { camara, galeria }

enum _AcaoSemAcesso { alternativa, definicoes }

/// Cadastro do mototaxista, do txopelista ou do taxista: um só ecrã, com só
/// os campos e as fotografias que esse veículo pede. Cada tipo tem a sua rota
/// (`/cadastro/mota`, `/cadastro/txopela`, `/cadastro/taxi`).
class EcraCadastroMotorista extends ConsumerStatefulWidget {
  const EcraCadastroMotorista({required this.tipo, super.key});

  final TipoVeiculo tipo;

  @override
  ConsumerState<EcraCadastroMotorista> createState() =>
      _EcraCadastroMotoristaState();
}

class _EcraCadastroMotoristaState extends ConsumerState<EcraCadastroMotorista> {
  final TextEditingController _nome = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _matricula = TextEditingController();
  final TextEditingController _marca = TextEditingController();
  final TextEditingController _modelo = TextEditingController();
  String? _cor;

  /// Fotografias escolhidas neste ecrã e ainda não enviadas.
  final Map<TipoDocumento, String> _fotosNovas = <TipoDocumento, String>{};
  bool _preenchido = false;

  @override
  void initState() {
    super.initState();
    final EstadoCadastro estado = ref.read(controladorCadastroProvider);
    if (estado.fase == FaseCadastro.inicial) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        ref.read(controladorCadastroProvider.notifier).verificarCadastro();
      });
    } else {
      _preencher(estado.motoqueiro);
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _matricula.dispose();
    _marca.dispose();
    _modelo.dispose();
    super.dispose();
  }

  void _preencher(Motoqueiro? motoqueiro) {
    if (_preenchido) {
      return;
    }
    _preenchido = true;
    _nome.text =
        motoqueiro?.nomeCompleto ??
        ref.read(controladorAutenticacaoProvider).utilizador?.nome ??
        '';
    _email.text = motoqueiro?.email ?? '';
    _matricula.text = motoqueiro?.matricula ?? '';
    _marca.text = motoqueiro?.marca ?? '';
    _modelo.text = motoqueiro?.modelo ?? '';
    _cor = motoqueiro?.cor;
  }

  bool get _pedeMarcaModelo => exigeMarcaModelo(widget.tipo);

  List<TipoDocumento> get _exigidos => documentosExigidos(widget.tipo);

  bool _temFoto(TipoDocumento tipo, Motoqueiro? motoqueiro) =>
      _fotosNovas.containsKey(tipo) ||
      (motoqueiro?.documentos.containsKey(tipo) ?? false);

  bool _valido(Motoqueiro? motoqueiro) =>
      Validadores.validarNome(_nome.text) == null &&
      Validadores.validarEmail(_email.text) == null &&
      Validadores.validarMatricula(_matricula.text) == null &&
      _cor != null &&
      (!_pedeMarcaModelo ||
          (_marca.text.trim().isNotEmpty && _modelo.text.trim().isNotEmpty)) &&
      _exigidos.every((TipoDocumento t) => _temFoto(t, motoqueiro));

  void _aoNormalizarMatricula(String valor) {
    final String normalizado = Validadores.normalizarMatricula(valor);
    if (normalizado != _matricula.text) {
      _matricula.value = _matricula.value.copyWith(
        text: normalizado,
        selection: TextSelection.collapsed(offset: normalizado.length),
      );
    }
  }

  Future<void> _voltar() async {
    if (ref.read(controladorCadastroProvider.notifier).voltarDoFormulario()) {
      return;
    }
    ref.read(controladorAutenticacaoProvider.notifier).voltarAEscolherTipo();
  }

  void _enviar() {
    ref
        .read(controladorCadastroProvider.notifier)
        .enviarParaAprovacao(
          nomeCompleto: _nome.text.trim(),
          email: _email.text.trim(),
          matricula: Validadores.normalizarMatricula(_matricula.text),
          cor: _cor!,
          marca: _pedeMarcaModelo ? _marca.text.trim() : null,
          modelo: _pedeMarcaModelo ? _modelo.text.trim() : null,
          fotosNovas: Map<TipoDocumento, String>.of(_fotosNovas),
        );
  }

  Future<void> _escolherFoto(TipoDocumento tipo) async {
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
    await _obterImagem(tipo, origem);
  }

  Future<void> _obterImagem(TipoDocumento tipo, _OrigemImagem origem) async {
    final SelectorImagem seletor = ref.read(selectorImagemProvider);
    final String? caminho;
    try {
      caminho = origem == _OrigemImagem.camara
          ? await seletor.tirarFotografia()
          : await seletor.escolherDaGaleria();
    } on ExcecaoSelectorImagem catch (e) {
      if (mounted) {
        await _tratarFalhaImagem(tipo, e.motivo);
      }
      return;
    }
    if (caminho == null || !mounted) {
      return;
    }
    setState(() => _fotosNovas[tipo] = caminho!);
  }

  Future<void> _tratarFalhaImagem(
    TipoDocumento tipo,
    MotivoFalhaImagem motivo,
  ) async {
    switch (motivo) {
      case MotivoFalhaImagem.semAcessoCamara:
        await _mostrarSemAcesso(
          tipo,
          titulo: 'Sem acesso à câmara',
          mensagem:
              'Para tirar a fotografia, permite o acesso à câmara nas '
              'definições do telemóvel. Também podes escolher uma fotografia '
              'da galeria.',
          alternativa: _OrigemImagem.galeria,
          rotuloAlternativa: 'Escolher da galeria',
        );
      case MotivoFalhaImagem.semAcessoGaleria:
        await _mostrarSemAcesso(
          tipo,
          titulo: 'Sem acesso às fotografias',
          mensagem:
              'Para escolher uma fotografia, permite o acesso às fotografias '
              'nas definições do telemóvel. Também podes tirar a fotografia '
              'agora.',
          alternativa: _OrigemImagem.camara,
          rotuloAlternativa: 'Tirar fotografia',
        );
      case MotivoFalhaImagem.semCamara:
        _aviso(
          'Não encontrámos uma câmara neste telemóvel. '
          'Escolhe uma fotografia da galeria.',
        );
      case MotivoFalhaImagem.desconhecido:
        _aviso('Não foi possível abrir a câmara. Tenta de novo.');
    }
  }

  Future<void> _mostrarSemAcesso(
    TipoDocumento tipo, {
    required String titulo,
    required String mensagem,
    required _OrigemImagem alternativa,
    required String rotuloAlternativa,
  }) async {
    final _AcaoSemAcesso? acao = await showDialog<_AcaoSemAcesso>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_AcaoSemAcesso.alternativa),
              child: Text(rotuloAlternativa),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(_AcaoSemAcesso.definicoes),
              child: const Text('Abrir definições'),
            ),
          ],
        );
      },
    );
    if (!mounted) {
      return;
    }
    switch (acao) {
      case _AcaoSemAcesso.alternativa:
        await _obterImagem(tipo, alternativa);
      case _AcaoSemAcesso.definicoes:
        await ref.read(selectorImagemProvider).abrirDefinicoesApp();
      case null:
        return;
    }
  }

  void _aviso(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  static String _tituloVeiculo(TipoVeiculo tipo) => switch (tipo) {
    TipoVeiculo.mota => 'A tua mota',
    TipoVeiculo.txopela => 'A tua txopela',
    TipoVeiculo.carro => 'O teu táxi',
    TipoVeiculo.camioneta => 'A tua camioneta',
  };

  static String _tituloEcra(TipoVeiculo tipo) => switch (tipo) {
    TipoVeiculo.mota => 'Cadastro de mototaxista',
    TipoVeiculo.txopela => 'Cadastro de txopelista',
    TipoVeiculo.carro => 'Cadastro de taxista',
    TipoVeiculo.camioneta => 'Cadastro de camionista',
  };

  @override
  Widget build(BuildContext context) {
    ref.listen<EstadoCadastro>(controladorCadastroProvider, (
      EstadoCadastro? anterior,
      EstadoCadastro atual,
    ) {
      if (atual.erro != null &&
          atual.erro != anterior?.erro &&
          atual.fase != FaseCadastro.inicial) {
        _aviso(atual.erro!);
      }
      if (anterior?.fase == FaseCadastro.inicial &&
          atual.fase != FaseCadastro.inicial) {
        setState(() => _preencher(atual.motoqueiro));
      }
    });

    final EstadoCadastro estado = ref.watch(controladorCadastroProvider);
    final Motoqueiro? motoqueiro = estado.motoqueiro;
    final bool aProcessar = estado.aProcessar;

    final Widget corpo;
    if (estado.fase == FaseCadastro.inicial) {
      corpo = estado.erro == null
          ? const IndicadorCarregamento()
          : EstadoVazio(
              icone: Icons.wifi_off,
              titulo: 'Não foi possível abrir o cadastro',
              descricao: estado.erro!,
              textoAcao: 'Tentar de novo',
              aoTocarAcao: () => ref
                  .read(controladorCadastroProvider.notifier)
                  .verificarCadastro(),
            );
    } else {
      corpo = _formulario(context, motoqueiro, aProcessar);
    }

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
          title: Text(_tituloEcra(widget.tipo)),
        ),
        body: SafeArea(child: corpo),
      ),
    );
  }

  Widget _formulario(
    BuildContext context,
    Motoqueiro? motoqueiro,
    bool aProcessar,
  ) {
    final TextTheme textos = Theme.of(context).textTheme;
    final ColorScheme cores = Theme.of(context).colorScheme;
    final String? motivo = motoqueiro?.motivoRejeicao;
    final TextStyle? estiloSeccao = textos.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
    );
    void atualizar(String _) => setState(() {});

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: <Widget>[
              if (motivo != null) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cores.errorContainer,
                    borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
                  ),
                  child: Text(
                    'A corrigir: $motivo',
                    style: TextStyle(color: cores.onErrorContainer),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text('Os teus dados', style: estiloSeccao),
              const SizedBox(height: 12),
              CampoTexto(
                rotulo: 'Nome completo',
                controlador: _nome,
                dica: 'Nome e apelido',
                validador: Validadores.validarNome,
                formatadores: <TextInputFormatter>[
                  FormatadorCapitalizacaoPalavras(),
                ],
                aoMudar: atualizar,
              ),
              const SizedBox(height: 12),
              CampoTexto(
                rotulo: 'Email',
                controlador: _email,
                dica: 'nome@exemplo.com',
                teclado: TextInputType.emailAddress,
                validador: Validadores.validarEmail,
                aoMudar: atualizar,
              ),
              const SizedBox(height: 32),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _tituloVeiculo(widget.tipo),
                      style: estiloSeccao,
                    ),
                  ),
                  IlustracaoVeiculo(tipo: widget.tipo, tamanho: 36),
                ],
              ),
              const SizedBox(height: 12),
              CampoSelecao<String>(
                rotulo: 'Cor',
                opcoes: CoresVeiculo.todas,
                valor: _cor,
                dica: 'Selecionar cor',
                aoSelecionar: (String cor) => setState(() => _cor = cor),
              ),
              const SizedBox(height: 12),
              CampoTexto(
                rotulo: 'Placa',
                controlador: _matricula,
                dica: 'ABC 123 MP',
                estilo: textos.bodyLarge?.copyWith(
                  fontFamily: 'monospace',
                  letterSpacing: 1.5,
                ),
                validador: Validadores.validarMatricula,
                formatadores: <TextInputFormatter>[
                  FormatadorMaiusculas(),
                  LengthLimitingTextInputFormatter(10),
                ],
                aoPerderFoco: _aoNormalizarMatricula,
                aoMudar: atualizar,
              ),
              if (_pedeMarcaModelo) ...<Widget>[
                const SizedBox(height: 12),
                CampoTexto(
                  rotulo: 'Marca',
                  controlador: _marca,
                  dica: 'Toyota, Nissan, Honda...',
                  aoMudar: atualizar,
                ),
                const SizedBox(height: 12),
                CampoTexto(
                  rotulo: 'Modelo',
                  controlador: _modelo,
                  dica: 'Corolla, Fit...',
                  aoMudar: atualizar,
                ),
              ],
              const SizedBox(height: 32),
              Text('Fotografias', style: estiloSeccao),
              const SizedBox(height: 4),
              Text(
                'Quem aprova o cadastro confirma-as antes de começares.',
                style: textos.bodySmall?.copyWith(
                  color: cores.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              for (final TipoDocumento tipo in _exigidos) ...<Widget>[
                _CartaoFoto(
                  tipo: tipo,
                  veiculo: widget.tipo,
                  caminhoLocal: _fotosNovas[tipo],
                  jaEnviada: motoqueiro?.documentos.containsKey(tipo) ?? false,
                  aoTocar: aProcessar ? null : () => _escolherFoto(tipo),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: BotaoPrincipal(
            texto: 'Enviar para aprovação',
            icone: Icons.send_outlined,
            aCarregar: aProcessar,
            aoPremir: _valido(motoqueiro) ? _enviar : null,
          ),
        ),
      ],
    );
  }
}

class _CartaoFoto extends StatelessWidget {
  const _CartaoFoto({
    required this.tipo,
    required this.veiculo,
    required this.caminhoLocal,
    required this.jaEnviada,
    required this.aoTocar,
  });

  final TipoDocumento tipo;
  final TipoVeiculo veiculo;
  final String? caminhoLocal;
  final bool jaEnviada;
  final VoidCallback? aoTocar;

  (String, String, IconData) get _info {
    final String nomeVeiculo = switch (veiculo) {
      TipoVeiculo.mota => 'A mota',
      TipoVeiculo.txopela => 'A txopela',
      TipoVeiculo.carro => 'O táxi',
      TipoVeiculo.camioneta => 'A camioneta',
    };
    return switch (tipo) {
      TipoDocumento.fotoMotorista => (
        'Fotografia tua',
        'Rosto visível, sem óculos escuros nem capacete',
        Icons.face_outlined,
      ),
      TipoDocumento.veiculoFrente => (
        '$nomeVeiculo de frente',
        'O veículo inteiro na fotografia',
        Icons.photo_camera_front_outlined,
      ),
      TipoDocumento.veiculoTraseira => (
        '$nomeVeiculo de trás',
        'Com a placa bem legível',
        Icons.pin_outlined,
      ),
      TipoDocumento.cartaConducao => (
        'Carta de condução',
        'Frente legível, dentro da validade',
        Icons.badge_outlined,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textos = Theme.of(context).textTheme;
    final ColorScheme cores = Theme.of(context).colorScheme;
    final (String nome, String descricao, IconData icone) = _info;
    final String? caminho = caminhoLocal;
    final bool temFoto = caminho != null || jaEnviada;

    final Widget miniatura = ClipRRect(
      borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
      child: SizedBox.square(
        dimension: 56,
        child: caminho != null
            ? ImagemLocal(
                caminho: caminho,
                larguraCache: 168,
                alternativa: _icone(cores, Icons.image_outlined),
              )
            : _icone(cores, temFoto ? Icons.cloud_done_outlined : icone),
      ),
    );

    return Material(
      color: cores.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TemaApp.raio),
        side: BorderSide(
          color: temFoto ? CoresApp.sucesso : cores.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(TemaApp.raio),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              miniatura,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(nome, style: textos.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      temFoto ? 'Toca para trocar' : descricao,
                      style: textos.bodySmall?.copyWith(
                        color: cores.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                temFoto ? Icons.check_circle : Icons.add_a_photo_outlined,
                color: temFoto ? CoresApp.sucesso : cores.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _icone(ColorScheme cores, IconData icone) => ColoredBox(
    color: cores.surfaceContainerHighest,
    child: Icon(icone, color: cores.onSurfaceVariant),
  );
}
