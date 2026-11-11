import 'package:flutter/services.dart';

String formatarMt(double valor) => '${valor.round()} MT';

String formatarKm(double km) =>
    '${km.toStringAsFixed(1).replaceAll('.', ',')} km';

String formatarDistancia(double metros) =>
    metros < 1000 ? '${metros.round()} m' : formatarKm(metros / 1000);

String formatarHora(DateTime momento) =>
    '${momento.hour.toString().padLeft(2, '0')}:'
    '${momento.minute.toString().padLeft(2, '0')}';

String formatarDuracao(int segundos) =>
    '${segundos ~/ 60}:${(segundos % 60).toString().padLeft(2, '0')}';

String formatarAvaliacao(double nota) =>
    nota.toStringAsFixed(1).replaceAll('.', ',');

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
