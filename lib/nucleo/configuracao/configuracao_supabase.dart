/// Credenciais do Supabase, passadas na compilação e nunca gravadas no
/// repositório:
///
/// ```
/// flutter run --dart-define-from-file=env/dev.json
/// ```
///
/// Sem elas, a app usa os repositórios simulados.
abstract final class ConfiguracaoSupabase {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String chavePublicavel = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get configurado => url.isNotEmpty && chavePublicavel.isNotEmpty;
}
