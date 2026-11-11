import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/funcionalidades/autenticacao/apresentacao/ecras/ecra_completar_perfil.dart';
import 'package:project_x/funcionalidades/autenticacao/apresentacao/ecras/ecra_escolher_tipo.dart';
import 'package:project_x/funcionalidades/autenticacao/apresentacao/ecras/ecra_login_telefone.dart';
import 'package:project_x/funcionalidades/autenticacao/apresentacao/ecras/ecra_splash.dart';
import 'package:project_x/funcionalidades/autenticacao/apresentacao/ecras/ecra_verificacao_otp.dart';
import 'package:project_x/funcionalidades/autenticacao/dominio/utilizador.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/controladores/controlador_cadastro.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/ecras/ecra_aguarda_aprovacao.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/ecras/ecra_cadastro_a_carregar.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/ecras/ecra_cadastro_motorista.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/ecras/ecra_painel_motoqueiro.dart';
import 'package:project_x/funcionalidades/capulana/apresentacao/ecras/ecra_escolher_capulana.dart';
import 'package:project_x/funcionalidades/corrida/apresentacao/controladores/controlador_corrida.dart';
import 'package:project_x/funcionalidades/corrida/apresentacao/controladores/controlador_pedidos_motoqueiro.dart';
import 'package:project_x/funcionalidades/corrida/apresentacao/ecras/ecra_avaliar_corrida.dart';
import 'package:project_x/funcionalidades/corrida/apresentacao/ecras/ecra_corrida_motoqueiro.dart';
import 'package:project_x/funcionalidades/corrida/apresentacao/ecras/ecra_em_viagem.dart';
import 'package:project_x/funcionalidades/corrida/apresentacao/ecras/ecra_motoqueiro_a_caminho.dart';
import 'package:project_x/funcionalidades/corrida/apresentacao/ecras/ecra_pedido_motoqueiro.dart';
import 'package:project_x/funcionalidades/corrida/apresentacao/ecras/ecra_sinal.dart';
import 'package:project_x/funcionalidades/inicio/apresentacao/ecras/ecra_ajustar_ponto.dart';
import 'package:project_x/funcionalidades/inicio/apresentacao/ecras/ecra_creditos_imagens.dart';
import 'package:project_x/funcionalidades/inicio/apresentacao/ecras/ecra_mapa_inicio.dart';
import 'package:project_x/funcionalidades/inicio/apresentacao/ecras/ecra_paragens.dart';
import 'package:project_x/funcionalidades/inicio/apresentacao/ecras/ecra_perfil.dart';
import 'package:project_x/funcionalidades/inicio/apresentacao/ecras/ecra_permissao_localizacao.dart';
import 'package:project_x/funcionalidades/inicio/apresentacao/ecras/ecra_pesquisa_destino.dart';
import 'package:project_x/funcionalidades/inicio/apresentacao/ecras/ecra_viagens.dart';
import 'package:project_x/funcionalidades/inicio/dominio/tipo_veiculo.dart';
import 'package:project_x/funcionalidades/localizacao/apresentacao/controladores/controlador_mapa.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/estado_permissao_localizacao.dart';
import 'package:project_x/funcionalidades/paragens/apresentacao/ecras/ecra_gravar_paragem.dart';

abstract final class Rotas {
  static const String splash = '/';
  static const String login = '/entrar';
  static const String verificacao = '/verificacao';
  static const String completarPerfil = '/perfil';
  static const String escolherTipo = '/tipo';
  static const String inicio = '/inicio';
  static const String permissaoLocalizacao = '/permissao-localizacao';
  static const String pesquisaDestino = '/pesquisa-destino';
  static const String ajustarPonto = '/ajustar-ponto';
  static const String cadastroACarregar = '/cadastro';
  static const String cadastroMota = '/cadastro/mota';
  static const String cadastroTxopela = '/cadastro/txopela';
  static const String cadastroTaxi = '/cadastro/taxi';
  static const String cadastroAprovacao = '/cadastro/aprovacao';
  static const String motoqueiro = '/motoqueiro';
  static const String pedidoMotoqueiro = '/motoqueiro/pedido';
  static const String corridaMotoqueiro = '/motoqueiro/corrida';
  static const String motoqueiroACaminho = '/corrida/a-caminho';
  static const String emViagem = '/corrida/em-viagem';
  static const String avaliarCorrida = '/corrida/avaliar';
  static const String sinal = '/corrida/sinal';
  static const String capulana = '/capulana';
  static const String gravarParagem = '/paragem/gravar';
  static const String perfilPassageiro = '/conta/perfil';
  static const String viagens = '/conta/viagens';
  static const String paragens = '/conta/paragens';
  static const String creditosImagens = '/conta/creditos-imagens';

  static const Set<String> rotasEmpilhadas = <String>{
    pesquisaDestino,
    ajustarPonto,
    sinal,
    capulana,
    gravarParagem,
    perfilPassageiro,
    viagens,
    paragens,
    creditosImagens,
  };
}

