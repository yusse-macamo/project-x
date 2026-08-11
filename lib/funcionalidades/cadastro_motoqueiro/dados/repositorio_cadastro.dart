import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/cadastro_motoqueiro/dominio/motoqueiro.dart';

abstract interface class RepositorioCadastro {
  Future<Motoqueiro?> cadastroAtual(String telefone);

  Future<Motoqueiro> guardarDadosPessoais({
    required String telefone,
    required String nomeCompleto,
    required String numeroBi,
    required String bairro,
    required String distrito,
    required String contactoEmergencia,
  });

  Future<Motoqueiro> guardarDadosMota({
    required String matricula,
    required String marca,
    required String modelo,
    required String cor,
    required int anoFabrico,
  });

  Future<Motoqueiro> enviarDocumento({
    required TipoDocumento tipo,
    required String caminho,
  });

  Future<Motoqueiro> submeterParaAprovacao();
}

class RepositorioCadastroSimulado implements RepositorioCadastro {
  static const Duration _atraso = Duration(milliseconds: 800);
  static const Duration _atrasoAprovacao = Duration(seconds: 20);

  Motoqueiro? _atual;
  bool _livreteJaFalhou = false;

  @override
  Future<Motoqueiro?> cadastroAtual(String telefone) async {
    await Future<void>.delayed(_atraso);
    final Motoqueiro? atual = _atual;
    if (atual != null && atual.telefone == telefone) {
      return atual;
    }
    return null;
  }

  @override
  Future<Motoqueiro> guardarDadosPessoais({
    required String telefone,
    required String nomeCompleto,
    required String numeroBi,
    required String bairro,
    required String distrito,
    required String contactoEmergencia,
  }) async {
    await Future<void>.delayed(_atraso);
    final Motoqueiro? existente = _atual?.telefone == telefone
        ? _atual
        : null;
    final Motoqueiro atualizado = Motoqueiro(
      id: 'motoqueiro-$telefone',
      telefone: telefone,
      nomeCompleto: nomeCompleto,
      numeroBi: numeroBi,
      bairro: bairro,
      distrito: distrito,
      contactoEmergencia: contactoEmergencia,
      matricula: existente?.matricula,
      marca: existente?.marca,
      modelo: existente?.modelo,
      cor: existente?.cor,
      anoFabrico: existente?.anoFabrico,
      estadoVerificacao:
          existente?.estadoVerificacao ?? EstadoVerificacao.incompleto,
      documentos: existente?.documentos ?? const <TipoDocumento, String>{},
    );
    _atual = atualizado;
    return atualizado;
  }

  @override
  Future<Motoqueiro> guardarDadosMota({
    required String matricula,
    required String marca,
    required String modelo,
    required String cor,
    required int anoFabrico,
  }) async {
    await Future<void>.delayed(_atraso);
    final Motoqueiro atual = _exigirCadastroAtual();
    final Motoqueiro atualizado = atual.copiarCom(
      matricula: matricula,
      marca: marca,
      modelo: modelo,
      cor: cor,
      anoFabrico: anoFabrico,
    );
    _atual = atualizado;
    return atualizado;
  }

  @override
  Future<Motoqueiro> enviarDocumento({
    required TipoDocumento tipo,
    required String caminho,
  }) async {
    await Future<void>.delayed(_atraso);
    final Motoqueiro atual = _exigirCadastroAtual();
    if (tipo == TipoDocumento.livrete && !_livreteJaFalhou) {
      _livreteJaFalhou = true;
      throw const ExcecaoCadastro(
        'Não foi possível enviar o livrete. Tente novamente.',
      );
    }
    final Map<TipoDocumento, String> documentos =
        Map<TipoDocumento, String>.from(atual.documentos)..[tipo] = caminho;
    final Motoqueiro atualizado = atual.copiarCom(documentos: documentos);
    _atual = atualizado;
    return atualizado;
  }

  @override
  Future<Motoqueiro> submeterParaAprovacao() async {
    await Future<void>.delayed(_atraso);
    final Motoqueiro atual = _exigirCadastroAtual();
    final Motoqueiro atualizado = atual.copiarCom(
      estadoVerificacao: EstadoVerificacao.pendente,
      dataSubmissao: DateTime.now(),
      limparMotivoRejeicao: true,
    );
    _atual = atualizado;
    unawaited(
      Future<void>.delayed(_atrasoAprovacao, () {
        if (_atual?.id == atualizado.id) {
          _atual = _atual!.copiarCom(
            estadoVerificacao: EstadoVerificacao.aprovado,
          );
        }
      }),
    );
    return atualizado;
  }

  Motoqueiro _exigirCadastroAtual() {
    final Motoqueiro? atual = _atual;
    if (atual == null) {
      throw StateError(
        'Tentativa de avançar o cadastro sem dados pessoais guardados.',
      );
    }
    return atual;
  }
}

final Provider<RepositorioCadastro> repositorioCadastroProvider =
    Provider<RepositorioCadastro>(
  (Ref ref) => RepositorioCadastroSimulado(),
);
