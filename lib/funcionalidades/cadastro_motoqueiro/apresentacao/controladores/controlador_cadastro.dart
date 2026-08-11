import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/dados/repositorio_cadastro.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/dominio/motoqueiro.dart';

enum FaseCadastro {
  inicial,
  dados,
  mota,
  documentos,
  pendente,
  rejeitado,
  aprovado,
}

class EstadoCadastro {
  const EstadoCadastro({
    this.fase = FaseCadastro.inicial,
    this.motoqueiro,
    this.aProcessar = false,
    this.erro,
    this.aprovacaoConfirmada = false,
  });

  final FaseCadastro fase;
  final Motoqueiro? motoqueiro;
  final bool aProcessar;
  final String? erro;

  /// Fica a `true` quando o motoqueiro toca em "Começar a trabalhar" no
  /// ecrã de aprovação. Enquanto for `false`, a fase [FaseCadastro.aprovado]
  /// continua a resolver para `/cadastro/aprovacao` em vez de
  /// `/motoqueiro` — para o utilizador ver o ecrã de aprovado antes do
  /// redirect o levar dali para a frente.
  final bool aprovacaoConfirmada;

  EstadoCadastro copiarCom({
    FaseCadastro? fase,
    Motoqueiro? motoqueiro,
    bool? aProcessar,
    String? erro,
    bool limparErro = false,
    bool? aprovacaoConfirmada,
  }) {
    return EstadoCadastro(
      fase: fase ?? this.fase,
      motoqueiro: motoqueiro ?? this.motoqueiro,
      aProcessar: aProcessar ?? this.aProcessar,
      erro: limparErro ? null : (erro ?? this.erro),
      aprovacaoConfirmada: aprovacaoConfirmada ?? this.aprovacaoConfirmada,
    );
  }
}

class ControladorCadastro extends Notifier<EstadoCadastro> {
  @override
  EstadoCadastro build() {
    return const EstadoCadastro();
  }

  RepositorioCadastro get _repositorio =>
      ref.read(repositorioCadastroProvider);

  String get _telefone {
    final String? telefone = ref.read(controladorAutenticacaoProvider).telefone;
    if (telefone == null) {
      throw StateError('Cadastro acedido sem sessão de autenticação ativa.');
    }
    return telefone;
  }

  FaseCadastro _faseParaMotoqueiro(Motoqueiro? motoqueiro) {
    if (motoqueiro == null) {
      return FaseCadastro.dados;
    }
    return switch (motoqueiro.estadoVerificacao) {
      EstadoVerificacao.incompleto => switch (motoqueiro.passoAtual) {
        PassoCadastro.dados => FaseCadastro.dados,
        PassoCadastro.mota => FaseCadastro.mota,
        PassoCadastro.documentos => FaseCadastro.documentos,
      },
      EstadoVerificacao.pendente => FaseCadastro.pendente,
      EstadoVerificacao.rejeitado => FaseCadastro.rejeitado,
      EstadoVerificacao.aprovado => FaseCadastro.aprovado,
    };
  }

  Future<void> verificarCadastro() async {
    state = state.copiarCom(aProcessar: true, limparErro: true);
    try {
      final Motoqueiro? motoqueiro = await _repositorio.cadastroAtual(
        _telefone,
      );
      state = state.copiarCom(
        fase: _faseParaMotoqueiro(motoqueiro),
        motoqueiro: motoqueiro,
        aProcessar: false,
      );
    } on ExcecaoCadastro catch (e) {
      state = state.copiarCom(aProcessar: false, erro: e.mensagem);
    }
  }

  Future<void> guardarDadosPessoais({
    required String nomeCompleto,
    required String numeroBi,
    required String bairro,
    required String distrito,
    required String contactoEmergencia,
  }) async {
    state = state.copiarCom(aProcessar: true, limparErro: true);
    try {
      final Motoqueiro motoqueiro = await _repositorio.guardarDadosPessoais(
        telefone: _telefone,
        nomeCompleto: nomeCompleto,
        numeroBi: numeroBi,
        bairro: bairro,
        distrito: distrito,
        contactoEmergencia: contactoEmergencia,
      );
      state = state.copiarCom(
        fase: _faseParaMotoqueiro(motoqueiro),
        motoqueiro: motoqueiro,
        aProcessar: false,
      );
    } on ExcecaoCadastro catch (e) {
      state = state.copiarCom(aProcessar: false, erro: e.mensagem);
    }
  }

  Future<void> guardarDadosMota({
    required String matricula,
    required String marca,
    required String modelo,
    required String cor,
    required int anoFabrico,
  }) async {
    state = state.copiarCom(aProcessar: true, limparErro: true);
    try {
      final Motoqueiro motoqueiro = await _repositorio.guardarDadosMota(
        matricula: matricula,
        marca: marca,
        modelo: modelo,
        cor: cor,
        anoFabrico: anoFabrico,
      );
      state = state.copiarCom(
        fase: _faseParaMotoqueiro(motoqueiro),
        motoqueiro: motoqueiro,
        aProcessar: false,
      );
    } on ExcecaoCadastro catch (e) {
      state = state.copiarCom(aProcessar: false, erro: e.mensagem);
    }
  }

  Future<void> enviarDocumento({
    required TipoDocumento tipo,
    required String caminho,
  }) async {
    state = state.copiarCom(aProcessar: true, limparErro: true);
    try {
      final Motoqueiro motoqueiro = await _repositorio.enviarDocumento(
        tipo: tipo,
        caminho: caminho,
      );
      state = state.copiarCom(
        fase: _faseParaMotoqueiro(motoqueiro),
        motoqueiro: motoqueiro,
        aProcessar: false,
      );
    } on ExcecaoCadastro catch (e) {
      state = state.copiarCom(aProcessar: false, erro: e.mensagem);
    }
  }

  Future<void> submeterParaAprovacao() async {
    state = state.copiarCom(aProcessar: true, limparErro: true);
    try {
      final Motoqueiro motoqueiro = await _repositorio
          .submeterParaAprovacao();
      state = state.copiarCom(
        fase: _faseParaMotoqueiro(motoqueiro),
        motoqueiro: motoqueiro,
        aProcessar: false,
        aprovacaoConfirmada: false,
      );
    } on ExcecaoCadastro catch (e) {
      state = state.copiarCom(aProcessar: false, erro: e.mensagem);
    }
  }

  void voltarPara(FaseCadastro fase) {
    state = state.copiarCom(fase: fase);
  }

  void confirmarAprovacao() {
    state = state.copiarCom(aprovacaoConfirmada: true);
  }

  void limparErro() {
    state = state.copiarCom(limparErro: true);
  }
}

final NotifierProvider<ControladorCadastro, EstadoCadastro>
controladorCadastroProvider =
    NotifierProvider<ControladorCadastro, EstadoCadastro>(
      ControladorCadastro.new,
    );
