import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project_x/nucleo/utilitarios/validadores.dart';

/// Só pode ser lido quando `ConfiguracaoSupabase.configurado` é verdadeiro —
/// `Supabase.instance` não existe sem `Supabase.initialize`.
final Provider<SupabaseClient> clienteSupabaseProvider =
    Provider<SupabaseClient>((Ref ref) => Supabase.instance.client);

/// O Supabase Auth guarda o telefone em E.164 sem o "+" ("258841234567");
/// a app trabalha com os 9 dígitos locais.
String telefoneLocal(String? telefoneServidor) {
  final String digitos = Validadores.apenasDigitos(telefoneServidor ?? '');
  final String indicativo = Validadores.apenasDigitos(Validadores.indicativo);
  if (digitos.startsWith(indicativo) &&
      digitos.length == indicativo.length + 9) {
    return digitos.substring(indicativo.length);
  }
  return digitos;
}

String telefoneServidor(String telefoneLocal) =>
    '${Validadores.indicativo}${Validadores.apenasDigitos(telefoneLocal)}';

const String _semLigacao =
    'Sem ligação à internet. Verifica a ligação e tenta de novo.';

/// Chaves de erro de negócio levantadas pelas funções em
/// `supabase/migrations/20261031000002_funcoes.sql`.
const Map<String, String> _errosNegocio = <String, String>{
  'coordenada_invalida':
      'A localização escolhida não é válida. Escolhe outro ponto no mapa.',
  'sessao_invalida': 'A tua sessão terminou. Entra de novo com o teu número.',
  'corrida_ativa_existente':
      'Já tens uma corrida em curso. Termina-a ou cancela-a antes de pedir outra.',
  'cadastro_inexistente':
      'Não encontrámos o teu cadastro. Preenche os teus dados para continuar.',
  'cadastro_ja_submetido': 'O teu cadastro já foi enviado e está em análise.',
  'dados_pessoais_em_falta':
      'Faltam o teu nome ou o teu email. Volta aos teus dados e completa-os.',
  'dados_veiculo_em_falta':
      'Faltam dados do veículo. Volta ao passo do veículo e completa-os.',
  'documentos_em_falta': 'Faltam fotografias. Envia todas antes de submeter.',
  'tipo_veiculo_invalido':
      'Este veículo não pode ser registado. Escolhe mota, txopela ou táxi.',
  'motoqueiro_nao_aprovado': 'O teu cadastro ainda não foi aprovado.',
  'corrida_indisponivel': 'Esta corrida já não está disponível.',
  'transicao_invalida':
      'Esta ação já não é possível nesta corrida. Atualiza e tenta de novo.',
  'avaliacao_ja_feita': 'Já avaliaste esta corrida.',
};

/// Converte qualquer erro do Supabase numa mensagem para o utilizador.
/// [porOmissao] é usada quando o erro não tem tradução específica.
String traduzirErroSupabase(Object erro, {required String porOmissao}) {
  if (erro is SocketException ||
      erro is http.ClientException ||
      erro is TimeoutException ||
      erro is AuthRetryableFetchException) {
    return _semLigacao;
  }
  if (erro is PostgrestException) {
    return _traduzirPostgrest(erro) ?? porOmissao;
  }
  if (erro is AuthException) {
    return _traduzirAuth(erro) ?? porOmissao;
  }
  if (erro is StorageException) {
    return _traduzirStorage(erro) ?? porOmissao;
  }
  return porOmissao;
}

String? _traduzirPostgrest(PostgrestException erro) {
  final String? negocio = _errosNegocio[erro.message];
  if (negocio != null) {
    return negocio;
  }
  if (erro.code == '23505') {
    if (erro.message.contains('matricula')) {
      return 'Esta placa já está registada noutra conta. Confirma a placa.';
    }
  }
  return null;
}

String? _traduzirAuth(AuthException erro) {
  switch (erro.code) {
    case 'otp_expired':
    case 'invalid_credentials':
      return 'Código incorreto ou expirado. Tenta de novo ou pede um novo código.';
    case 'over_sms_send_rate_limit':
    case 'over_request_rate_limit':
      return 'Pediste demasiados códigos. Aguarda um minuto e tenta de novo.';
    case 'sms_send_failed':
      return 'Não foi possível enviar o SMS. Confirma o número e tenta de novo.';
    case 'phone_provider_disabled':
      return 'O envio de códigos por SMS está desligado. Contacta o suporte.';
    case 'session_not_found':
    case 'session_expired':
    case 'refresh_token_not_found':
      return 'A tua sessão terminou. Entra de novo com o teu número.';
  }
  return null;
}

String? _traduzirStorage(StorageException erro) {
  final String mensagem = erro.message.toLowerCase();
  if (erro.statusCode == '413' || mensagem.contains('size')) {
    return 'A imagem é demasiado grande. Escolhe uma com menos de 5 MB.';
  }
  if (erro.statusCode == '415' || mensagem.contains('mime')) {
    return 'Formato não suportado. Usa uma fotografia em JPEG ou PNG.';
  }
  return null;
}
