import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:project_x/nucleo/tema/cores_app.dart';

class CampoCodigo extends StatefulWidget {
  const CampoCodigo({required this.aoCompletar, this.ativo = true, super.key});

  final ValueChanged<String> aoCompletar;
  final bool ativo;

  static const int comprimento = 6;

  @override
  State<CampoCodigo> createState() => _CampoCodigoState();
}

class _CampoCodigoState extends State<CampoCodigo> {
  final TextEditingController _controlador = TextEditingController();
  final FocusNode _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    _foco.addListener(() => setState(() {}));
    if (widget.ativo) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) {
          _foco.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _aoMudar(String valor) {
    setState(() {});
    if (valor.length == CampoCodigo.comprimento) {
      _foco.unfocus();
      widget.aoCompletar(valor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final String codigo = _controlador.text;

    return GestureDetector(
      onTap: widget.ativo ? () => _foco.requestFocus() : null,
      child: SizedBox(
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List<Widget>.generate(CampoCodigo.comprimento, (
                int indice,
              ) {
                final String caracter = indice < codigo.length
                    ? codigo[indice]
                    : '';
                final bool preenchida = caracter.isNotEmpty;
                final bool ativa = _foco.hasFocus && indice == codigo.length;
                final bool destacada = preenchida || ativa;

                return Container(
                  width: 44,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: destacada ? CoresApp.primaria : cores.outline,
                      width: destacada ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    caracter,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                );
              }),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _controlador,
                  focusNode: _foco,
                  enabled: widget.ativo,
                  keyboardType: TextInputType.number,
                  maxLength: CampoCodigo.comprimento,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                  ),
                  onChanged: _aoMudar,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
