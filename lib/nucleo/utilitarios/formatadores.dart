import 'package:flutter/services.dart';

String formatarMt(double valor) => '${valor.round()} MT';

class FormatadorCapitalizacaoPalavras extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue valorAntigo,
    TextEditingValue novoValor,
  ) {
    final String capitalizado = novoValor.text
        .split(' ')
        .map(
          (String palavra) => palavra.isEmpty
              ? palavra
              : palavra[0].toUpperCase() + palavra.substring(1),
        )
        .join(' ');
    return novoValor.copyWith(text: capitalizado);
  }
}

class FormatadorMaiusculas extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue valorAntigo,
    TextEditingValue novoValor,
  ) {
    return novoValor.copyWith(text: novoValor.text.toUpperCase());
  }
}
