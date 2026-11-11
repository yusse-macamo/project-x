enum TipoVeiculo {
  camioneta,
  txopela,
  mota,
  carro;

  String get nome => switch (this) {
    TipoVeiculo.camioneta => 'Camioneta',
    TipoVeiculo.txopela => 'Txopela',
    TipoVeiculo.mota => 'Mota',
    TipoVeiculo.carro => 'Táxi',
  };

  String get capacidade => switch (this) {
    TipoVeiculo.camioneta => 'cargas',
    TipoVeiculo.txopela => 'até 3 · leva carga',
    TipoVeiculo.mota => '1 pessoa',
    TipoVeiculo.carro => 'até 4',
  };
}

/// Os veículos que o passageiro pode escolher. A camioneta fica no domínio e
/// na base de dados para o futuro transporte de mercadorias.
const List<TipoVeiculo> veiculosDeViagem = <TipoVeiculo>[
  TipoVeiculo.mota,
  TipoVeiculo.txopela,
  TipoVeiculo.carro,
];

enum ModoPreco { zona, quilometro }
