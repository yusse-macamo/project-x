abstract final class Validadores {
  static const String indicativo = '+258';

  static bool telefoneValido(String telefone) {
    final String digitos = apenasDigitos(telefone);
    if (digitos.length != 9) {
      return false;
    }
    final int prefixo = int.parse(digitos.substring(0, 2));
    return prefixo >= 82 && prefixo <= 87;
  }

  static String? validarTelefone(String? valor, {String? telefoneProprio}) {
    final String digitos = apenasDigitos(valor ?? '');
    if (digitos.isEmpty) {
      return 'Introduza o número de telemóvel.';
    }
    if (digitos.length < 9) {
      return 'Número incompleto.';
    }
    if (digitos.length > 9 || !telefoneValido(digitos)) {
      return 'Número inválido.';
    }
    if (telefoneProprio != null &&
        digitos == apenasDigitos(telefoneProprio)) {
      return 'Tem de ser diferente do seu número.';
    }
    return null;
  }

  static String? validarNome(String? valor) {
    final String nome = valor?.trim() ?? '';
    if (nome.length < 3 || !nome.contains(' ')) {
      return 'Introduza o nome completo.';
    }
    return null;
  }

  static String? validarNumeroBi(String? valor) {
    final String texto = valor?.trim() ?? '';
    if (texto.isEmpty) {
      return 'Introduza o número do BI.';
    }
    if (!RegExp(r'^\d{12}[A-Z]$').hasMatch(texto)) {
      return 'Número de BI inválido.';
    }
    return null;
  }

  static String normalizarMatricula(String valor) {
    return valor.toUpperCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String? validarMatricula(String? valor) {
    final String texto = normalizarMatricula(valor ?? '');
    if (texto.isEmpty) {
      return 'Introduza a matrícula.';
    }
    if (!RegExp(r'^[A-Z]{3} \d{3} [A-Z]{2}$').hasMatch(texto)) {
      return 'Matrícula inválida.';
    }
    return null;
  }

  static String apenasDigitos(String valor) {
    return valor.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static String formatarTelefone(String telefone) {
    final String digitos = apenasDigitos(telefone);
    if (digitos.length != 9) {
      return telefone;
    }
    final String parte1 = digitos.substring(0, 2);
    final String parte2 = digitos.substring(2, 5);
    final String parte3 = digitos.substring(5, 9);
    return '$indicativo $parte1 $parte2 $parte3';
  }
}
