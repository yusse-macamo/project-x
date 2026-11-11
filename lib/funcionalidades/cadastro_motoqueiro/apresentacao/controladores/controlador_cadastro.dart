import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/dados/repositorio_cadastro.dart';
import 'package:project_x/funcionalidades/cadastro_motoqueiro/dominio/motoqueiro.dart';
import 'package:project_x/funcionalidades/inicio/dominio/tipo_veiculo.dart';

enum FaseCadastro { inicial, formulario, pendente, rejeitado, aprovado }

class EstadoCadastro {
  const EstadoCadastro({
    this.fase = FaseCadastro.inicial,
    this.motoqueiro,
    this.tipoVeiculo,
    this.aProcessar = false,
    this.erro,
    this.aprovacaoConfirmada = false,
  });

  final FaseCadastro fase;
  final Motoqueiro? motoqueiro;

  /// Escolhido no ecrã "Como queres usar a ROTA?" (Mototaxista, Txopelista
  /// ou Taxista). Tem prioridade sobre o tipo já guardado em [motoqueiro]:
  /// quem escolhe outro tipo muda de formulário.
  final TipoVeiculo? tipoVeiculo;
  final bool aProcessar;
  final String? erro;

  /// Fica a `true` quando o motorista toca em "Começar a trabalhar" no ecrã
  /// de aprovação. Enquanto for `false`, a fase [FaseCadastro.aprovado]
  /// continua a resolver para `/cadastro/aprovacao` em vez de
  /// `/motoqueiro` — para o utilizador ver o ecrã de aprovado antes do
  /// redirect o levar dali para a frente.
  final bool aprovacaoConfirmada;

  TipoVeiculo? get tipoVeiculoAtual => tipoVeiculo ?? motoqueiro?.tipoVeiculo;

  EstadoCadastro copiarCom({
    FaseCadastro? fase,
    Motoqueiro? motoqueiro,
    TipoVeiculo? tipoVeiculo,
    bool? aProcessar,
    String? erro,
    bool limparErro = false,
    bool? aprovacaoConfirmada,
  }) {
    return EstadoCadastro(
      fase: fase ?? this.fase,
      motoqueiro: motoqueiro ?? this.motoqueiro,
      tipoVeiculo: tipoVeiculo ?? this.tipoVeiculo,
      aProcessar: aProcessar ?? this.aProcessar,
      erro: limparErro ? null : (erro ?? this.erro),
      aprovacaoConfirmada: aprovacaoConfirmada ?? this.aprovacaoConfirmada,
    );
  }
}

class ControladorCadastro extends Notifier<EstadoCadastro> {
  @override
  EstadoCadastro build() {
    // Outra sessão (ou nenhuma) nunca herda o cadastro da anterior.
    ref.watch(
      controladorAutenticacaoProvider.select(
        (EstadoAutenticacao estado) => estado.utilizador?.id,
      ),
    );
    return const EstadoCadastro();
  }

  RepositorioCadastro get _repositorio => ref.read(repositorioCadastroProvider);

  String get _telefone {
    final String? telefone = ref.read(controladorAutenticacaoProvider).telefone;
    if (telefone == null) {
      throw StateError('Cadastro acedido sem sessão de autenticação ativa.');
    }
    return telefone;
  }

  static FaseCadastro _faseParaMotoqueiro(Motoqueiro? motoqueiro) {
    return switch (motoqueiro?.estadoVerificacao) {
      null || EstadoVerificacao.incompleto => FaseCadastro.formulario,
      EstadoVerificacao.pendente => FaseCadastro.pendente,
      EstadoVerificacao.rejeitado => FaseCadastro.rejeitado,
      EstadoVerificacao.aprovado => FaseCadastro.aprovado,
    };
  }

  void escolherTipoVeiculo(TipoVeiculo tipo) {
    state = state.copiarCom(tipoVeiculo: tipo, limparErro: true);
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

  /// Guarda os dados, envia as fotografias novas e submete para aprovação,
  /// por esta ordem. Pára no primeiro erro; o que já foi guardado fica em
  /// [EstadoCadastro.motoqueiro], para a pessoa não ter de repetir.
  Future<void> enviarParaAprovacao({
    required String nomeCompleto,
    required String email,
    required String matricula,
    required String cor,
    String? marca,
    String? modelo,
    required Map<TipoDocumento, String> fotosNovas,
  }) async {
    final TipoVeiculo? tipoVeiculo = state.tipoVeiculoAtual;
    if (tipoVeiculo == null) {
      return;
    }
    state = state.copiarCom(aProcessar: true, limparErro: true);
    try {
      Motoqueiro motoqueiro = await _repositorio.guardarDadosPessoais(
        telefone: _telefone,
        tipoVeiculo: tipoVeiculo,
        nomeCompleto: nomeCompleto,
        email: email,
      );
      state = state.copiarCom(motoqueiro: motoqueiro);
      motoqueiro = await _repositorio.guardarDadosVeiculo(
        matricula: matricula,
        cor: cor,
        marca: exigeMarcaModelo(tipoVeiculo) ? marca : null,
        modelo: exigeMarcaModelo(tipoVeiculo) ? modelo : null,
      );
      state = state.copiarCom(motoqueiro: motoqueiro);
      for (final MapEntry<TipoDocumento, String> foto in fotosNovas.entries) {
        if (!documentosExigidos(tipoVeiculo).contains(foto.key)) {
          continue;
        }
        motoqueiro = await _repositorio.enviarDocumento(
          tipo: foto.key,
          caminho: foto.value,
        );
        state = state.copiarCom(motoqueiro: motoqueiro);
      }
      motoqueiro = await _repositorio.submeterParaAprovacao();
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

  /// Do ecrã de rejeitado, volta ao formulário para corrigir.
  void corrigir() {
    state = state.copiarCom(fase: FaseCadastro.formulario);
  }

  /// Recuar do formulário só tem destino dentro do cadastro se o motorista
  /// veio corrigir um cadastro rejeitado — volta a ver o motivo. Devolve
  /// `false` quando não há para onde recuar.
  bool voltarDoFormulario() {
    if (state.motoqueiro?.estadoVerificacao != EstadoVerificacao.rejeitado) {
      return false;
    }
    state = state.copiarCom(fase: FaseCadastro.rejeitado);
    return true;
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
