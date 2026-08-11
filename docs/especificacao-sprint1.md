# Especificação — sprint 1: fundação e autenticação

Ponto de partida: projeto Flutter acabado de criar, `lib/` com apenas o
`main.dart` gerado. Nada mais existe.

Objetivo do sprint: ter tema, navegação, widgets partilhados e o ciclo completo
de autenticação por telemóvel a funcionar sem backend.

Constrói pela ordem das secções. Cada secção é uma tarefa fechada: só avança
depois de eu confirmar.

---

## 1. Dependências

Acrescentar ao `pubspec.yaml`:

```yaml
dependencies:
  flutter_riverpod: ^2.5.1
  go_router: ^14.2.0

dev_dependencies:
  flutter_lints: ^4.0.0
```

Criar `analysis_options.yaml` a incluir `package:flutter_lints/flutter.yaml`,
com `prefer_single_quotes`, `require_trailing_commas` e
`always_declare_return_types` ativos.

---

## 2. Paleta — `nucleo/tema/cores_app.dart`

Classe `abstract final class CoresApp` com constantes. É o único ficheiro do
projeto onde pode existir um literal `Color(0xFF…)`.

**Marca:** âmbar `0xFFEF9F27`, âmbar escuro `0xFF854F0B`, âmbar claro `0xFFFAEEDA`.

**Semânticas:** sucesso `0xFF639922`, sucesso claro `0xFFEAF3DE`,
erro `0xFFA32D2D`, erro claro `0xFFFCEBEB`, aviso `0xFFBA7517`.

**Neutros tema claro:** fundo `0xFFF7F5F0`, superfície `0xFFFFFFFF`,
superfície alternativa `0xFFF1EFE8`, texto `0xFF1C1B18`,
texto secundário `0xFF5F5E5A`, borda `0xFFE2E0D8`.

**Neutros tema escuro:** fundo `0xFF141311`, superfície `0xFF1F1E1B`,
superfície alternativa `0xFF2A2926`, texto `0xFFF3F1EC`,
texto secundário `0xFFA3A199`, borda `0xFF35342F`.

---

## 3. Tema — `nucleo/tema/tema_app.dart`

`abstract final class TemaApp` com `ThemeData get claro` e `ThemeData get escuro`,
ambos construídos por um método privado que recebe o `Brightness`.

- Material 3 ativo. `ColorScheme` construído explicitamente (não por
  `fromSeed`), com o âmbar como `primary` e o texto escuro como `onPrimary` —
  o âmbar é claro demais para texto branco por cima.
- `AppBar` transparente, sem elevação e sem `surfaceTint`, alinhada à esquerda.
- `InputDecorationTheme`: preenchido, raio 8, borda de foco a âmbar com 1,5 de
  espessura, `counterText` vazio.
- `FilledButtonTheme`: altura mínima 52, raio 8, fundo âmbar.
- `OutlinedButtonTheme` com a mesma altura e borda neutra.
- `CardTheme` com raio 12, sem elevação, borda de 1.
- Constantes públicas `raio = 12` e `raioPequeno = 8`.

**Critério:** trocar `CoresApp.ambar` por outra cor muda o aspeto de todo o app
sem tocar em mais nenhum ficheiro.

---

## 4. Validadores — `nucleo/utilitarios/validadores.dart`

`abstract final class Validadores`:

- `indicativo` = `'+258'`.
- `telefoneValido(String)` — 9 dígitos, começados por 82 a 87.
- `validarTelefone(String?)` — devolve `null` ou mensagem: campo vazio,
  número incompleto, número inválido. Mensagens acentuadas.
- `validarNome(String?)` — mínimo três caracteres e pelo menos um espaço.
- `apenasDigitos(String)`.
- `formatarTelefone(String)` — `841234567` passa a `+258 84 123 4567`.

---

## 5. Widgets partilhados — `partilhado/widgets/`

| Ficheiro | Widget | Notas |
|---|---|---|
| `botao_principal.dart` | `BotaoPrincipal` | texto, `aoPremir` opcional, `aCarregar`, ícone opcional. Enquanto carrega mostra indicador circular e ignora toques |
| `botao_principal.dart` | `BotaoSecundario` | versão com contorno |
| `campo_texto.dart` | `CampoTexto` | rótulo por cima do campo, dica, prefixo, validador, formatadores, `aoMudar`, `autoFoco` |
| `indicador_carregamento.dart` | `IndicadorCarregamento` | centrado, com mensagem opcional |
| `estado_vazio.dart` | `EstadoVazio` | ícone, título, descrição e ação opcional. O texto é um convite a agir, não um "nada aqui" |

Nenhum destes widgets conhece Riverpod nem rotas.

---

## 6. Domínio — `funcionalidades/autenticacao/dominio/utilizador.dart`

- `enum TipoUtilizador { passageiro, motoqueiro }`
- `class Utilizador` com id, telefone, nome opcional, urlFoto opcional, tipo.
  Getters `perfilCompleto` (nome com três ou mais caracteres) e `primeiroNome`.
  Método `copiarCom`.
- `class ExcecaoAutenticacao implements Exception` com uma mensagem já pronta
  para mostrar ao utilizador.

Sem imports de Flutter neste ficheiro.

---

## 7. Repositório — `funcionalidades/autenticacao/dados/repositorio_autenticacao.dart`

```dart
abstract interface class RepositorioAutenticacao {
  Future<Utilizador?> sessaoAtual();
  Future<void> pedirCodigo(String telefone);
  Future<Utilizador> confirmarCodigo({required String telefone, required String codigo});
  Future<Utilizador> guardarNome({required Utilizador utilizador, required String nome});
  Future<void> terminarSessao();
}
```

