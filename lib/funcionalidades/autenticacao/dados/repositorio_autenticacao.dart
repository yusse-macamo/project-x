import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project_x/funcionalidades/autenticacao/dominio/utilizador.dart';
import 'package:project_x/nucleo/configuracao/configuracao_supabase.dart';
import 'package:project_x/nucleo/supabase/cliente_supabase.dart';
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

class RepositorioAutenticacaoSupabase implements RepositorioAutenticacao {
  RepositorioAutenticacaoSupabase({
    required this._cliente,
    required TipoAplicacao tipoAplicacao,
  }) : _tipoUtilizador = switch (tipoAplicacao) {
         TipoAplicacao.passageiro => TipoUtilizador.passageiro,
         TipoAplicacao.motoqueiro => TipoUtilizador.motoqueiro,
       };

  final SupabaseClient _cliente;
  final TipoUtilizador _tipoUtilizador;

  @override
  Future<Utilizador?> sessaoAtual() {
    return _protegido(() async {
      final User? utilizador = _cliente.auth.currentUser;
      if (utilizador == null) {
        return null;
      }
      return _carregar(utilizador);
    }, porOmissao: 'Não foi possível recuperar a sua sessão. Tente de novo.');
  }

  @override
  Future<void> pedirCodigo(String telefone) {
    return _protegido(
      () => _cliente.auth.signInWithOtp(phone: telefoneServidor(telefone)),
      porOmissao: 'Não foi possível enviar o código. Tente de novo.',
    );
  }

  @override
  Future<Utilizador> confirmarCodigo({
    required String telefone,
    required String codigo,
  }) {
    return _protegido(() async {
      final AuthResponse resposta = await _cliente.auth.verifyOTP(
        phone: telefoneServidor(telefone),
        token: codigo,
        type: OtpType.sms,
      );
      final User? utilizador = resposta.user;
      if (utilizador == null) {
        throw const ExcecaoAutenticacao(
          'Não foi possível confirmar o código. Peça um novo código.',
        );
      }
      return _carregar(utilizador);
    }, porOmissao: 'Não foi possível confirmar o código. Tente de novo.');
  }

  @override
  Future<Utilizador> guardarNome({
    required Utilizador utilizador,
    required String nome,
  }) {
    return _protegido(() async {
      await _cliente
          .from('perfis')
          .update(<String, Object?>{'nome': nome})
          .eq('id', utilizador.id);
      return utilizador.copiarCom(nome: nome);
    }, porOmissao: 'Não foi possível guardar o nome. Tente de novo.');
  }

  @override
  Future<void> terminarSessao() {
    return _protegido(
      () => _cliente.auth.signOut(),
      porOmissao: 'Não foi possível terminar a sessão. Tente de novo.',
    );
  }

  Future<Utilizador> _carregar(User utilizador) async {
    final Map<String, dynamic>? perfil = await _cliente
        .from('perfis')
        .select('nome, url_foto')
        .eq('id', utilizador.id)
        .maybeSingle();
    return Utilizador(
      id: utilizador.id,
      telefone: telefoneLocal(utilizador.phone),
      tipo: _tipoUtilizador,
      nome: perfil?['nome'] as String?,
      urlFoto: perfil?['url_foto'] as String?,
    );
  }

  Future<T> _protegido<T>(
    Future<T> Function() acao, {
    required String porOmissao,
  }) async {
    try {
      return await acao();
    } on ExcecaoAutenticacao {
      rethrow;
    } catch (erro) {
      throw ExcecaoAutenticacao(
        traduzirErroSupabase(erro, porOmissao: porOmissao),
      );
    }
  }
}

final Provider<RepositorioAutenticacao> repositorioAutenticacaoProvider =
    Provider<RepositorioAutenticacao>((Ref ref) {
      final TipoAplicacao tipoAplicacao = ref.watch(tipoAplicacaoProvider);
      if (ConfiguracaoSupabase.configurado) {
        return RepositorioAutenticacaoSupabase(
          cliente: ref.watch(clienteSupabaseProvider),
          tipoAplicacao: tipoAplicacao,
        );
      }
      return RepositorioAutenticacaoSimulado(tipoAplicacao: tipoAplicacao);
    });
