import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/corrida/apresentacao/controladores/controlador_corrida.dart';
import 'package:project_x/funcionalidades/corrida/dominio/corrida.dart';
import 'package:project_x/funcionalidades/inicio/apresentacao/widgets/lista_destinos.dart';
import 'package:project_x/funcionalidades/inicio/dominio/tipo_veiculo.dart';
import 'package:project_x/funcionalidades/localizacao/apresentacao/controladores/controlador_mapa.dart';
import 'package:project_x/funcionalidades/localizacao/apresentacao/controladores/controlador_pesquisa_destino.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/coordenada.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/local.dart';
import 'package:project_x/funcionalidades/voz/apresentacao/controladores/controlador_ditado.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';
import 'package:project_x/nucleo/tema/tema_app.dart';
import 'package:project_x/nucleo/utilitarios/formatadores.dart';
import 'package:project_x/partilhado/widgets/botao_principal.dart';
import 'package:project_x/partilhado/widgets/elementos_rota.dart';
import 'package:project_x/partilhado/widgets/ilustracao_veiculo.dart';

/// Folha em baixo do mapa: escrever ou ditar o destino, ver os resultados,
/// escolher o veículo, pagar e pedir — tudo no mesmo ecrã.
class FolhaPedidoViagem extends ConsumerWidget {
  const FolhaPedidoViagem({
    required this.primeiroNome,
    required this.origemNome,
    required this.distanciaKm,
    required this.referencia,
    required this.campoTexto,
    required this.foco,
    required this.emProcura,
    required this.aoMudarTexto,
    required this.aoDitar,
    required this.aoEscolherDestino,
    required this.aoMarcarNoMapa,
    required this.aoMudarDestino,
    super.key,
  });

  final String? primeiroNome;
  final String origemNome;
  final double? distanciaKm;

  /// Para ordenar os lugares sugeridos pela distância.
  final Coordenada referencia;
  final TextEditingController campoTexto;
  final FocusNode foco;

