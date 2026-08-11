import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_x/funcionalidades/autenticacao/dominio/utilizador.dart';
import 'package:project_x/nucleo/tipo_aplicacao.dart';

abstract interface class RepositorioAutenticacao {
  Future<Utilizador?> sessaoAtual();
  Future<void> pedirCodigo(String telefone);
  Future<Utilizador> confirmarCodigo({
    required String telefone,
    required String codigo,
  });
  Future<Utilizador> guardarNome({
    required Utilizador utilizador,
    required String nome,
  });
  Future<void> terminarSessao();
}

class RepositorioAutenticacaoSimulado implements RepositorioAutenticacao {
  RepositorioAutenticacaoSimulado({required TipoAplicacao tipoAplicacao})
    : _tipoUtilizador = switch (tipoAplicacao) {
        TipoAplicacao.passageiro => TipoUtilizador.passageiro,
        TipoAplicacao.motoqueiro => TipoUtilizador.motoqueiro,
      };

  static const String _codigoValido = '123456';
  static const Duration _atraso = Duration(milliseconds: 900);

  final TipoUtilizador _tipoUtilizador;
  Utilizador? _sessao;

  @override
  Future<Utilizador?> sessaoAtual() async {
    await Future<void>.delayed(_atraso);
    return _sessao;
  }

  @override
  Future<void> pedirCodigo(String telefone) async {
    await Future<void>.delayed(_atraso);
  }

  @override
  Future<Utilizador> confirmarCodigo({
    required String telefone,
    required String codigo,
  }) async {
    await Future<void>.delayed(_atraso);
    if (codigo != _codigoValido) {
      throw const ExcecaoAutenticacao('Código incorreto. Tente de novo.');
    }
    final Utilizador utilizador = Utilizador(
      id: 'utilizador-$telefone',
      telefone: telefone,
      tipo: _tipoUtilizador,
    );
    _sessao = utilizador;
    return utilizador;
  }

  @override
  Future<Utilizador> guardarNome({
    required Utilizador utilizador,
    required String nome,
  }) async {
    await Future<void>.delayed(_atraso);
    final Utilizador atualizado = utilizador.copiarCom(nome: nome);
    _sessao = atualizado;
    return atualizado;
  }

  @override
  Future<void> terminarSessao() async {
    await Future<void>.delayed(_atraso);
    _sessao = null;
  }
}

final Provider<RepositorioAutenticacao> repositorioAutenticacaoProvider =
    Provider<RepositorioAutenticacao>(
  (Ref ref) => RepositorioAutenticacaoSimulado(
    tipoAplicacao: ref.watch(tipoAplicacaoProvider),
  ),
);
