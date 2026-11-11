import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/widgets/mudar_tipo.dart';
import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/funcionalidades/autenticacao/dominio/utilizador.dart';
import 'package:project_x/funcionalidades/corrida/apresentacao/controladores/controlador_pedidos_motoqueiro.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/nucleo/utilitarios/validadores.dart';
import 'package:project_x/partilhado/widgets/botao_principal.dart';
import 'package:project_x/partilhado/widgets/dialogo_confirmacao.dart';
import 'package:project_x/partilhado/widgets/estado_vazio.dart';

class EcraPainelMotoqueiro extends ConsumerStatefulWidget {
  const EcraPainelMotoqueiro({super.key});

  @override
  ConsumerState<EcraPainelMotoqueiro> createState() =>
      _EcraPainelMotoqueiroState();
}

class _EcraPainelMotoqueiroState extends ConsumerState<EcraPainelMotoqueiro> {
  static const int _abaInicio = 0;

  int _abaAtual = 0;

  static const List<NavigationDestination> _abas = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Início',
    ),
    NavigationDestination(
      icon: Icon(Icons.route_outlined),
      selectedIcon: Icon(Icons.route),
      label: 'Corridas',
    ),
    NavigationDestination(
      icon: Icon(Icons.payments_outlined),
      selectedIcon: Icon(Icons.payments),
      label: 'Ganhos',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Perfil',
    ),
  ];

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

  @override
  Widget build(BuildContext context) {
    final Widget corpo = switch (_abaAtual) {
      1 => const EstadoVazio(
        icone: Icons.route_outlined,
        titulo: 'Ainda sem corridas',
        descricao: 'As corridas que fizeres aparecem aqui.',
      ),
      2 => const EstadoVazio(
        icone: Icons.payments_outlined,
        titulo: 'Ainda sem ganhos',
        descricao: 'O que ganhares com as corridas aparece aqui.',
      ),
      3 => _AbaPerfil(aoTerminarSessao: _terminarSessao),
      _ => _construirInicio(context),
    };

    // O voltar do sistema regressa primeiro ao separador Início; só sai da
    // app a partir dele.
    return PopScope(
      canPop: _abaAtual == _abaInicio,
      onPopInvokedWithResult: (bool saiu, Object? _) {
        if (!saiu) {
          setState(() => _abaAtual = _abaInicio);
        }
      },
      child: Scaffold(
        body: SafeArea(child: corpo),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _abaAtual,
          onDestinationSelected: (int indice) =>
              setState(() => _abaAtual = indice),
          destinations: _abas,
        ),
      ),
    );
  }

  Widget _construirInicio(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TextTheme textos = Theme.of(context).textTheme;
    final bool online = ref.watch(
      controladorPedidosMotoqueiroProvider.select(
        (EstadoPedidosMotoqueiro e) => e.disponivel,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: cores.surfaceContainerHighest,
          child: Row(
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: online ? CoresApp.sucesso : cores.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                online ? 'Estás online' : 'Estás offline',
                style: textos.titleMedium,
              ),
              const Spacer(),
              Switch(
                value: online,
                onChanged: ref
                    .read(controladorPedidosMotoqueiroProvider.notifier)
                    .definirDisponivel,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _CartaoMetrica(
                        icone: Icons.payments_outlined,
                        rotulo: 'Ganhos de hoje',
                        valor: '1 250,00 MT',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CartaoMetrica(
                        icone: Icons.route_outlined,
                        rotulo: 'Corridas de hoje',
                        valor: '6',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.calendar_today_outlined,
                          color: cores.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Subscrição semanal',
                                style: textos.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ativa até sexta-feira.',
                                style: textos.bodySmall?.copyWith(
                                  color: cores.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AbaPerfil extends ConsumerWidget {
  const _AbaPerfil({required this.aoTerminarSessao});

  final VoidCallback aoTerminarSessao;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Utilizador? utilizador = ref.watch(
      controladorAutenticacaoProvider.select(
        (EstadoAutenticacao estado) => estado.utilizador,
      ),
    );
    final bool aProcessar = ref.watch(
      controladorAutenticacaoProvider.select(
        (EstadoAutenticacao estado) => estado.aProcessar,
      ),
    );
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TextTheme textos = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(
          'Perfil',
          style: textos.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: cores.primaryContainer,
              foregroundColor: cores.onPrimaryContainer,
              child: const Icon(Icons.person),
            ),
            title: Text(utilizador?.nome ?? 'Sem nome'),
            subtitle: Text(
              '${Validadores.indicativo} '
              '${Validadores.formatarTelefone(utilizador?.telefone ?? '')}',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_pin_circle_outlined),
            title: const Text('Mudar para passageiro'),
            subtitle: const Text('Pede viagens com a mesma conta.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: aProcessar
                ? null
                : () => mudarTipoComConfirmacao(
                    context,
                    ref,
                    TipoUtilizador.passageiro,
                  ),
          ),
        ),
        const SizedBox(height: 32),
        BotaoSecundario(
          texto: 'Terminar sessão',
          icone: Icons.logout,
          aoPremir: aProcessar ? null : aoTerminarSessao,
          aCarregar: aProcessar,
        ),
      ],
    );
  }
}

class _CartaoMetrica extends StatelessWidget {
  const _CartaoMetrica({
    required this.icone,
    required this.rotulo,
    required this.valor,
  });

  final IconData icone;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TextTheme textos = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icone, color: cores.primary),
            const SizedBox(height: 8),
            Text(
              valor,
              style: textos.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              rotulo,
              style: textos.bodySmall?.copyWith(color: cores.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
