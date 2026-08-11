import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/autenticacao/dados/repositorio_autenticacao.dart';
import 'package:project_x/funcionalidades/autenticacao/dominio/utilizador.dart';

enum FaseAutenticacao {
  inicial,
  semSessao,
  aguardaCodigo,
  perfilIncompleto,
  autenticado,
}

class EstadoAutenticacao {
  const EstadoAutenticacao({
    this.fase = FaseAutenticacao.inicial,
    this.telefone,
    this.utilizador,
    this.aProcessar = false,
    this.erro,
  });

  final FaseAutenticacao fase;
  final String? telefone;
  final Utilizador? utilizador;
  final bool aProcessar;
  final String? erro;

  EstadoAutenticacao copiarCom({
    FaseAutenticacao? fase,
    String? telefone,
    Utilizador? utilizador,
    bool? aProcessar,
    String? erro,
    bool limparErro = false,
  }) {
    return EstadoAutenticacao(
      fase: fase ?? this.fase,
      telefone: telefone ?? this.telefone,
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
        fase: utilizador.perfilCompleto
            ? FaseAutenticacao.autenticado
            : FaseAutenticacao.perfilIncompleto,
        utilizador: utilizador,
        telefone: utilizador.telefone,
        aProcessar: false,
      );
    } on ExcecaoAutenticacao catch (e) {
      state = state.copiarCom(aProcessar: false, erro: e.mensagem);
    }
  }

  Future<void> pedirCodigo(String telefone) async {
    state = state.copiarCom(
      aProcessar: true,
      limparErro: true,
      telefone: telefone,
    );
    try {
      await _repositorio.pedirCodigo(telefone);
      state = state.copiarCom(
        fase: FaseAutenticacao.aguardaCodigo,
        aProcessar: false,
      );
    } on ExcecaoAutenticacao catch (e) {
      state = state.copiarCom(aProcessar: false, erro: e.mensagem);
    }
  }

  Future<void> reenviarCodigo() async {
    final String? telefone = state.telefone;
    if (telefone == null) {
      return;
    }
    state = state.copiarCom(aProcessar: true, limparErro: true);
    try {
      await _repositorio.pedirCodigo(telefone);
      state = state.copiarCom(aProcessar: false);
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
        fase: utilizador.perfilCompleto
            ? FaseAutenticacao.autenticado
            : FaseAutenticacao.perfilIncompleto,
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
        fase: FaseAutenticacao.autenticado,
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
