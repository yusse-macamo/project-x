import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/funcionalidades/autenticacao/dominio/utilizador.dart';
import 'package:project_x/partilhado/widgets/dialogo_confirmacao.dart';

/// Troca entre passageiro e motorista, a partir do menu de qualquer dos lados.
Future<void> mudarTipoComConfirmacao(
  BuildContext context,
  WidgetRef ref,
  TipoUtilizador destino,
) async {
  final bool paraMotorista = destino == TipoUtilizador.motoqueiro;
  final bool confirmado = await mostrarDialogoConfirmacao(
    context,
    titulo: paraMotorista ? 'Usar como motorista?' : 'Usar como passageiro?',
    mensagem: paraMotorista
        ? 'Para levar passageiros, completa o cadastro. Só começas a '
              'trabalhar depois de aprovado.'
        : 'Passas a pedir viagens. O teu cadastro de motorista fica guardado.',
    rotuloConfirmar: paraMotorista
        ? 'Mudar para motorista'
        : 'Mudar para passageiro',
  );
  if (!confirmado || !context.mounted) {
    return;
  }
  await ref
      .read(controladorAutenticacaoProvider.notifier)
      .escolherTipo(destino);
  final String? erro = ref.read(controladorAutenticacaoProvider).erro;
  if (erro != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
    ref.read(controladorAutenticacaoProvider.notifier).limparErro();
  }
}