  /// A pessoa está a escrever ou a ditar o destino: a folha mostra os
  /// resultados em vez dos veículos.
  final bool emProcura;
  final ValueChanged<String> aoMudarTexto;
  final VoidCallback aoDitar;
  final ValueChanged<Local> aoEscolherDestino;
  final VoidCallback aoMarcarNoMapa;
  final VoidCallback aoMudarDestino;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final EstadoMapa mapa = ref.watch(controladorMapaProvider);
    final EstadoCorrida corrida = ref.watch(controladorCorridaProvider);
    final ControladorCorrida controlador = ref.read(
      controladorCorridaProvider.notifier,
    );
    final Local? destino = emProcura ? null : mapa.destino;
    final double? preco = destino == null
        ? null
        : controlador.precoApresentado(
            mapa.precosEstimados,
            corrida.tipoVeiculo,
          );
    final double alturaDisponivel =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      color: cores.surface,
      elevation: 8,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(TemaApp.raio),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (emProcura)
                ..._procura(context, ref, alturaDisponivel)
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: alturaDisponivel * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (destino == null)
                          _CabecalhoPesquisa(
                            primeiroNome: primeiroNome,
                            campo: _CampoDestino(
                              campoTexto: campoTexto,
                              foco: foco,
                              aoMudarTexto: aoMudarTexto,
                              aoDitar: aoDitar,
                            ),
                          )
                        else
                          _LinhaDestino(
                            texto:
                                '$origemNome → ${destino.nome}'
                                '${distanciaKm == null ? '' : ' · ${formatarKm(distanciaKm!)}'}',
                            aoMudar: aoMudarDestino,
                            aoLimpar: corrida.aProcessar
                                ? null
                                : ref
                                      .read(controladorMapaProvider.notifier)
                                      .limparDestino,
                          ),
                        const SizedBox(height: 16),
                        if (destino != null && mapa.erro != null) ...<Widget>[
                          _ErroPrecos(
                            mensagem: mapa.erro!,
                            aoRepetir: ref
                                .read(controladorMapaProvider.notifier)
                                .tentarEstimarDeNovo,
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: <Widget>[
                            for (final TipoVeiculo tipo
                                in veiculosDeViagem) ...<Widget>[
                              Expanded(
                                child: _CartaoVeiculo(
                                  tipo: tipo,
                                  preco: destino == null
                                      ? null
                                      : controlador.precoApresentado(
                                          mapa.precosEstimados,
                                          tipo,
                                        ),
                                  aCalcular:
                                      destino != null && mapa.aCalcularPrecos,
                                  selecionado: tipo == corrida.tipoVeiculo,
                                  aoTocar: () =>
                                      controlador.escolherVeiculo(tipo),
                                ),
                              ),
                              if (tipo != veiculosDeViagem.last)
                                const SizedBox(width: 8),
                            ],
                          ],
                        ),
                        if (destino != null) ...<Widget>[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              for (final FormaPagamento forma
                                  in FormaPagamento.values)
                                ChipOpcao(
                                  texto: forma.nome,
                                  selecionado: forma == corrida.formaPagamento,
                                  aoTocar: () =>
                                      controlador.escolherPagamento(forma),
                                ),
                            ],
                          ),
                          _MaisOpcoes(preco: preco),
                        ],
                      ],
                    ),
                  ),
                ),
              if (destino != null) ...<Widget>[
                const SizedBox(height: 12),
                BotaoPrincipal(
                  texto: preco == null
                      ? 'Pedir ${corrida.tipoVeiculo.nome}'
                      : 'Pedir ${corrida.tipoVeiculo.nome} · '
                            '${formatarMt(preco)}',
                  aCarregar: corrida.aProcessar || mapa.aCalcularPrecos,
                  aoPremir: preco == null
                      ? null
                      : () => controlador.pedir(origemNome: origemNome),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _procura(
    BuildContext context,
    WidgetRef ref,
    double alturaDisponivel,
  ) {
    final EstadoPesquisaDestino pesquisa = ref.watch(
      controladorPesquisaDestinoProvider,
    );
    final EstadoDitado ditado = ref.watch(controladorDitadoProvider);
    final bool comTermo = campoTexto.text.trim().length >= 3;
    final String? erroDitado = ditado.erro;

    return <Widget>[
      _CampoDestino(
        campoTexto: campoTexto,
        foco: foco,
        aoMudarTexto: aoMudarTexto,
        aoDitar: aoDitar,
      ),
      if (ditado.aOuvir || erroDitado != null) ...<Widget>[
        const SizedBox(height: 8),
        _EstadoDitado(
          aOuvir: ditado.aOuvir,
          texto: ditado.aOuvir
              ? (ditado.textoParcial.isEmpty
                    ? 'A ouvir… diz para onde vais.'
                    : '«${ditado.textoParcial}»')
              : erroDitado!,
        ),
      ],
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: aoMarcarNoMapa,
          icon: const Icon(Icons.pin_drop_outlined),
          label: const Text('Marcar no mapa'),
        ),
      ),
      ConstrainedBox(
        constraints: BoxConstraints(maxHeight: alturaDisponivel * 0.45),
        child: SingleChildScrollView(
          child: comTermo
              ? ResultadosPesquisa(
                  estado: pesquisa,
                  aoEscolher: aoEscolherDestino,
                  aoEscolherNoMapa: aoMarcarNoMapa,
                  aoRepetir: () => ref
                      .read(controladorPesquisaDestinoProvider.notifier)
                      .tentarNovamente(perto: referencia),
                )
              : ListaLugares(
                  referencia: referencia,
                  aoEscolher: aoEscolherDestino,
                ),
        ),
      ),
    ];
  }
}

class _CabecalhoPesquisa extends StatelessWidget {
  const _CabecalhoPesquisa({required this.primeiroNome, required this.campo});

