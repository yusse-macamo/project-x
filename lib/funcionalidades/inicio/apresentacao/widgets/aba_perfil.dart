import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/funcionalidades/autenticacao/dominio/utilizador.dart';
import 'package:project_x/funcionalidades/capulana/apresentacao/controladores/controlador_capulana.dart';
import 'package:project_x/nucleo/utilitarios/validadores.dart';
import 'package:project_x/partilhado/widgets/botao_principal.dart';
import 'package:project_x/partilhado/widgets/dialogo_confirmacao.dart';
import 'package:project_x/partilhado/widgets/elementos_rota.dart';
import 'package:project_x/partilhado/widgets/faixa_capulana.dart';
import 'package:project_x/rotas/rotas_app.dart';

Future<void> terminarSessaoComConfirmacao(
  BuildContext context,
  WidgetRef ref,
) async {
  if (!await confirmarTerminarSessao(context)) {
    return;
  }
  await ref.read(controladorAutenticacaoProvider.notifier).terminarSessao();
  final String? erro = ref.read(controladorAutenticacaoProvider).erro;
  if (erro == null || !context.mounted) {
    return;
  }
  mostrarAviso(context, erro);
  ref.read(controladorAutenticacaoProvider.notifier).limparErro();
}

class AbaPerfil extends ConsumerWidget {
  const AbaPerfil({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EstadoAutenticacao autenticacao = ref.watch(
      controladorAutenticacaoProvider,
    );
    final Utilizador? utilizador = autenticacao.utilizador;
    final String nomeCapulana = ref
        .watch(controladorCapulanaProvider)
        .padrao
        .nome;
    final TextTheme textos = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text('PERFIL', style: textos.headlineSmall),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
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
            leading: const SizedBox.square(
              dimension: 40,
              child: ClipOval(child: CapulanaAtual()),
            ),
            title: const Text('A tua capulana'),
            subtitle: Text(nomeCapulana),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Rotas.capulana),
          ),
        ),
        const SizedBox(height: 32),
        BotaoSecundario(
          texto: 'Terminar sessão',
          icone: Icons.logout,
          aCarregar: autenticacao.aProcessar,
          aoPremir: () => terminarSessaoComConfirmacao(context, ref),
        ),
      ],
    );
  }
}
