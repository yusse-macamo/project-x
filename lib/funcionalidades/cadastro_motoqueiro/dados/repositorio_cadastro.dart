import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project_x/funcionalidades/cadastro_motoqueiro/dominio/motoqueiro.dart';
import 'package:project_x/funcionalidades/inicio/dominio/tipo_veiculo.dart';
import 'package:project_x/nucleo/configuracao/configuracao_supabase.dart';
import 'package:project_x/nucleo/supabase/cliente_supabase.dart';

abstract interface class RepositorioCadastro {
  Future<Motoqueiro?> cadastroAtual(String telefone);

  Future<Motoqueiro> guardarDadosPessoais({
    required String telefone,
    required TipoVeiculo tipoVeiculo,
    required String nomeCompleto,
    required String email,
  });

  Future<Motoqueiro> guardarDadosVeiculo({
    required String matricula,
    required String cor,
    String? marca,
    String? modelo,
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
    required TipoVeiculo tipoVeiculo,
    required String nomeCompleto,
    required String email,
  }) async {
    await Future<void>.delayed(_atraso);
    final Motoqueiro? existente = _atual?.telefone == telefone ? _atual : null;
    final Motoqueiro atualizado =
        existente?.copiarCom(
          tipoVeiculo: tipoVeiculo,
          nomeCompleto: nomeCompleto,
          email: email,
        ) ??
        Motoqueiro(
          id: 'motoqueiro-$telefone',
          telefone: telefone,
          tipoVeiculo: tipoVeiculo,
          nomeCompleto: nomeCompleto,
          email: email,
        );
    _atual = atualizado;
    return atualizado;
  }

  @override
  Future<Motoqueiro> guardarDadosVeiculo({
    required String matricula,
    required String cor,
    String? marca,
    String? modelo,
  }) async {
    await Future<void>.delayed(_atraso);
    final Motoqueiro atualizado = _exigirCadastroAtual().copiarCom(
      matricula: matricula,
      cor: cor,
      marca: marca,
      modelo: modelo,
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
    if (!atual.dadosVeiculoCompletos) {
      throw const ExcecaoCadastro(
        'Faltam dados do veículo. Volta ao passo anterior e completa-os.',
      );
    }
    if (atual.documentosEmFalta.isNotEmpty) {
      throw const ExcecaoCadastro(
        'Faltam fotografias. Envia todas antes de submeter.',
      );
    }
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
        TipoDocumento.fotoMotorista: 'foto_motorista',
        TipoDocumento.veiculoFrente: 'veiculo_frente',
        TipoDocumento.veiculoTraseira: 'veiculo_traseira',
        TipoDocumento.cartaConducao: 'carta_conducao',
      };

  static const Map<TipoVeiculo, String> _tiposVeiculo = <TipoVeiculo, String>{
    TipoVeiculo.mota: 'mota',
    TipoVeiculo.txopela: 'txopela',
    TipoVeiculo.carro: 'carro',
    TipoVeiculo.camioneta: 'camioneta',
  };

  final SupabaseClient _cliente;

  /// O servidor identifica o motoqueiro por `auth.uid()`; o [telefone] fica
  /// na interface só por causa da implementação simulada.
  @override
  Future<Motoqueiro?> cadastroAtual(String telefone) {
    return _protegido(
      _carregar,
      porOmissao: 'Não foi possível carregar o teu cadastro. Tenta de novo.',
    );
  }

  @override
  Future<Motoqueiro> guardarDadosPessoais({
    required String telefone,
    required TipoVeiculo tipoVeiculo,
    required String nomeCompleto,
    required String email,
  }) {
    return _protegido(() async {
      final Map<String, Object?> dados = <String, Object?>{
        'tipo_veiculo': _tiposVeiculo[tipoVeiculo],
        'nome_completo': nomeCompleto,
        'email': email,
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
    }, porOmissao: 'Não foi possível guardar os teus dados. Tenta de novo.');
  }

  @override
  Future<Motoqueiro> guardarDadosVeiculo({
    required String matricula,
    required String cor,
    String? marca,
    String? modelo,
  }) {
    return _protegido(
      () async {
        await _cliente
            .from('motoqueiros')
            .update(<String, Object?>{
              'matricula': matricula,
              'cor': cor,
              'marca': marca,
              'modelo': modelo,
            })
            .eq('id', _idAtual);
        return _carregarObrigatorio();
      },
      porOmissao:
          'Não foi possível guardar os dados do veículo. Tenta de novo.',
    );
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
      // XFile lê tanto um ficheiro no telemóvel como um `blob:` no browser.
      final XFile ficheiro = XFile(caminho);
      final String contentType =
          (ficheiro.mimeType ?? caminho).toLowerCase().contains('png')
          ? 'image/png'
          : 'image/jpeg';
      await _cliente.storage
          .from(_bucket)
          .uploadBinary(
            caminhoStorage,
            await ficheiro.readAsBytes(),
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          );
      await _cliente.from('documentos').upsert(<String, Object?>{
        'motoqueiro_id': _idAtual,
        'tipo': tipoServidor,
        'caminho_storage': caminhoStorage,
        'enviado_em': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'motoqueiro_id,tipo');
      return _carregarObrigatorio();
    }, porOmissao: 'Não foi possível enviar a fotografia. Tenta de novo.');
  }

  @override
  Future<Motoqueiro> submeterParaAprovacao() {
    return _protegido(() async {
      await _cliente.rpc<dynamic>('submeter_cadastro');
      return _carregarObrigatorio();
    }, porOmissao: 'Não foi possível submeter o cadastro. Tenta de novo.');
  }

  String get _idAtual {
    final User? utilizador = _cliente.auth.currentUser;
    if (utilizador == null) {
      throw const ExcecaoCadastro(
        'A tua sessão terminou. Entra de novo com o teu número.',
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
        'Não encontrámos o teu cadastro. Preenche os teus dados para continuar.',
      );
    }
    return motoqueiro;
  }

  Motoqueiro _deLinha(Map<String, dynamic> linha) {
    final Map<String, TipoDocumento> tiposPorNome = <String, TipoDocumento>{
      for (final MapEntry<TipoDocumento, String> e in _tiposDocumento.entries)
        e.value: e.key,
    };
    final TipoVeiculo tipoVeiculo = _tiposVeiculo.entries
        .firstWhere(
          (MapEntry<TipoVeiculo, String> e) => e.value == linha['tipo_veiculo'],
          orElse: () =>
              const MapEntry<TipoVeiculo, String>(TipoVeiculo.mota, 'mota'),
        )
        .key;
    final List<dynamic> documentos =
        linha['documentos'] as List<dynamic>? ?? <dynamic>[];
    final String? submetidoEm = linha['submetido_em'] as String?;
    return Motoqueiro(
      id: linha['id'] as String,
      telefone: telefoneLocal(_cliente.auth.currentUser?.phone),
      tipoVeiculo: tipoVeiculo,
      nomeCompleto: linha['nome_completo'] as String,
      email: linha['email'] as String? ?? '',
      matricula: linha['matricula'] as String?,
      cor: linha['cor'] as String?,
      marca: linha['marca'] as String?,
      modelo: linha['modelo'] as String?,
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