`RepositorioAutenticacaoSimulado`: guarda a sessão em memória, atraso de 900 ms
em cada operação, código aceite `123456`. Códigos errados lançam
`ExcecaoAutenticacao` com "Código incorreto. Tente de novo".

No fim do ficheiro, `repositorioAutenticacaoProvider` a devolver a
implementação simulada. Trocar para Supabase deve ser mudar só esta linha.

---

## 8. Controlador — `funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart`

```dart
enum FaseAutenticacao { inicial, semSessao, aguardaCodigo, perfilIncompleto, autenticado }
```

`EstadoAutenticacao`: fase, telefone, utilizador, `aProcessar`, erro. Campos
`final`, método `copiarCom` com um parâmetro `limparErro`.

`ControladorAutenticacao extends Notifier<EstadoAutenticacao>`, `build()`
devolve o estado inicial e **não faz trabalho assíncrono**.

Métodos: `verificarSessao`, `pedirCodigo`, `reenviarCodigo`, `confirmarCodigo`,
`guardarNome`, `terminarSessao`, `voltarAoNumero`, `limparErro`.

Cada método assíncrono liga `aProcessar`, limpa o erro anterior, apanha
`ExcecaoAutenticacao` e guarda a mensagem no estado. Nunca deixa `aProcessar`
ligado depois de falhar.

---

## 9. Rotas — `rotas/rotas_app.dart`

`abstract final class Rotas` com `splash = '/'`, `login = '/entrar'`,
`verificacao = '/verificacao'`, `completarPerfil = '/perfil'`,
`inicio = '/inicio'`.

`roteadorProvider` devolve um `GoRouter` com:

- um `ChangeNotifier` privado que ouve o controlador e notifica quando a **fase**
  muda (não a cada alteração de estado), usado como `refreshListenable`;
- um `redirect` que traduz a fase numa rota e devolve `null` quando já lá está:

```
inicial          → /
semSessao        → /entrar
aguardaCodigo    → /verificacao
perfilIncompleto → /perfil
autenticado      → /inicio
```

Nenhum ecrã chama `context.go()` para mudar de fase.

---

## 10. Ecrã 1 — `EcraSplash`

Consumer com estado. Em `initState`, dentro de `addPostFrameCallback`, chama
`verificarSessao()`.

Visual: quadrado âmbar de 88 com raio 24 e o ícone `two_wheeler` em texto
escuro, nome do app, subtítulo "Inhambane", e um indicador de progresso por
baixo. Tudo centrado.

---

## 11. Ecrã 2 — `EcraLoginTelefone`

**Objetivo:** recolher o número.

Título "O seu número". Subtítulo: "Enviamos um código por SMS para confirmar
que o número é seu."

Um `CampoTexto` com rótulo "Número de telemóvel", dica `84 123 4567`, teclado
numérico, máximo 9 dígitos, prefixo fixo `+258` e apenas dígitos aceites.

O botão "Continuar" só fica ativo quando o número é válido, e mostra o estado
de carregamento durante o pedido. Por cima do botão, uma linha pequena sobre
termos e privacidade.

Erros do controlador aparecem em `SnackBar`, através de um `ref.listen` que
compara com o erro anterior para não repetir.

---

## 12. Ecrã 3 — `EcraVerificacaoOtp`

**Objetivo:** confirmar o código.

Widget próprio em `apresentacao/widgets/campo_codigo.dart`: seis caixas de um
dígito, avanço automático de foco ao escrever, recuo ao apagar numa caixa
vazia, borda âmbar quando preenchida. Ao completar os seis dígitos, submete
sozinho — sem botão.

Cabeçalho com botão de retroceder que chama `voltarAoNumero()`.

Subtítulo mostra o número formatado. Contador de 60 segundos; enquanto corre,
texto "Reenviar código em N s"; terminado, botão de texto "Reenviar código".
Durante a verificação, mostra indicador e desativa as caixas.

---

## 13. Ecrã 4 — `EcraCompletarPerfil`

Título "Como se chama?". Subtítulo: "O motoqueiro vê o seu nome para o
encontrar no ponto de recolha." Um campo de nome completo com validação, e
botão "Concluir".

---

## 14. Ecrã 5 — `EcraMapaInicio` (marcador de posição)

`funcionalidades/inicio/apresentacao/ecras/`. `AppBar` com "Olá, {primeiroNome}"
e ação de terminar sessão. Corpo com `EstadoVazio` a explicar que o mapa entra
no sprint 3.

Serve para fechar o ciclo e permitir testar o logout.

---

## 15. `main.dart`

`ProviderScope` na raiz, `MaterialApp.router` com tema claro, escuro e
`ThemeMode.system`, `debugShowCheckedModeBanner` a falso, orientação fixa em
retrato, e `MediaQuery.withClampedTextScaling` com máximo 1.3.

---

## Critérios de aceitação

1. `flutter analyze` sem avisos.
2. `flutter run` arranca no splash e vai parar ao login.
3. Número válido + `123456` leva a completar perfil e depois ao início.
4. Código errado mostra mensagem e deixa tentar de novo.
5. Terminar sessão volta ao login.
6. Retroceder no ecrã do código volta ao número, sem ficar preso.
7. Tudo legível em tema claro e escuro.
8. Nenhum literal `Color(0xFF…)` fora de `cores_app.dart`.
9. Todas as strings visíveis ao utilizador acentuadas corretamente.
