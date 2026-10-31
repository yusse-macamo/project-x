import 'package:flutter/material.dart';

import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/nucleo/tema/tema_app.dart';

class CampoSelecao<T> extends StatelessWidget {
  const CampoSelecao({
    required this.rotulo,
    required this.opcoes,
    required this.valor,
    required this.aoSelecionar,
    this.rotuloOpcao,
    this.dica,
    super.key,
  });

  final String rotulo;
  final List<T> opcoes;
  final T? valor;
  final ValueChanged<T> aoSelecionar;
  final String Function(T)? rotuloOpcao;
  final String? dica;

  String _textoOpcao(T opcao) => rotuloOpcao?.call(opcao) ?? opcao.toString();

  Future<void> _abrirFolha(BuildContext context) async {
    final T? escolhido = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: opcoes.length,
            itemBuilder: (BuildContext context, int indice) {
              final T opcao = opcoes[indice];
              final bool selecionada = opcao == valor;
              return ListTile(
                title: Text(_textoOpcao(opcao)),
                trailing: selecionada
                    ? const Icon(Icons.check, color: CoresApp.primaria)
                    : null,
                onTap: () => Navigator.of(context).pop(opcao),
              );
            },
          ),
        );
      },
    );
    if (escolhido != null) {
      aoSelecionar(escolhido);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final T? valorAtual = valor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(rotulo, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
          onTap: () => _abrirFolha(context),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: dica,
              suffixIcon: Icon(Icons.expand_more, color: cores.onSurfaceVariant),
            ),
            isEmpty: valorAtual == null,
            child: valorAtual == null ? null : Text(_textoOpcao(valorAtual)),
          ),
        ),
      ],
    );
  }
}
