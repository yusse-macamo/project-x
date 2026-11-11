enum Ambiente { desenvolvimento, producao }

/// Ambiente de compilação, lido de `AMBIENTE` no ficheiro de `env/`:
///
/// ```
/// flutter run --flavor passageiro --dart-define-from-file=env/dev.json
/// flutter build appbundle --flavor passageiro --dart-define-from-file=env/prod.json
/// ```
///
/// Sem `AMBIENTE`, assume desenvolvimento. Em produção a app recusa arrancar
/// sem Supabase, para nunca chegar à loja uma versão com dados simulados.
abstract final class ConfiguracaoAmbiente {
  static const String _valor = String.fromEnvironment('AMBIENTE');

  static Ambiente get atual =>
      _valor == 'prod' ? Ambiente.producao : Ambiente.desenvolvimento;

  static bool get producao => atual == Ambiente.producao;
}
