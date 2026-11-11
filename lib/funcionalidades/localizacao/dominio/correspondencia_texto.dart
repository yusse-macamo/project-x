/// Comparação tolerante entre o que a pessoa diz ou escreve e os nomes dos
/// lugares: sem acentos, sem maiúsculas, palavra a palavra.
library;

const Map<String, String> _semAcento = <String, String>{
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
};

/// Palavras que não ajudam a identificar o lugar.
const Set<String> _palavrasVazias = <String>{
  'a',
  'o',
  'as',
  'os',
  'ao',
  'aos',
  'da',
  'do',
  'das',
  'dos',
  'de',
  'na',
  'no',
  'nas',
  'nos',
  'em',
  'para',
  'pra',
  'pro',
  'perto',
  'ate',
  'e',
  'um',
  'uma',
  'me',
  'eu',
  'quero',
  'queria',
  'ir',
  'vou',
  'vamos',
  'leva',
  'levar',
  'leve',
  'levame',
  'por',
  'favor',
  'se',
  'faz',
  'fazes',
  'ali',
  'la',
};

/// Expressões típicas de um pedido falado, retiradas antes de pesquisar:
/// "quero ir ao mercado municipal" → "mercado municipal".
final List<RegExp> _inicioDePedido = <RegExp>[
  RegExp(r'^(eu )?(quero|queria|preciso de) (ir|chegar) (ate |para |pra )?'),
  RegExp(r'^(me )?leva(-me| me)? (ate |para |pra )?'),
  RegExp(r'^(vou|vamos) (ate |para |pra )?'),
  RegExp(r'^(para|pra|ate) '),
];

String normalizarTexto(String texto) {
  final StringBuffer saida = StringBuffer();
  for (final String letra in texto.toLowerCase().split('')) {
    saida.write(_semAcento[letra] ?? letra);
  }
  return saida
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// O nome do lugar dentro de uma frase falada, sem "quero ir ao…".
String extrairDestino(String frase) {
  String texto = normalizarTexto(frase);
  for (final RegExp padrao in _inicioDePedido) {
    texto = texto.replaceFirst(padrao, '');
  }
  return texto.replaceFirst(RegExp(r'^(o|a|os|as|ao|aos) '), '').trim();
}

List<String> palavrasSignificativas(String texto) => normalizarTexto(texto)
    .split(' ')
    .where((String p) => p.length >= 3 && !_palavrasVazias.contains(p))
    .toList();

/// Quantas palavras do [termo] aparecem no [texto]. 0 = nada em comum.
int pontuarCorrespondencia(String termo, String texto) {
  final String alvo = normalizarTexto(texto);
  return palavrasSignificativas(
    termo,
  ).where((String palavra) => alvo.contains(palavra)).length;
}
