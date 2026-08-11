import 'package:flutter/material.dart';

import 'package:project_x/nucleo/tema/cores_app.dart';

class EcraPainelMotoqueiro extends StatefulWidget {
  const EcraPainelMotoqueiro({super.key});

  @override
  State<EcraPainelMotoqueiro> createState() => _EcraPainelMotoqueiroState();
}

class _EcraPainelMotoqueiroState extends State<EcraPainelMotoqueiro> {
  bool _online = false;
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

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TextTheme textos = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              color: cores.surfaceContainerHighest,
              child: Row(
                children: <Widget>[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _online
                          ? CoresApp.sucesso
                          : cores.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _online ? 'Está online' : 'Está offline',
                    style: textos.titleMedium,
                  ),
                  const Spacer(),
                  Switch(
                    value: _online,
                    onChanged: (bool valor) => setState(() => _online = valor),
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
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _abaAtual,
        onDestinationSelected: (int indice) =>
            setState(() => _abaAtual = indice),
        destinations: _abas,
      ),
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
