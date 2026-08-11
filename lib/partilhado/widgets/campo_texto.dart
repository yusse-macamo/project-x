import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CampoTexto extends StatefulWidget {
  const CampoTexto({
    required this.rotulo,
    this.controlador,
    this.dica,
    this.prefixo,
    this.validador,
    this.formatadores,
    this.aoMudar,
    this.aoPerderFoco,
    this.autoFoco = false,
    this.teclado,
    this.estilo,
    super.key,
  });

  final String rotulo;
  final TextEditingController? controlador;
  final String? dica;
  final String? prefixo;
  final String? Function(String?)? validador;
  final List<TextInputFormatter>? formatadores;
  final ValueChanged<String>? aoMudar;
  final ValueChanged<String>? aoPerderFoco;
  final bool autoFoco;
  final TextInputType? teclado;
  final TextStyle? estilo;

  @override
  State<CampoTexto> createState() => _CampoTextoState();
}

class _CampoTextoState extends State<CampoTexto> {
  final GlobalKey<FormFieldState<String>> _chave =
      GlobalKey<FormFieldState<String>>();
  final FocusNode _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    _foco.addListener(_aoMudarFoco);
  }

  @override
  void dispose() {
    _foco.removeListener(_aoMudarFoco);
    _foco.dispose();
    super.dispose();
  }

  void _aoMudarFoco() {
    if (_foco.hasFocus) {
      return;
    }
    widget.aoPerderFoco?.call(widget.controlador?.text ?? '');
    if (widget.validador != null) {
      _chave.currentState?.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(widget.rotulo, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextFormField(
          key: _chave,
          controller: widget.controlador,
          focusNode: _foco,
          autofocus: widget.autoFoco,
          keyboardType: widget.teclado,
          inputFormatters: widget.formatadores,
          validator: widget.validador,
          onChanged: widget.aoMudar,
          style: widget.estilo,
          decoration: InputDecoration(
            hintText: widget.dica,
            prefixText: widget.prefixo,
            counterText: '',
          ),
        ),
      ],
    );
  }
}