class _NotificadorNavegacao extends ChangeNotifier {
  _NotificadorNavegacao(Ref ref) {
    _faseAutenticacao = ref.read(controladorAutenticacaoProvider).fase;
    _tipoUtilizador = ref
        .read(controladorAutenticacaoProvider)
        .utilizador
        ?.tipo;
    _faseCadastro = ref.read(controladorCadastroProvider).fase;
    final EstadoMapa estadoMapaInicial = ref.read(controladorMapaProvider);
    _permissaoLocalizacao = estadoMapaInicial.permissao;
    _podeContinuarSemPosicao = estadoMapaInicial.podeContinuarSemPosicao;
    _temDestino = estadoMapaInicial.destino != null;
    _faseCorrida = ref.read(controladorCorridaProvider).fase;
    _faseMotoqueiro = ref.read(controladorPedidosMotoqueiroProvider).fase;
    ref.listen<EstadoCorrida>(controladorCorridaProvider, (
      EstadoCorrida? anterior,
      EstadoCorrida atual,
    ) {
      if (atual.fase != _faseCorrida) {
        _faseCorrida = atual.fase;
        notifyListeners();
      }
    });
    ref.listen<EstadoPedidosMotoqueiro>(controladorPedidosMotoqueiroProvider, (
      EstadoPedidosMotoqueiro? anterior,
      EstadoPedidosMotoqueiro atual,
    ) {
      if (atual.fase != _faseMotoqueiro) {
        _faseMotoqueiro = atual.fase;
        notifyListeners();
      }
    });
    ref.listen<EstadoAutenticacao>(controladorAutenticacaoProvider, (
      EstadoAutenticacao? anterior,
      EstadoAutenticacao atual,
    ) {
      if (atual.fase != _faseAutenticacao ||
          atual.utilizador?.tipo != _tipoUtilizador) {
        _faseAutenticacao = atual.fase;
        _tipoUtilizador = atual.utilizador?.tipo;
        notifyListeners();
      }
    });
    ref.listen<EstadoCadastro>(controladorCadastroProvider, (
      EstadoCadastro? anterior,
      EstadoCadastro atual,
    ) {
      if (atual.fase != _faseCadastro ||
          atual.aprovacaoConfirmada != _aprovacaoConfirmada ||
          atual.tipoVeiculoAtual != _tipoVeiculoCadastro) {
        _faseCadastro = atual.fase;
        _aprovacaoConfirmada = atual.aprovacaoConfirmada;
        _tipoVeiculoCadastro = atual.tipoVeiculoAtual;
        notifyListeners();
      }
    });
    ref.listen<EstadoMapa>(controladorMapaProvider, (
      EstadoMapa? anterior,
      EstadoMapa atual,
    ) {
      final bool temDestino = atual.destino != null;
      if (atual.permissao != _permissaoLocalizacao ||
          atual.podeContinuarSemPosicao != _podeContinuarSemPosicao ||
          temDestino != _temDestino) {
        _permissaoLocalizacao = atual.permissao;
        _podeContinuarSemPosicao = atual.podeContinuarSemPosicao;
        _temDestino = temDestino;
        notifyListeners();
      }
    });
  }

  late FaseAutenticacao _faseAutenticacao;
  TipoUtilizador? _tipoUtilizador;
  late FaseCadastro _faseCadastro;
  bool _aprovacaoConfirmada = false;
  TipoVeiculo? _tipoVeiculoCadastro;
  late EstadoPermissaoLocalizacao _permissaoLocalizacao;
  bool _podeContinuarSemPosicao = false;
  bool _temDestino = false;
  late FaseCorrida _faseCorrida;
  late FaseMotoqueiro _faseMotoqueiro;
}

