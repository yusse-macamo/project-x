import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/corrida/apresentacao/controladores/controlador_pedidos_motoqueiro.dart';
import 'package:project_x/funcionalidades/corrida/dominio/corrida.dart';
import 'package:project_x/nucleo/utilitarios/formatadores.dart';
import 'package:project_x/partilhado/widgets/botao_principal.dart';
import 'package:project_x/partilhado/widgets/elementos_rota.dart';
import 'package:project_x/partilhado/widgets/fundo_capulana.dart';

class EcraCorridaMotoqueiro extends ConsumerStatefulWidget {
  const EcraCorridaMotoqueiro({super.key});

  @override
  ConsumerState<EcraCorridaMotoqueiro> createState() =>
      _EcraCorridaMotoqueiroState();
}

class _EcraCorridaMotoqueiroState extends ConsumerState<EcraCorridaMotoqueiro> {
  final TextEditingController _codigo = TextEditingController();

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      controladorPedidosMotoqueiroProvider.select(
        (EstadoPedidosMotoqueiro e) => e.erro,
      ),
      (String? anterior, String? erro) {
        if (erro != null) {
          mostrarAviso(context, erro);
        }
      },
    );

    final EstadoPedidosMotoqueiro estado = ref.watch(
      controladorPedidosMotoqueiroProvider,
    );
    final ControladorPedidosMotoqueiro controlador = ref.read(
      controladorPedidosMotoqueiroProvider.notifier,
    );
    final PedidoParaMotoqueiro? pedido = estado.pedido;
    if (pedido == null) {
      return const Scaffold();
    }
    final bool emViagem = estado.fase == FaseMotoqueiro.emViagem;
    final TextTheme textos = Theme.of(context).textTheme;
    final String? codigoDeTeste = controlador.codigoDeTeste;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                emViagem ? 'A CAMINHO DO DESTINO' : 'VAI BUSCAR',
                style: textos.headlineSmall,
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 100,
                  child: FundoCapulana(padrao: pedido.capulanaPassageiro),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emViagem ? pedido.destinoNome : pedido.origemNome,
                style: textos.titleLarge,
              ),
              Text(
                '${pedido.passageiroNome} · ${formatarMt(pedido.preco)} · '
                '${formatarKm(pedido.distanciaKm)}',
              ),
              const SizedBox(height: 32),
              if (emViagem)
                BotaoPrincipal(
                  texto: 'Terminar corrida',
                  aCarregar: estado.aProcessar,
                  aoPremir: controlador.terminar,
                )
              else ...<Widget>[
                if (codigoDeTeste != null) ...<Widget>[
                  FaixaModoTeste(
                    mensagem: 'Modo de teste: o código é $codigoDeTeste.',
                  ),
                  const SizedBox(height: 12),
                ],
                Text('Código do passageiro', style: textos.labelLarge),
                const SizedBox(height: 8),
                TextField(
                  controller: _codigo,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: textos.headlineSmall,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(hintText: '0000'),
                ),
                const SizedBox(height: 16),
                BotaoPrincipal(
                  texto: 'Iniciar corrida',
                  aCarregar: estado.aProcessar,
                  aoPremir: () => controlador.iniciar(_codigo.text),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
