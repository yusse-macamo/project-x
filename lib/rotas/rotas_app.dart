import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/funcionalidades/autenticacao/apresentacao/ecras/ecra_completar_perfil.dart';
import 'package:project_x/funcionalidades/autenticacao/apresentacao/ecras/ecra_login_telefone.dart';
import 'package:project_x/funcionalidades/autenticacao/apresentacao/ecras/ecra_splash.dart';
import 'package:project_x/funcionalidades/autenticacao/apresentacao/ecras/ecra_verificacao_otp.dart';
import 'package:project_x/funcionalidades/autenticacao/dominio/utilizador.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/controladores/controlador_cadastro.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/ecras/ecra_aguarda_aprovacao.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/ecras/ecra_cadastro_passo_dados.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/ecras/ecra_cadastro_passo_documentos.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/ecras/ecra_cadastro_passo_mota.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/apresentacao/ecras/ecra_painel_motoqueiro.dart';
import 'package:project_x/funcionalidades/inicio/apresentacao/ecras/ecra_ajustar_ponto.dart';
import 'package:project_x/funcionalidades/inicio/apresentacao/ecras/ecra_mapa_inicio.dart';
import 'package:project_x/funcionalidades/inicio/apresentacao/ecras/ecra_permissao_localizacao.dart';
import 'package:project_x/funcionalidades/inicio/apresentacao/ecras/ecra_pesquisa_destino.dart';
import 'package:project_x/funcionalidades/localizacao/apresentacao/controladores/controlador_mapa.dart';
import 'package:project_x/funcionalidades/localizacao/dominio/estado_permissao_localizacao.dart';

abstract final class Rotas {
  static const String splash = '/';
  static const String login = '/entrar';
  static const String verificacao = '/verificacao';
  static const String completarPerfil = '/perfil';
  static const String inicio = '/inicio';
  static const String permissaoLocalizacao = '/permissao-localizacao';
  static const String pesquisaDestino = '/pesquisa-destino';
  static const String ajustarPonto = '/ajustar-ponto';
  static const String cadastroDados = '/cadastro/dados';
  static const String cadastroMota = '/cadastro/mota';
  static const String cadastroDocumentos = '/cadastro/documentos';
  static const String cadastroAprovacao = '/cadastro/aprovacao';
  static const String motoqueiro = '/motoqueiro';

  static const Set<String> rotasEmpilhadas = <String>{
    pesquisaDestino,
    ajustarPonto,
  };
}

class _NotificadorNavegacao extends ChangeNotifier {
  _NotificadorNavegacao(Ref ref) {
    _faseAutenticacao = ref.read(controladorAutenticacaoProvider).fase;
    _faseCadastro = ref.read(controladorCadastroProvider).fase;
    final EstadoMapa estadoMapaInicial = ref.read(controladorMapaProvider);
    _permissaoLocalizacao = estadoMapaInicial.permissao;
    _podeContinuarSemPosicao = estadoMapaInicial.podeContinuarSemPosicao;
    ref.listen<EstadoAutenticacao>(
      controladorAutenticacaoProvider,
      (EstadoAutenticacao? anterior, EstadoAutenticacao atual) {
        if (atual.fase != _faseAutenticacao) {
          _faseAutenticacao = atual.fase;
          notifyListeners();
        }
      },
    );
    ref.listen<EstadoCadastro>(
      controladorCadastroProvider,
      (EstadoCadastro? anterior, EstadoCadastro atual) {
        if (atual.fase != _faseCadastro ||
            atual.aprovacaoConfirmada != _aprovacaoConfirmada) {
          _faseCadastro = atual.fase;
          _aprovacaoConfirmada = atual.aprovacaoConfirmada;
          notifyListeners();
        }
      },
    );
    ref.listen<EstadoMapa>(controladorMapaProvider, (
      EstadoMapa? anterior,
      EstadoMapa atual,
    ) {
      if (atual.permissao != _permissaoLocalizacao ||
          atual.podeContinuarSemPosicao != _podeContinuarSemPosicao) {
        _permissaoLocalizacao = atual.permissao;
        _podeContinuarSemPosicao = atual.podeContinuarSemPosicao;
        notifyListeners();
      }
    });
  }

  late FaseAutenticacao _faseAutenticacao;
  late FaseCadastro _faseCadastro;
  bool _aprovacaoConfirmada = false;
  late EstadoPermissaoLocalizacao _permissaoLocalizacao;
  bool _podeContinuarSemPosicao = false;
}

final Provider<GoRouter> roteadorProvider = Provider<GoRouter>((Ref ref) {
  final _NotificadorNavegacao notificador = _NotificadorNavegacao(ref);
  ref.onDispose(notificador.dispose);

  String destinoParaMotoqueiro() {
    final EstadoCadastro estadoCadastro = ref.read(controladorCadastroProvider);
    return switch (estadoCadastro.fase) {
      FaseCadastro.inicial => Rotas.cadastroDados,
      FaseCadastro.dados => Rotas.cadastroDados,
      FaseCadastro.mota => Rotas.cadastroMota,
      FaseCadastro.documentos => Rotas.cadastroDocumentos,
      FaseCadastro.pendente => Rotas.cadastroAprovacao,
      FaseCadastro.rejeitado => Rotas.cadastroAprovacao,
      FaseCadastro.aprovado => estadoCadastro.aprovacaoConfirmada
          ? Rotas.motoqueiro
          : Rotas.cadastroAprovacao,
    };
  }

  String destinoParaPassageiro() {
    final EstadoMapa estadoMapa = ref.read(controladorMapaProvider);
    final bool podeVerMapa =
        estadoMapa.permissao == EstadoPermissaoLocalizacao.concedida ||
        estadoMapa.podeContinuarSemPosicao;
    return podeVerMapa ? Rotas.inicio : Rotas.permissaoLocalizacao;
  }

  String destinoAutenticado(Utilizador? utilizador) {
    if (utilizador?.tipo != TipoUtilizador.motoqueiro) {
      return destinoParaPassageiro();
    }
    return destinoParaMotoqueiro();
  }

  String? redirect(BuildContext context, GoRouterState state) {
    if (Rotas.rotasEmpilhadas.contains(state.matchedLocation)) {
      return null;
    }
    final EstadoAutenticacao estadoAuth = ref.read(
      controladorAutenticacaoProvider,
    );
    final String destino = switch (estadoAuth.fase) {
      FaseAutenticacao.inicial => Rotas.splash,
      FaseAutenticacao.semSessao => Rotas.login,
      FaseAutenticacao.aguardaCodigo => Rotas.verificacao,
      FaseAutenticacao.perfilIncompleto => Rotas.completarPerfil,
      FaseAutenticacao.autenticado => destinoAutenticado(
        estadoAuth.utilizador,
      ),
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
        path: Rotas.cadastroDados,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraCadastroPassoDados(),
      ),
      GoRoute(
        path: Rotas.cadastroMota,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraCadastroPassoMota(),
      ),
      GoRoute(
        path: Rotas.cadastroDocumentos,
        builder: (BuildContext context, GoRouterState state) =>
            const EcraCadastroPassoDocumentos(),
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
    ],
  );
});