final Provider<GoRouter> roteadorProvider = Provider<GoRouter>((Ref ref) {
  final _NotificadorNavegacao notificador = _NotificadorNavegacao(ref);
  ref.onDispose(notificador.dispose);

  String destinoParaMotoqueiro() {
    final EstadoCadastro estadoCadastro = ref.read(controladorCadastroProvider);
    final String? formulario = switch (estadoCadastro.tipoVeiculoAtual) {
      TipoVeiculo.mota => Rotas.cadastroMota,
      TipoVeiculo.txopela => Rotas.cadastroTxopela,
      TipoVeiculo.carro => Rotas.cadastroTaxi,
      TipoVeiculo.camioneta || null => null,
    };
    return switch (estadoCadastro.fase) {
      FaseCadastro.inicial => formulario ?? Rotas.cadastroACarregar,
      // Sem cadastro guardado e sem tipo escolhido: volta à escolha.
      FaseCadastro.formulario => formulario ?? Rotas.escolherTipo,
      FaseCadastro.pendente => Rotas.cadastroAprovacao,
      FaseCadastro.rejeitado => Rotas.cadastroAprovacao,
      FaseCadastro.aprovado =>
        estadoCadastro.aprovacaoConfirmada
            ? switch (ref.read(controladorPedidosMotoqueiroProvider).fase) {
                FaseMotoqueiro.livre => Rotas.motoqueiro,
                FaseMotoqueiro.pedidoRecebido => Rotas.pedidoMotoqueiro,
                FaseMotoqueiro.aCaminhoDaRecolha ||
                FaseMotoqueiro.emViagem => Rotas.corridaMotoqueiro,
              }
            : Rotas.cadastroAprovacao,
    };
  }

  String destinoParaPassageiro() {
    final EstadoMapa estadoMapa = ref.read(controladorMapaProvider);
    final bool podeVerMapa =
        estadoMapa.permissao == EstadoPermissaoLocalizacao.concedida ||
        estadoMapa.podeContinuarSemPosicao;
    if (!podeVerMapa) {
      return Rotas.permissaoLocalizacao;
    }
    return switch (ref.read(controladorCorridaProvider).fase) {
      FaseCorrida.motoqueiroACaminho => Rotas.motoqueiroACaminho,
      FaseCorrida.emViagem => Rotas.emViagem,
      FaseCorrida.avaliacao => Rotas.avaliarCorrida,
      FaseCorrida.semCorrida => Rotas.inicio,
    };
  }

  String destinoAutenticado(Utilizador? utilizador) {
    if (utilizador?.tipo != TipoUtilizador.motoqueiro) {
      return destinoParaPassageiro();
    }
    return destinoParaMotoqueiro();
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final EstadoAutenticacao estadoAuth = ref.read(
      controladorAutenticacaoProvider,
    );
    if (estadoAuth.fase == FaseAutenticacao.autenticado &&
        Rotas.rotasEmpilhadas.contains(state.matchedLocation)) {
      return null;
    }
    final String destino = switch (estadoAuth.fase) {
      FaseAutenticacao.inicial => Rotas.splash,
      FaseAutenticacao.semSessao => Rotas.login,
      FaseAutenticacao.aguardaCodigo => Rotas.verificacao,
      FaseAutenticacao.escolherTipo => Rotas.escolherTipo,
      FaseAutenticacao.perfilIncompleto => Rotas.completarPerfil,
      FaseAutenticacao.autenticado => destinoAutenticado(estadoAuth.utilizador),
    };
    return state.matchedLocation == destino ? null : destino;
  }

  return GoRouter(
    initialLocation: Rotas.splash,
    refreshListenable: notificador,
    redirect: redirect,
    routes: <RouteBase>[
      GoRoute(
        path: Rotas.splash,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraSplash(),
      ),
      GoRoute(
        path: Rotas.login,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraLoginTelefone(),
      ),
      GoRoute(
        path: Rotas.verificacao,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraVerificacaoOtp(),
      ),
      GoRoute(
        path: Rotas.escolherTipo,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraEscolherTipo(),
      ),
      GoRoute(
        path: Rotas.completarPerfil,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraCompletarPerfil(),
      ),
      GoRoute(
        path: Rotas.inicio,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraMapaInicio(),
      ),
      GoRoute(
        path: Rotas.permissaoLocalizacao,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraPermissaoLocalizacao(),
      ),
      GoRoute(
        path: Rotas.pesquisaDestino,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraPesquisaDestino(),
      ),
      GoRoute(
        path: Rotas.ajustarPonto,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraAjustarPonto(),
      ),
      GoRoute(
        path: Rotas.cadastroACarregar,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraCadastroACarregar(),
      ),
      GoRoute(
        path: Rotas.cadastroMota,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraCadastroMotorista(tipo: TipoVeiculo.mota),
      ),
      GoRoute(
        path: Rotas.cadastroTxopela,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraCadastroMotorista(tipo: TipoVeiculo.txopela),
      ),
      GoRoute(
        path: Rotas.cadastroTaxi,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraCadastroMotorista(tipo: TipoVeiculo.carro),
      ),
      GoRoute(
        path: Rotas.cadastroAprovacao,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraAguardaAprovacao(),
      ),
      GoRoute(
        path: Rotas.motoqueiro,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraPainelMotoqueiro(),
      ),
      GoRoute(
        path: Rotas.pedidoMotoqueiro,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraPedidoMotoqueiro(),
      ),
      GoRoute(
        path: Rotas.corridaMotoqueiro,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraCorridaMotoqueiro(),
      ),
      GoRoute(
        path: Rotas.motoqueiroACaminho,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraMotoqueiroACaminho(),
      ),
      GoRoute(
        path: Rotas.emViagem,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraEmViagem(),
      ),
      GoRoute(
        path: Rotas.avaliarCorrida,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraAvaliarCorrida(),
      ),
      GoRoute(
        path: Rotas.sinal,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraSinal(),
      ),
      GoRoute(
        path: Rotas.capulana,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraEscolherCapulana(),
      ),
      GoRoute(
        path: Rotas.gravarParagem,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraGravarParagem(),
      ),
      GoRoute(
        path: Rotas.perfilPassageiro,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraPerfil(),
      ),
      GoRoute(
        path: Rotas.viagens,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraViagens(),
      ),
      GoRoute(
        path: Rotas.paragens,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraParagens(),
      ),
      GoRoute(
        path: Rotas.creditosImagens,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraCreditosImagens(),
      ),
    ],
  );
});
