import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/autenticacao/dados/repositorio_autenticacao.dart';
import 'package:project_x/funcionalidades/autenticacao/dominio/canal_codigo.dart';
import 'package:project_x/funcionalidades/autenticacao/dominio/utilizador.dart';

enum FaseAutenticacao {
  inicial,
  semSessao,
  aguardaCodigo,
  escolherTipo,
  perfilIncompleto,
  autenticado,
}

class EstadoAutenticacao {
  const EstadoAutenticacao({
    this.fase = FaseAutenticacao.inicial,
    this.telefone,
    this.canal = CanalCodigo.sms,
    this.codigoEnviado = false,
    this.utilizador,
    this.aProcessar = false,
    this.erro,
  });

  final FaseAutenticacao fase;
  final String? telefone;
  final CanalCodigo canal;

  /// `false` ao chegar ao ecrã do código: o envio só acontece depois de a
  /// pessoa escolher SMS ou WhatsApp.
  final bool codigoEnviado;
  final Utilizador? utilizador;
  final bool aProcessar;
  final String? erro;

  EstadoAutenticacao copiarCom({
    FaseAutenticacao? fase,
    String? telefone,
    CanalCodigo? canal,
    bool? codigoEnviado,
    Utilizador? utilizador,
    bool? aProcessar,
    String? erro,
    bool limparErro = false,
  }) {
    return EstadoAutenticacao(
      fase: fase ?? this.fase,
      telefone: telefone ?? this.telefone,
      canal: canal ?? this.canal,
      codigoEnviado: codigoEnviado ?? this.codigoEnviado,
      utilizador: utilizador ?? this.utilizador,
      aProcessar: aProcessar ?? this.aProcessar,
      erro: limparErro ? null : (erro ?? this.erro),
    );
  }
}

class ControladorAutenticacao extends Notifier<EstadoAutenticacao> {
  @override
  EstadoAutenticacao build() {
    return const EstadoAutenticacao();
  }

  RepositorioAutenticacao get _repositorio =>
      ref.read(repositorioAutenticacaoProvider);

  String? get codigoDeTeste => _repositorio.codigoDeTeste;

  static FaseAutenticacao _faseDe(Utilizador utilizador) {
    if (utilizador.tipo == null) {
      return FaseAutenticacao.escolherTipo;
    }
    return utilizador.perfilCompleto
        ? FaseAutenticacao.autenticado
        : FaseAutenticacao.perfilIncompleto;
  }

  /// Abre de novo "Como queres usar a ROTA?" sem apagar a escolha atual: a
  /// pessoa pode trocar de tipo de motorista ou desistir e voltar onde
  /// estava ([cancelarEscolhaTipo]).
  void voltarAEscolherTipo() {
    if (state.utilizador == null) {
      return;
    }
    state = state.copiarCom(
      fase: FaseAutenticacao.escolherTipo,
      limparErro: true,
    );
  }

  /// Só faz sentido para quem já tinha escolhido; devolve `false` se não há
  /// escolha anterior para onde voltar.
  bool cancelarEscolhaTipo() {
    final Utilizador? utilizador = state.utilizador;
    if (utilizador?.tipo == null) {
      return false;
    }
    state = state.copiarCom(fase: _faseDe(utilizador!));
    return true;
  }

  /// Serve para a primeira escolha e para mudar mais tarde pelo menu.
  Future<void> escolherTipo(TipoUtilizador tipo) async {
    final Utilizador? utilizador = state.utilizador;
    if (utilizador == null) {
      return;
    }
    state = state.copiarCom(aProcessar: true, limparErro: true);
    try {
      final Utilizador atualizado = await _repositorio.guardarTipo(
        utilizador: utilizador,
        tipo: tipo,
      );
      state = state.copiarCom(
        fase: _faseDe(atualizado),
        utilizador: atualizado,
        aProcessar: false,
      );
    } on ExcecaoAutenticacao catch (e) {
      state = state.copiarCom(aProcessar: false, erro: e.mensagem);
    }
  }

  Future<void> verificarSessao() async {
    state = state.copiarCom(aProcessar: true, limparErro: true);
    try {
      final Utilizador? utilizador = await _repositorio.sessaoAtual();
      if (utilizador == null) {
        state = state.copiarCom(
          fase: FaseAutenticacao.semSessao,
          aProcessar: false,
        );
        return;
      }
      state = state.copiarCom(
        fase: _faseDe(utilizador),
        utilizador: utilizador,
        telefone: utilizador.telefone,
        aProcessar: false,
      );
    } on ExcecaoAutenticacao catch (e) {
      state = state.copiarCom(aProcessar: false, erro: e.mensagem);
    }
  }

  void continuarParaCodigo(String telefone) {
    state = state.copiarCom(
      fase: FaseAutenticacao.aguardaCodigo,
      telefone: telefone,
      codigoEnviado: false,
      limparErro: true,
    );
  }

  Future<void> enviarCodigo(CanalCodigo canal) async {
    final String? telefone = state.telefone;
    if (telefone == null) {
      return;
    }
    state = state.copiarCom(aProcessar: true, limparErro: true, canal: canal);
    try {
      await _repositorio.pedirCodigo(telefone, canal: canal);
      state = state.copiarCom(aProcessar: false, codigoEnviado: true);
    } on ExcecaoAutenticacao catch (e) {
      state = state.copiarCom(aProcessar: false, erro: e.mensagem);
    }
  }

  Future<void> confirmarCodigo(String codigo) async {
    final String? telefone = state.telefone;
    if (telefone == null) {
      return;
    }
    state = state.copiarCom(aProcessar: true, limparErro: true);
    try {
      final Utilizador utilizador = await _repositorio.confirmarCodigo(
        telefone: telefone,
        codigo: codigo,
      );
      state = state.copiarCom(
        fase: _faseDe(utilizador),
        utilizador: utilizador,
        aProcessar: false,
      );
    } on ExcecaoAutenticacao catch (e) {
      state = state.copiarCom(aProcessar: false, erro: e.mensagem);
    }
  }

  Future<void> guardarNome(String nome) async {
    final Utilizador? utilizador = state.utilizador;
    if (utilizador == null) {
      return;
    }
    state = state.copiarCom(aProcessar: true, limparErro: true);
    try {
      final Utilizador atualizado = await _repositorio.guardarNome(
        utilizador: utilizador,
        nome: nome,
      );
      state = state.copiarCom(
        fase: _faseDe(atualizado),
        utilizador: atualizado,
        aProcessar: false,
      );
    } on ExcecaoAutenticacao catch (e) {
      state = state.copiarCom(aProcessar: false, erro: e.mensagem);
    }
  }

  Future<void> terminarSessao() async {
    state = state.copiarCom(aProcessar: true, limparErro: true);
    try {
      await _repositorio.terminarSessao();
      state = const EstadoAutenticacao(fase: FaseAutenticacao.semSessao);
    } on ExcecaoAutenticacao catch (e) {
      state = state.copiarCom(aProcessar: false, erro: e.mensagem);
    }
  }

  void voltarAoNumero() {
    state = state.copiarCom(
      fase: FaseAutenticacao.semSessao,
      codigoEnviado: false,
      limparErro: true,
    );
  }

  void limparErro() {
    state = state.copiarCom(limparErro: true);
  }
}

final NotifierProvider<ControladorAutenticacao, EstadoAutenticacao>
controladorAutenticacaoProvider =
    NotifierProvider<ControladorAutenticacao, EstadoAutenticacao>(
      ControladorAutenticacao.new,
    );
