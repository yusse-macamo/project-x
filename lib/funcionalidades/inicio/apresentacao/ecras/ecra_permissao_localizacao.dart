import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/localizacao/apresentacao/controladores/controlador_mapa.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/estado_permissao_localizacao.dart';
import 'package:project_x/partilhado/widgets/botao_principal.dart';
import 'package:project_x/partilhado/widgets/indicador_carregamento.dart';

class EcraPermissaoLocalizacao extends ConsumerStatefulWidget {
  const EcraPermissaoLocalizacao({super.key});

  @override
  ConsumerState<EcraPermissaoLocalizacao> createState() =>
      _EcraPermissaoLocalizacaoState();
}

class _EcraPermissaoLocalizacaoState
    extends ConsumerState<EcraPermissaoLocalizacao>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      ref.read(controladorMapaProvider.notifier).iniciar();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) {
      ref.read(controladorMapaProvider.notifier).iniciar();
    }
  }

  Future<void> _abrirDefinicoesApp() =>
      ref.read(controladorMapaProvider.notifier).abrirDefinicoesApp();

  Future<void> _abrirDefinicoesLocalizacao() =>
      ref.read(controladorMapaProvider.notifier).abrirDefinicoesLocalizacao();

  void _pedirPermissao() {
    ref.read(controladorMapaProvider.notifier).pedirPermissao();
  }

  void _continuarSemLocalizacao() {
    ref.read(controladorMapaProvider.notifier).continuarSemLocalizacao();
  }

  @override
  Widget build(BuildContext context) {
    final EstadoMapa estado = ref.watch(controladorMapaProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: estado.aCarregar
              ? const IndicadorCarregamento()
              : _Conteudo(
                  permissao: estado.permissao,
                  aoPermitir: _pedirPermissao,
                  aoAbrirDefinicoesApp: _abrirDefinicoesApp,
                  aoAbrirDefinicoesLocalizacao: _abrirDefinicoesLocalizacao,
                  aoContinuarSemLocalizacao: _continuarSemLocalizacao,
                ),
        ),
      ),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({
    required this.permissao,
    required this.aoPermitir,
    required this.aoAbrirDefinicoesApp,
    required this.aoAbrirDefinicoesLocalizacao,
    required this.aoContinuarSemLocalizacao,
  });

  final EstadoPermissaoLocalizacao permissao;
  final VoidCallback aoPermitir;
  final VoidCallback aoAbrirDefinicoesApp;
  final VoidCallback aoAbrirDefinicoesLocalizacao;
  final VoidCallback aoContinuarSemLocalizacao;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TextTheme textos = Theme.of(context).textTheme;

    final (
      IconData icone,
      String titulo,
      String corpo,
      String acao,
      VoidCallback aoPremirAcao,
    )
    conteudo = switch (permissao) {
      EstadoPermissaoLocalizacao.negadaPermanente => (
        Icons.location_disabled,
        'Localização bloqueada',
        'A permissão foi recusada e só pode ser reativada nas definições '
            'do telemóvel',
        'Abrir definições',
        aoAbrirDefinicoesApp,
      ),
      EstadoPermissaoLocalizacao.servicoDesligado => (
        Icons.gps_off,
        'GPS desligado',
        'Liga a localização no teu telemóvel para continuar',
        'Ligar localização',
        aoAbrirDefinicoesLocalizacao,
      ),
      EstadoPermissaoLocalizacao.negada ||
      EstadoPermissaoLocalizacao.desconhecido ||
      EstadoPermissaoLocalizacao.concedida => (
        Icons.location_on_outlined,
        'Precisamos da tua localização',
        'Para te mostrar os motoqueiros mais próximos e calcular o '
            'preço até ao destino',
        'Permitir',
        aoPermitir,
      ),
    };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(conteudo.$1, size: 56, color: cores.primary),
          const SizedBox(height: 32),
          Text(
            conteudo.$2,
            style: textos.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            conteudo.$3,
            style: textos.bodyMedium?.copyWith(color: cores.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          BotaoPrincipal(texto: conteudo.$4, aoPremir: conteudo.$5),
          const SizedBox(height: 8),
          TextButton(
            onPressed: aoContinuarSemLocalizacao,
            child: const Text('Escolher a origem no mapa'),
          ),
        ],
      ),
    );
  }
}
