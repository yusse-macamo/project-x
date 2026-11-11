import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project_x/funcionalidades/autenticacao/dominio/canal_codigo.dart';
import 'package:project_x/funcionalidades/autenticacao/dominio/utilizador.dart';
import 'package:project_x/nucleo/configuracao/configuracao_supabase.dart';
import 'package:project_x/nucleo/supabase/cliente_supabase.dart';

abstract interface class RepositorioAutenticacao {
  /// Código que funciona sempre, só nas implementações de teste. `null`
  /// quando o código chega mesmo por SMS ou WhatsApp.
  String? get codigoDeTeste;

  Future<Utilizador?> sessaoAtual();
  Future<void> pedirCodigo(String telefone, {required CanalCodigo canal});
  Future<Utilizador> confirmarCodigo({
    required String telefone,
    required String codigo,
  });
  Future<Utilizador> guardarNome({
    required Utilizador utilizador,
    required String nome,
  });
  Future<Utilizador> guardarTipo({
    required Utilizador utilizador,
    required TipoUtilizador tipo,
  });
  Future<void> terminarSessao();
}

class RepositorioAutenticacaoSimulado implements RepositorioAutenticacao {
  static const String _codigoValido = '123456';
  static const Duration _atraso = Duration(milliseconds: 900);

  Utilizador? _sessao;

  @override
  String? get codigoDeTeste => _codigoValido;

  @override
  Future<Utilizador?> sessaoAtual() async {
    await Future<void>.delayed(_atraso);
    return _sessao;
  }

  @override
  Future<void> pedirCodigo(
    String telefone, {
    required CanalCodigo canal,
  }) async {
    await Future<void>.delayed(_atraso);
  }

  @override
  Future<Utilizador> confirmarCodigo({
    required String telefone,
    required String codigo,
  }) async {
    await Future<void>.delayed(_atraso);
    if (codigo != _codigoValido) {
      throw const ExcecaoAutenticacao('Código incorreto. Tenta de novo.');
    }
    final Utilizador utilizador = Utilizador(
      id: 'utilizador-$telefone',
      telefone: telefone,
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
  Future<Utilizador> guardarTipo({
    required Utilizador utilizador,
    required TipoUtilizador tipo,
  }) async {
    await Future<void>.delayed(_atraso);
    final Utilizador atualizado = utilizador.copiarCom(tipo: tipo);
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
  RepositorioAutenticacaoSupabase({required this._cliente});

  static const Map<TipoUtilizador, String> _papelServidor =
      <TipoUtilizador, String>{
        TipoUtilizador.passageiro: 'passageiro',
        TipoUtilizador.motoqueiro: 'motorista',
      };

  final SupabaseClient _cliente;

  @override
  String? get codigoDeTeste => null;

  @override
  Future<Utilizador?> sessaoAtual() {
    return _protegido(() async {
      final User? utilizador = _cliente.auth.currentUser;
      if (utilizador == null) {
        return null;
      }
      return _carregar(utilizador);
    }, porOmissao: 'Não foi possível recuperar a tua sessão. Tenta de novo.');
  }

  @override
  Future<void> pedirCodigo(String telefone, {required CanalCodigo canal}) {
    return _protegido(
      () => _cliente.auth.signInWithOtp(
        phone: telefoneServidor(telefone),
        channel: switch (canal) {
          CanalCodigo.sms => OtpChannel.sms,
          CanalCodigo.whatsapp => OtpChannel.whatsapp,
        },
      ),
      porOmissao: 'Não foi possível enviar o código. Tenta de novo.',
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
          'Não foi possível confirmar o código. Pede um novo código.',
        );
      }
      return _carregar(utilizador);
    }, porOmissao: 'Não foi possível confirmar o código. Tenta de novo.');
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
    }, porOmissao: 'Não foi possível guardar o nome. Tenta de novo.');
  }

  @override
  Future<Utilizador> guardarTipo({
    required Utilizador utilizador,
    required TipoUtilizador tipo,
  }) {
    return _protegido(() async {
      await _cliente
          .from('perfis')
          .update(<String, Object?>{'papel': _papelServidor[tipo]})
          .eq('id', utilizador.id);
      return utilizador.copiarCom(tipo: tipo);
    }, porOmissao: 'Não foi possível guardar a tua escolha. Tenta de novo.');
  }

  @override
  Future<void> terminarSessao() {
    return _protegido(
      () => _cliente.auth.signOut(),
      porOmissao: 'Não foi possível terminar a sessão. Tenta de novo.',
    );
  }

  Future<Utilizador> _carregar(User utilizador) async {
    final Map<String, dynamic>? perfil = await _cliente
        .from('perfis')
        .select('nome, url_foto, papel')
        .eq('id', utilizador.id)
        .maybeSingle();
    return Utilizador(
      id: utilizador.id,
      telefone: telefoneLocal(utilizador.phone),
      tipo: _papelServidor.entries
          .where(
            (MapEntry<TipoUtilizador, String> e) => e.value == perfil?['papel'],
          )
          .firstOrNull
          ?.key,
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
      // A mensagem traduzida esconde o erro original; em desenvolvimento,
      // fica no registo para se perceber o que o servidor respondeu.
      debugPrint('RepositorioAutenticacaoSupabase: $erro');
      throw ExcecaoAutenticacao(
        traduzirErroSupabase(erro, porOmissao: porOmissao),
      );
    }
  }
}

final Provider<RepositorioAutenticacao> repositorioAutenticacaoProvider =
    Provider<RepositorioAutenticacao>((Ref ref) {
      if (ConfiguracaoSupabase.configurado) {
        return RepositorioAutenticacaoSupabase(
          cliente: ref.watch(clienteSupabaseProvider),
        );
      }
      return RepositorioAutenticacaoSimulado();
    });
