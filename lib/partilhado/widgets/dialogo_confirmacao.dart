import 'package:flutter/material.dart';

/// Pergunta antes de uma ação que não se desfaz com um toque. Devolve `true`
/// só se o utilizador confirmar; fechar o diálogo conta como cancelar.
Future<bool> mostrarDialogoConfirmacao(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  required String rotuloConfirmar,
  String rotuloCancelar = 'Cancelar',
}) async {
  final bool? confirmado = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(rotuloCancelar),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(rotuloConfirmar),
          ),
        ],
      );
    },
  );
  return confirmado ?? false;
}

Future<bool> confirmarTerminarSessao(BuildContext context) {
  return mostrarDialogoConfirmacao(
    context,
    titulo: 'Terminar sessão?',
    mensagem:
        'Para voltar a entrar, vais precisar de um novo código enviado '
        'para o teu número.',
    rotuloConfirmar: 'Terminar sessão',
  );
}