  final String? primeiroNome;
  final Widget campo;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TextTheme textos = Theme.of(context).textTheme;
    final String? nome = primeiroNome;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (nome != null && nome.isNotEmpty)
          Text(
            'Olá, $nome',
            style: textos.bodyLarge?.copyWith(color: cores.onSurfaceVariant),
          ),
        Text(
          'Para onde vais?',
          style: textos.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        campo,
      ],
    );
  }
}

/// Caixa de texto do destino, com o microfone para ditar.
class _CampoDestino extends ConsumerWidget {
  const _CampoDestino({
    required this.campoTexto,
    required this.foco,
    required this.aoMudarTexto,
    required this.aoDitar,
  });

  final TextEditingController campoTexto;
  final FocusNode foco;
  final ValueChanged<String> aoMudarTexto;
  final VoidCallback aoDitar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final bool aOuvir = ref.watch(
      controladorDitadoProvider.select((EstadoDitado e) => e.aOuvir),
    );
    return TextField(
      controller: campoTexto,
      focusNode: foco,
      onChanged: aoMudarTexto,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Escreve ou diz o lugar',
        filled: true,
        fillColor: cores.surfaceContainerHighest,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (campoTexto.text.isNotEmpty)
              IconButton(
                tooltip: 'Limpar',
                icon: const Icon(Icons.close),
                onPressed: () {
                  campoTexto.clear();
                  aoMudarTexto('');
                },
              ),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton.filled(
                tooltip: aOuvir ? 'Parar' : 'Dizer o destino',
                style: IconButton.styleFrom(
                  backgroundColor: aOuvir
                      ? CoresApp.destaque
                      : CoresApp.terracota,
                  foregroundColor: aOuvir ? CoresApp.marinho : CoresApp.branco,
                ),
                icon: Icon(aOuvir ? Icons.stop_rounded : Icons.mic_rounded),
                onPressed: aoDitar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoDitado extends StatelessWidget {
  const _EstadoDitado({required this.aOuvir, required this.texto});

  final bool aOuvir;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CoresApp.marinho,
        borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            aOuvir ? Icons.graphic_eq : Icons.info_outline,
            color: CoresApp.destaque,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(color: CoresApp.creme, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinhaDestino extends StatelessWidget {
  const _LinhaDestino({
    required this.texto,
    required this.aoMudar,
    required this.aoLimpar,
  });

  final String texto;
  final VoidCallback aoMudar;
  final VoidCallback? aoLimpar;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TextTheme textos = Theme.of(context).textTheme;
    return Material(
      color: cores.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
      child: InkWell(
        onTap: aoMudar,
        borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
          child: Row(
            children: <Widget>[
              const Icon(Icons.place, color: CoresApp.terracota),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  texto,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textos.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Limpar destino',
                icon: const Icon(Icons.close),
                onPressed: aoLimpar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartaoVeiculo extends StatelessWidget {
  const _CartaoVeiculo({
    required this.tipo,
    required this.preco,
    required this.aCalcular,
    required this.selecionado,
    required this.aoTocar,
  });

  final TipoVeiculo tipo;
  final double? preco;
  final bool aCalcular;
  final bool selecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final TextTheme textos = Theme.of(context).textTheme;
    final double? valor = preco;
    return Material(
      color: selecionado
          ? cores.primaryContainer
          : cores.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TemaApp.raio),
        side: BorderSide(
          color: selecionado ? cores.primary : cores.outlineVariant,
          width: selecionado ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(TemaApp.raio),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
          child: Column(
            children: <Widget>[
              IlustracaoVeiculo(tipo: tipo, tamanho: 40),
              const SizedBox(height: 6),
              Text(
                tipo.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textos.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: selecionado ? cores.onPrimaryContainer : null,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 20,
                child: aCalcular
                    ? const Center(
                        child: SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Text(
                        valor == null ? tipo.capacidade : formatarMt(valor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: valor == null
                            ? textos.bodySmall?.copyWith(
                                color: selecionado
                                    ? cores.onPrimaryContainer
                                    : cores.onSurfaceVariant,
                              )
                            : textos.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: selecionado
                                    ? cores.onPrimaryContainer
                                    : cores.onSurface,
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaisOpcoes extends ConsumerWidget {
  const _MaisOpcoes({required this.preco});

  final double? preco;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EstadoMapa mapa = ref.watch(controladorMapaProvider);
    final EstadoCorrida corrida = ref.watch(controladorCorridaProvider);
    final ControladorCorrida controlador = ref.read(
      controladorCorridaProvider.notifier,
    );
    final ControladorMapa controladorMapa = ref.read(
      controladorMapaProvider.notifier,
    );
    final double? extraCarga = controlador.extraCargaMt;
    final TextTheme textos = Theme.of(context).textTheme;

    return ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text('Mais opções', style: textos.titleSmall),
      children: <Widget>[
        if (controladorMapa.suportaTabelaPorZona) ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: ChipOpcao(
                  texto: 'Tabela por zona',
                  selecionado: mapa.modoPreco == ModoPreco.zona,
                  aoTocar: () => controladorMapa.mudarModoPreco(ModoPreco.zona),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChipOpcao(
                  texto: 'Por quilómetro',
                  selecionado: mapa.modoPreco == ModoPreco.quilometro,
                  aoTocar: () =>
                      controladorMapa.mudarModoPreco(ModoPreco.quilometro),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              mapa.modoPreco == ModoPreco.zona
                  ? 'Preço fixo da tabela que os motoqueiros já usam.'
                  : 'Preço calculado pela distância da viagem.',
              style: textos.bodySmall,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (extraCarga != null) ...<Widget>[
          _LinhaOpcao(
            texto: 'Levo carga do mercado (peixe, sacos)',
            extra: '+${formatarMt(extraCarga)}',
            valor: corrida.comCarga,
            aoMudar: controlador.definirCarga,
          ),
          const SizedBox(height: 8),
        ],
        _LinhaOpcao(
          texto: 'Tenho barco para apanhar no porto',
          valor: corrida.temBarco,
          aoMudar: controlador.definirBarco,
        ),
        if (corrida.formaPagamento == FormaPagamento.dinheiro) ...<Widget>[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text('Pago com nota de', style: textos.labelLarge),
              for (final int nota in notasDePagamento)
                ChipOpcao(
                  texto: '$nota',
                  selecionado: nota == corrida.notaPagamento,
                  corSelecionado: CoresApp.destaque,
                  corTextoSelecionado: CoresApp.marinho,
                  aoTocar: controlador.notaChega(nota, preco)
                      ? () => controlador.escolherNota(nota)
                      : null,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LinhaOpcao extends StatelessWidget {
  const _LinhaOpcao({
    required this.texto,
    required this.valor,
    required this.aoMudar,
    this.extra,
  });

  final String texto;
  final String? extra;
  final bool valor;
  final ValueChanged<bool> aoMudar;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final String? acrescimo = extra;
    return InkWell(
      onTap: () => aoMudar(!valor),
      borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cores.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
          border: Border.all(color: cores.outline),
        ),
        child: Row(
          children: <Widget>[
            Checkbox(
              value: valor,
              onChanged: (bool? novo) => aoMudar(novo ?? false),
            ),
            Expanded(
              child: Text(
                texto,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (acrescimo != null)
              Text(
                acrescimo,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? CoresApp.destaque
                      : CoresApp.terracota,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErroPrecos extends StatelessWidget {
  const _ErroPrecos({required this.mensagem, required this.aoRepetir});

  final String mensagem;
  final VoidCallback aoRepetir;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: cores.errorContainer,
        borderRadius: BorderRadius.circular(TemaApp.raioPequeno),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              mensagem,
              style: TextStyle(color: cores.onErrorContainer),
            ),
          ),
          TextButton(onPressed: aoRepetir, child: const Text('Repetir')),
        ],
      ),
    );
  }
}
