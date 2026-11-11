class CreditoImagem {
  const CreditoImagem({
    required this.titulo,
    required this.autor,
    required this.licenca,
    required this.origem,
  });

  final String titulo;
  final String autor;
  final String licenca;
  final String origem;
}

/// As fotografias dos veículos foram recortadas e reduzidas; continuam sob a
/// mesma licença (CC BY-SA 4.0), que obriga a mostrar estes créditos na app.
const List<CreditoImagem> creditosImagens = <CreditoImagem>[
  CreditoImagem(
    titulo: 'Mota (Honda CG125)',
    autor: 'SEDJRO SETONDJI',
    licenca: 'CC BY-SA 4.0',
    origem: 'commons.wikimedia.org/wiki/File:Honda_CG125.jpg',
  ),
  CreditoImagem(
    titulo: 'Txopela em Moçambique',
    autor: 'Edward Middleton',
    licenca: 'CC BY-SA 4.0',
    origem: 'commons.wikimedia.org/wiki/File:Mozambique_155.jpg',
  ),
  CreditoImagem(
    titulo: 'Táxi (Toyota Corolla)',
    autor: 'LuvsMG481',
    licenca: 'CC BY-SA 4.0',
    origem:
        'commons.wikimedia.org/wiki/'
        'File:Swan_Taxis_Toyota_Corolla_Ascent_Sport_Hybrid.jpg',
  ),
];

const String textoLicencaCcBySa =
    'Imagens recortadas e reduzidas a partir dos originais. Licença: '
    'creativecommons.org/licenses/by-sa/4.0';
