import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project_x/funcionalidades/cadastro_motoqueiro/dominio/motoqueiro.dart';
import 'package:project_x/nucleo/configuracao/configuracao_supabase.dart';
import 'package:project_x/nucleo/supabase/cliente_supabase.dart';

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
    final Motoqueiro? existente = _atual?.telefone == telefone ? _atual : null;
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

class RepositorioCadastroSupabase implements RepositorioCadastro {
  RepositorioCadastroSupabase({required this._cliente});

  static const String _bucket = 'documentos';
  static const String _colunas = '*, documentos(tipo, caminho_storage)';

  static const Map<TipoDocumento, String> _tiposDocumento =
      <TipoDocumento, String>{
        TipoDocumento.cartaConducao: 'carta_conducao',
        TipoDocumento.livrete: 'livrete',
        TipoDocumento.bilheteIdentidade: 'bilhete_identidade',
        TipoDocumento.selfie: 'selfie',
      };

  final SupabaseClient _cliente;

  /// O servidor identifica o motoqueiro por `auth.uid()`; o [telefone] fica
  /// na interface só por causa da implementação simulada.
  @override
  Future<Motoqueiro?> cadastroAtual(String telefone) {
    return _protegido(
      _carregar,
      porOmissao: 'Não foi possível carregar o seu cadastro. Tente de novo.',
    );
  }

  @override
  Future<Motoqueiro> guardarDadosPessoais({
    required String telefone,
    required String nomeCompleto,
    required String numeroBi,
    required String bairro,
    required String distrito,
    required String contactoEmergencia,
  }) {
    return _protegido(() async {
      final Map<String, Object?> dados = <String, Object?>{
        'nome_completo': nomeCompleto,
        'numero_bi': numeroBi,
        'bairro': bairro,
        'distrito': distrito,
        'contacto_emergencia': contactoEmergencia,
      };
      // Sem upsert: a coluna `id` não tem permissão de UPDATE, e o upsert do
      // PostgREST reescreve todas as colunas enviadas.
      final Map<String, dynamic>? existente = await _cliente
          .from('motoqueiros')
          .select('id')
          .eq('id', _idAtual)
          .maybeSingle();
      if (existente == null) {
        await _cliente.from('motoqueiros').insert(<String, Object?>{
          'id': _idAtual,
          ...dados,
        });
      } else {
        await _cliente.from('motoqueiros').update(dados).eq('id', _idAtual);
      }
      return _carregarObrigatorio();
    }, porOmissao: 'Não foi possível guardar os seus dados. Tente de novo.');
  }

  @override
  Future<Motoqueiro> guardarDadosMota({
    required String matricula,
    required String marca,
    required String modelo,
    required String cor,
    required int anoFabrico,
  }) {
    return _protegido(() async {
      await _cliente
          .from('motoqueiros')
          .update(<String, Object?>{
            'matricula': matricula,
            'marca': marca,
            'modelo': modelo,
            'cor': cor,
            'ano_fabrico': anoFabrico,
          })
          .eq('id', _idAtual);
      return _carregarObrigatorio();
    }, porOmissao: 'Não foi possível guardar os dados da mota. Tente de novo.');
  }

  @override
  Future<Motoqueiro> enviarDocumento({
    required TipoDocumento tipo,
    required String caminho,
  }) {
    return _protegido(() async {
      final String tipoServidor = _tiposDocumento[tipo]!;
      // Um ficheiro por tipo, sempre com o mesmo nome: reenviar substitui.
      final String caminhoStorage = '$_idAtual/$tipoServidor';
      final String contentType = caminho.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';
      await _cliente.storage
          .from(_bucket)
          .upload(
            caminhoStorage,
            File(caminho),
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          );
      await _cliente.from('documentos').upsert(<String, Object?>{
        'motoqueiro_id': _idAtual,
        'tipo': tipoServidor,
        'caminho_storage': caminhoStorage,
        'enviado_em': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'motoqueiro_id,tipo');
      return _carregarObrigatorio();
    }, porOmissao: 'Não foi possível enviar o documento. Tente novamente.');
  }

  @override
  Future<Motoqueiro> submeterParaAprovacao() {
    return _protegido(() async {
      await _cliente.rpc<dynamic>('submeter_cadastro');
      return _carregarObrigatorio();
    }, porOmissao: 'Não foi possível submeter o cadastro. Tente de novo.');
  }

  String get _idAtual {
    final User? utilizador = _cliente.auth.currentUser;
    if (utilizador == null) {
      throw const ExcecaoCadastro(
        'A sua sessão terminou. Entre de novo com o seu número.',
      );
    }
    return utilizador.id;
  }

  Future<Motoqueiro?> _carregar() async {
    final Map<String, dynamic>? linha = await _cliente
        .from('motoqueiros')
        .select(_colunas)
        .eq('id', _idAtual)
        .maybeSingle();
    return linha == null ? null : _deLinha(linha);
  }

  Future<Motoqueiro> _carregarObrigatorio() async {
    final Motoqueiro? motoqueiro = await _carregar();
    if (motoqueiro == null) {
      throw const ExcecaoCadastro(
        'Não encontrámos o seu cadastro. Preencha os seus dados para continuar.',
      );
    }
    return motoqueiro;
  }

  Motoqueiro _deLinha(Map<String, dynamic> linha) {
    final Map<String, TipoDocumento> tiposPorNome = <String, TipoDocumento>{
      for (final MapEntry<TipoDocumento, String> e in _tiposDocumento.entries)
        e.value: e.key,
    };
    final List<dynamic> documentos =
        linha['documentos'] as List<dynamic>? ?? <dynamic>[];
    final String? submetidoEm = linha['submetido_em'] as String?;
    return Motoqueiro(
      id: linha['id'] as String,
      telefone: telefoneLocal(_cliente.auth.currentUser?.phone),
      nomeCompleto: linha['nome_completo'] as String,
      numeroBi: linha['numero_bi'] as String,
      bairro: linha['bairro'] as String,
      distrito: linha['distrito'] as String,
      contactoEmergencia: linha['contacto_emergencia'] as String,
      matricula: linha['matricula'] as String?,
      marca: linha['marca'] as String?,
      modelo: linha['modelo'] as String?,
      cor: linha['cor'] as String?,
      anoFabrico: linha['ano_fabrico'] as int?,
      estadoVerificacao: EstadoVerificacao.values.byName(
        linha['estado_verificacao'] as String,
      ),
      motivoRejeicao: linha['motivo_rejeicao'] as String?,
      documentos: <TipoDocumento, String>{
        for (final dynamic d in documentos)
          if (tiposPorNome[(d as Map<String, dynamic>)['tipo']] != null)
            tiposPorNome[d['tipo']]!: d['caminho_storage'] as String,
      },
      dataSubmissao: submetidoEm == null
          ? null
          : DateTime.parse(submetidoEm).toLocal(),
    );
  }

  Future<T> _protegido<T>(
    Future<T> Function() acao, {
    required String porOmissao,
  }) async {
    try {
      return await acao();
    } on ExcecaoCadastro {
      rethrow;
    } catch (erro) {
      throw ExcecaoCadastro(traduzirErroSupabase(erro, porOmissao: porOmissao));
    }
  }
}

final Provider<RepositorioCadastro> repositorioCadastroProvider =
    Provider<RepositorioCadastro>(
      (Ref ref) => ConfiguracaoSupabase.configurado
          ? RepositorioCadastroSupabase(
              cliente: ref.watch(clienteSupabaseProvider),
            )
          : RepositorioCadastroSimulado(),
    );
