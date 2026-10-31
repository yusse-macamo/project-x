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
    'Sem ligação à internet. Verifique a ligação e tente de novo.';

/// Chaves de erro de negócio levantadas pelas funções em
/// `supabase/migrations/20261031000002_funcoes.sql`.
const Map<String, String> _errosNegocio = <String, String>{
  'coordenada_invalida':
      'A localização escolhida não é válida. Escolha outro ponto no mapa.',
  'sessao_invalida': 'A sua sessão terminou. Entre de novo com o seu número.',
  'corrida_ativa_existente':
      'Já tem uma corrida em curso. Termine-a ou cancele-a antes de pedir outra.',
  'cadastro_inexistente':
      'Não encontrámos o seu cadastro. Preencha os seus dados para continuar.',
  'cadastro_ja_submetido': 'O seu cadastro já foi enviado e está em análise.',
  'dados_veiculo_em_falta':
      'Faltam dados da mota. Volte ao passo da mota e complete-os.',
  'documentos_em_falta':
      'Faltam documentos. Envie os quatro documentos antes de submeter.',
  'motoqueiro_nao_aprovado': 'O seu cadastro ainda não foi aprovado.',
  'corrida_indisponivel': 'Esta corrida já não está disponível.',
  'transicao_invalida':
      'Esta ação já não é possível nesta corrida. Atualize e tente de novo.',
  'avaliacao_ja_feita': 'Já avaliou esta corrida.',
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
    if (erro.message.contains('numero_bi')) {
      return 'Este número de BI já está registado noutra conta. '
          'Confirme o número.';
    }
    if (erro.message.contains('matricula')) {
      return 'Esta matrícula já está registada noutra conta. '
          'Confirme a matrícula.';
    }
  }
  return null;
}

String? _traduzirAuth(AuthException erro) {
  switch (erro.code) {
    case 'otp_expired':
    case 'invalid_credentials':
      return 'Código incorreto ou expirado. Tente de novo ou peça um novo código.';
    case 'over_sms_send_rate_limit':
    case 'over_request_rate_limit':
      return 'Pediu demasiados códigos. Aguarde um minuto e tente de novo.';
    case 'sms_send_failed':
      return 'Não foi possível enviar o SMS. Confirme o número e tente de novo.';
    case 'phone_provider_disabled':
      return 'O envio de códigos por SMS está desligado. Contacte o suporte.';
    case 'session_not_found':
    case 'session_expired':
    case 'refresh_token_not_found':
      return 'A sua sessão terminou. Entre de novo com o seu número.';
  }
  return null;
}

String? _traduzirStorage(StorageException erro) {
  final String mensagem = erro.message.toLowerCase();
  if (erro.statusCode == '413' || mensagem.contains('size')) {
    return 'A imagem é demasiado grande. Escolha uma com menos de 5 MB.';
  }
  if (erro.statusCode == '415' || mensagem.contains('mime')) {
    return 'Formato não suportado. Use uma fotografia em JPEG ou PNG.';
  }
  return null;
}
