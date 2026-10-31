# MotoTáxi Inhambane

App de mototáxi para a província de Inhambane. Liga passageiros a mototaxistas,
com preço calculado pela distância. Expansão futura: transporte de mercadorias
entre produtores e transportadores.

Duas aplicações partilham esta base de código: **passageiro** e **motoqueiro**.

## Stack

- Flutter 3.x / Dart 3, null safety, Material 3
- Riverpod 2 (`Notifier` / `NotifierProvider`) — sem geração de código
- GoRouter para navegação
- Backend previsto: Supabase (Postgres + PostGIS + Auth + Storage)
- Sem dependências novas sem me perguntares primeiro

## Idioma

- **Todo o código em português**: pastas, ficheiros, classes, variáveis, métodos.
- Ficheiros em `snake_case`, classes em `PascalCase`.
- Prefixos por camada: `Ecra…`, `Controlador…`, `Repositorio…`, `Estado…`.
- Strings visíveis ao utilizador **com acentuação correta** (português europeu):
  "Introduza o código", não "Introduza o codigo".
- Comentários só onde a intenção não é óbvia. Sem comentários a narrar código.

## Estrutura

```
lib/
  nucleo/           tema, utilitários, constantes — sem dependências de features
  rotas/            rotas_app.dart (GoRouter)
  partilhado/       widgets reutilizáveis pelas duas apps
  funcionalidades/
    <nome>/
      dominio/          entidades puras, sem imports de Flutter
      dados/            repositórios (interface + implementações) e providers
      apresentacao/
        ecras/          um ficheiro por ecrã
        controladores/  Notifier + classe de estado
        widgets/        widgets só desta funcionalidade
```

Uma funcionalidade nunca importa de `apresentacao/` de outra funcionalidade.
Se for preciso partilhar, o widget sobe para `partilhado/`.

## Regras de arquitetura

1. **Navegação conduzida pelo estado.** Nenhum ecrã chama `context.go()` para
   mudar de fase. O controlador publica uma fase e o `redirect` do GoRouter
   traduz a fase numa rota. `context.push()` só para ecrãs empilhados
   (detalhe, definições).

   Aviso: o `redirect` em `rotas/rotas_app.dart` força sempre a rota
   canónica da fase atual, sem exceção para rotas empilhadas — não
   distingue "estou numa rota de nível de fase diferente" de "estou num
   ecrã empilhado por cima da rota certa". Enquanto só existirem as cinco
   rotas de fase da autenticação, isto não tem efeito visível. Assim que
   entrarem ecrãs empilhados (`/cadastro/...` no sprint 2, ou qualquer
   `context.push()`), o `redirect` vai precisar de ignorar rotas que não
   sejam de nível de fase, ou vai devolver o utilizador à rota canónica
   sempre que ele tentar abrir um desses ecrãs.
2. **Repositórios atrás de interfaces.** Cada funcionalidade define
   `abstract interface class Repositorio…`. As implementações simuladas ficam
   no mesmo ficheiro enquanto o Supabase não estiver ligado. Trocar de
   implementação nunca pode obrigar a mexer num ecrã.
3. **Estado imutável.** Classe de estado com campos `final` e `copiarCom(...)`.
   Nunca mutar campos do estado.
4. **Nada de lógica de negócio em widgets.** Cálculo de preço, validação e
   decisões de fluxo vivem no controlador ou no domínio.
5. **Preço e atribuição do motoqueiro serão calculados no servidor.** O cliente
   nunca decide o valor final — só o apresenta.
6. **Duas apps, um ponto de entrada cada.** `passageiro` e `motoqueiro` não
   são uma escolha dentro da app — são dois pontos de entrada separados
   (`lib/main_passageiro.dart` e `lib/main_motoqueiro.dart`), cada um a
   chamar `arrancarApp(TipoAplicacao.…)` com o seu tipo fixo, sobreposto
   uma única vez em `tipoAplicacaoProvider` dentro do `ProviderScope`.
   `lib/main.dart` aponta para o de passageiro, para `flutter run` sem
   argumentos continuar a funcionar. Para correr a app do motoqueiro:

   ```
   flutter run -t lib/main_motoqueiro.dart
   ```

   Nenhum ecrã pergunta nem decide o tipo de utilizador. O `tipoAplicacaoProvider`
   só influencia como o `Utilizador` é criado (`RepositorioAutenticacaoSimulado`
   lê-o uma vez, no arranque). O `redirect` em `rotas/rotas_app.dart` nunca lê
   `tipoAplicacaoProvider` diretamente — decide sempre pelo `tipo` do
   `Utilizador` autenticado, que é a fonte de verdade para a navegação.

## Regras de UI

- Cores **apenas** de `CoresApp` ou de `Theme.of(context).colorScheme`.
  Nunca `Color(0xFF…)` fora de `nucleo/tema/cores_app.dart`.
- Reutilizar `BotaoPrincipal`, `BotaoSecundario`, `CampoTexto`, `EstadoVazio`,
  `IndicadorCarregamento` antes de criar widgets novos.
- Margem lateral de ecrã: 24. Espaço entre blocos: 32. Entre elementos
  relacionados: 8 ou 12.
- Raio de canto: 8 para controlos, 12 para cartões.
- Todos os ecrãs funcionam em tema claro e escuro. Verificar sempre os dois.
- Todo o ecrã que carrega dados tem três estados visíveis: a carregar, erro
  (com forma de repetir) e vazio.
- Erros dizem o que aconteceu e o que fazer. Sem "Erro:" à frente, sem pedidos
  de desculpa, sem texto de exceção cru.
- Rótulos de botões são verbos: "Continuar", "Enviar documentos", "Aceitar".

## Fluxo de trabalho

- Antes de escrever, apresenta o plano: ficheiros a criar, a alterar, e porquê.
  Espera pela minha confirmação.
- Um ecrã de cada vez. Não avances para o seguinte sem eu confirmar.
- No fim de cada ecrã corre `flutter analyze` e resolve tudo o que aparecer.
- Nunca alteres `pubspec.yaml` sem me dizeres antes.
- Não escrevas testes a menos que eu peça.
- Se uma especificação estiver ambígua, pergunta em vez de assumir.

## Estado atual

Sprint 1 concluído (docs/especificacao-sprint1.md): tema, rotas, widgets
partilhados e ciclo de autenticação por telemóvel (splash, número, código,
completar perfil, início) a funcionar sem backend. Todos os critérios de
aceitação verificados — análise estática (`flutter analyze` limpo, sem
`Color(0xFF…)` fora de `cores_app.dart`, strings acentuadas) e teste manual
no emulador (fluxo completo, código errado, logout, retroceder, tema claro
e escuro). O repositório de autenticação está simulado — código de
verificação `123456`.

Durante os testes manuais foi corrigido um bug no `CampoCodigo`: partilhar
o mesmo `FocusNode` entre um `KeyboardListener` e o `TextField` de cada
caixa causava colisão de `GlobalKey<EditableTextState>` interna do Flutter.
Substituído por um único `TextField` invisível sobreposto a seis caixas
visuais — ver `funcionalidades/autenticacao/apresentacao/widgets/campo_codigo.dart`.

Sprint 2 (cadastro do motoqueiro, docs/especificacao-telas.md) em curso.
Feitos: domínio, repositório, controlador, e a Tela 1
(`EcraCadastroPassoDados`). Ainda sem rotas de cadastro ligadas — o ecrã
existe mas não está alcançável por navegação normal (ver nota no
`CLAUDE.md` sobre isso ser tratado de propósito mais tarde, todo de uma
vez, por causa do aviso sobre ecrãs empilhados na regra 1).

Nesta tela nasceram utilitários novos, reutilizáveis pelas telas
seguintes: `nucleo/constantes/distritos_inhambane.dart`,
`nucleo/utilitarios/formatadores.dart` (capitalização, maiúsculas), e
`CampoTexto` (partilhado/) passou a validar ao perder o foco em vez de
nunca validar. `IndicadorPasso` e `CampoSelecao` (folha inferior) ficam em
`cadastro_motoqueiro/apresentacao/widgets/`, para as Telas 2 e 3
reutilizarem.

Tela 2 (`EcraCadastroPassoMota`) feita. O "retroceder sem perder dados"
ficou resolvido com `ControladorCadastro.voltarPara(FaseCadastro)` — força
a fase para trás sem `Navigator.pop()`, o mesmo padrão do
`voltarAoNumero()` da autenticação. Isto resolve de vez o aviso da regra 1
sobre ecrãs empilhados *para o fluxo de cadastro*: os 3 passos são todos
rotas de fase (nunca empilhadas), e recuar é sempre uma mudança de fase
explícita, nunca navegação de pilha. O aviso na regra 1 mantém-se válido
para outros ecrãs empilhados futuros (detalhe, definições).

`CampoTexto` (partilhado/) ganhou `aoPerderFoco` e `estilo` (usados pela
matrícula: normalização ao sair do campo, espaçamento monoespaçado).
Assunções por falta de especificação exata, a confirmar: formato da
matrícula `AAA 000 XX` (3 letras, 3 dígitos, 2 letras) em
`Validadores.validarMatricula`; lista de cores em
`nucleo/constantes/cores_veiculo.dart`.

Tela 3 (`EcraCadastroPassoDocumentos`) feita — a mais complexa do sprint.
Nasceu `dados/selector_imagem.dart` (`SelectorImagem` + implementação
simulada, 500 ms, caminho falso). Este ecrã não usa `ref.listen`: cada ação
(`enviarDocumento`, `submeterParaAprovacao`) é chamada com `await`
diretamente no `onTap`/diálogo, e o resultado é lido logo a seguir via
`ref.read` — mais direto do que o padrão de `ref.listen` + `SnackBar`
usado nas Telas 1 e 2, porque aqui o erro tem de ir para o cartão certo
(por documento), não para um `SnackBar` genérico. Sem miniatura real (os
caminhos são falsos) — mostra só um ícone de imagem genérico quando
"enviado". Sem botão de retroceder — a spec desta tela não o pede.

Tela 4 (`EcraAguardaAprovacao`) feita — três estados no mesmo widget,
escolhidos com `switch (estado.fase)`. Consulta o repositório a cada 15s
só enquanto `pendente` (o temporizador cancela-se sozinho assim que a fase
muda). Duas coisas por ligar a sério mais tarde, ambas com `SnackBar`
placeholder por agora: "Falar com o suporte" (sem canal de contacto
definido em lado nenhum da spec) e "Começar a trabalhar" (a Tela 5 /
`/motoqueiro` ainda não existem). "Corrigir dados" usa uma heurística por
palavras-chave no `motivoRejeicao` para escolher o passo (mota/documentos/
dados por omissão) — não há forma de testar isto a sério porque o
repositório simulado nunca produz `rejeitado`.

Tela 5 (`EcraPainelMotoqueiro`, esqueleto) feita: interruptor
online/offline (estado local, sem persistir), dois cartões de métrica com
valores fixos, cartão de subscrição semanal, `NavigationBar` de 4 abas
(rótulos inventados — Início/Corridas/Ganhos/Perfil — a spec não os dá).
As outras 3 abas não têm ecrã próprio ainda; mudar de aba só realça o
ícone, o corpo não muda. Sem Riverpod nesta tela — é só esqueleto visual,
sem dados reais.

Sprint 2 fechado: rotas de cadastro acrescentadas a `Rotas` e o `redirect`
em `rotas_app.dart` passou a combinar fase de autenticação + fase de
cadastro, exatamente pela tabela pedida. `_NotificadorFaseAutenticacao`
foi renomeado para `_NotificadorNavegacao` e agora ouve os dois
controladores (autenticação e cadastro).

Duas coisas importantes por trás disto:

1. **`FaseCadastro.inicial` → `/cadastro/dados`.** Um motoqueiro
   autenticado sem cadastro ainda carregado (`EstadoCadastro` no valor
   inicial) é enviado para a Tela 1, cujo `initState` já chama
   `verificarCadastro()` sozinho — o mesmo truque do `EcraSplash` na
   autenticação, sem precisar de um ecrã de arranque dedicado para o
   cadastro.
2. **`aprovacaoConfirmada` em `EstadoCadastro`.** Sem isto, o redirect
   forçaria `/motoqueiro` no instante em que a fase passasse a `aprovado`
   (a sondagem de 15s na Tela 4 apanharia isso), e o motoqueiro nunca
   chegaria a ver o ecrã "Está aprovado" — o botão "Começar a trabalhar"
   fica-lhe a ligar. Agora `aprovado` só resolve para `/motoqueiro` depois
   de `ControladorCadastro.confirmarAprovacao()` correr (chamado pelo
   botão). Fica a `false` de novo sempre que `submeterParaAprovacao` for
   chamado outra vez. Isto liga finalmente o botão da Tela 4 a sério — já
   não é placeholder.

**Resolvido:** o tipo de utilizador já não é fixo. `lib/nucleo/tipo_aplicacao.dart`
(`TipoAplicacao`, `tipoAplicacaoProvider`), `lib/arranque.dart`
(`arrancarApp`), `lib/main_passageiro.dart` e `lib/main_motoqueiro.dart` são
os dois pontos de entrada (ver regra 6 de "Regras de arquitetura").
`RepositorioAutenticacaoSimulado` lê `tipoAplicacaoProvider` uma vez, no
arranque, e cria o `Utilizador` com o `TipoUtilizador` correspondente. O
`redirect` continua a decidir só pelo `tipo` do `Utilizador` autenticado —
`tipoAplicacaoProvider` não é lido em `rotas_app.dart`. Agora dá para
testar o fluxo de cadastro a sério: `flutter run -t lib/main_motoqueiro.dart`.

Antes do sprint 3a, a paleta mudou de âmbar para um tema de praia de
Vilankulos: `CoresApp.primaria`/`primariaEscura`/`primariaClara`/
`onPrimaria` (turquesa do mar, substitui `ambar*`) e
`destaque`/`destaqueEscura`/`destaqueClara`/`onDestaque` (coral do
pôr-do-sol, nova segunda cor — antes era só um tom do âmbar). Neutros
também mudaram: fundo claro para tom de areia, fundo escuro para "noite de
oceano". `onPrimary` do tema passou de texto escuro para branco, porque o
turquesa é mais escuro que o âmbar antigo. Sem ficheiros de imagem nem
dependências novas — só constantes em `cores_app.dart` e o `ColorScheme`
em `tema_app.dart`.

Sprint 3a (localização e mapa, docs/especificacao-sprint3a.md) fechado.
Secções 1 e 2: `pubspec.yaml` com `flutter_map`, `latlong2`, `geolocator`,
`http`; permissões de localização e internet no `AndroidManifest.xml`;
`minSdkVersion` já cumpria o mínimo de 21 sem alterações
(`flutter.minSdkVersion` = 24 nesta versão do Flutter). Domínio em
`funcionalidades/localizacao/dominio/`: `Coordenada` (Haversine em
`dart:math`, sem Flutter), `Local`/`TipoLocal`, `ExcecaoLocalizacao`/
`ExcecaoPesquisa`. Falta configurar o `Info.plist` do iOS (a spec só cobre
Android) — sinalizado, não feito, à espera de instrução.

Secções 3 a 6: `EstadoPermissaoLocalizacao` (dominio), os dois
repositórios (`RepositorioLocalizacao` com implementação real via
`geolocator` e uma simulada; `RepositorioLugares` com implementação real
via Nominatim, com limite de 1 pedido/segundo aplicado no próprio
repositório, e uma simulada com uma dúzia de locais reais de
Inhambane/Maxixe/Vilankulos) e `ControladorMapa`/`EstadoMapa`. O debounce
de 600ms da pesquisa não fica no repositório — fica num controlador
próprio (`ControladorPesquisaDestino`, feito com a Tela 9), com um
contador de geração para descartar respostas atrasadas de pedidos já
cancelados.

Telas 7 a 10 feitas. Duas coisas nasceram na Tela 7, fora da lista de
métodos original da spec, por necessidade concreta ao construir o ecrã:
`EstadoMapa.podeContinuarSemPosicao` (mesmo padrão do `aprovacaoConfirmada`
do cadastro — sem isto o redirect nunca saberia que o utilizador escolheu
avançar sem GPS) e `ControladorMapa.abrirDefinicoesApp()`/
`abrirDefinicoesLocalizacao()` (o ecrã nunca toca no repositório
diretamente). O ecrã observa o ciclo de vida da app (`WidgetsBindingObserver`)
para voltar a verificar a permissão quando a app regressa do ecrã de
definições do sistema, porque o `Future` do `geolocator` ao abrir essas
definições resolve assim que a alavanca dispara, não quando o utilizador
volta. A Tela 10 (`EcraAjustarPonto`) não tem controlador próprio — só
`setState` local, porque não há decisão de negócio, só uma chamada ao
repositório e mostrar o resultado (mesmo espírito do padrão sem
`ref.listen` da Tela 3 do cadastro). O menu da Tela 8 e os atalhos
"Casa"/"Trabalho" ficam como placeholder (`SnackBar` "Em breve") — não há
ainda repositório de favoritos nem drawer nesta app.

Secção 11 fechada: `/permissao-localizacao`, `/pesquisa-destino` e
`/ajustar-ponto` acrescentadas a `Rotas`, com `rotasEmpilhadas` a marcar as
duas últimas como empilhadas — o `redirect` devolve `null` de imediato para
elas, sem forçar a rota canónica. Um passageiro autenticado só chega a
`/inicio` se `EstadoMapa.permissao` for `concedida` ou
`podeContinuarSemPosicao` for `true`; caso contrário fica em
`/permissao-localizacao`. Esta gate é só do passageiro — o motoqueiro não é
afetado. `_NotificadorNavegacao` passa a ouvir também `controladorMapaProvider`
(pelos campos `permissao` e `podeContinuarSemPosicao`, mesmo padrão do
`fase`+`aprovacaoConfirmada` do cadastro). O campo "Para onde vai?" no mapa
e a linha "Escolher no mapa" na pesquisa já navegam a sério
(`context.push`) e devolvem o `Local` escolhido pela cadeia de ecrãs
empilhados.

Duas coisas por pedido explícito, fora da spec original: o ecrã de splash
(`EcraSplash`) mostra agora o wordmark **"VilaMova"** sobre uma estrada
costeira ao entardecer desenhada em `CustomPaint` (sem imagem, só cores do
`CoresApp`) — isto é só o ecrã de abertura; o nome do produto continua
"MotoTáxi Inhambane" em todo o resto. E o centro por omissão do mapa (sem
posição real) e a coordenada da posição simulada
(`RepositorioLocalizacaoSimulado`) passaram de Inhambane-cidade para
Vilankulos (-21.9833, 35.3167), em `EcraMapaInicio`, `EcraAjustarPonto` e
no repositório simulado.

Terceira coisa fora da spec, por pedido explícito: seletor de tipo de
veículo com preço estimado, no mapa. `TipoVeiculo` (domínio puro, em
`funcionalidades/inicio/dominio/`) tem 4 valores — camioneta ("Cargas"),
txopela ("Viagem"), mota ("Viagem mais rápida") e carro ("Viagem mais
confortável") — cada um com ícone Material (sem imagens nem dependências
novas). `RepositorioPrecos` (interface + `RepositorioPrecosSimulado`, em
`funcionalidades/inicio/dados/`) estima o preço por tipo a partir da
distância (Haversine) entre a posição atual e o destino, com tarifa base +
por km e um mínimo de 0,5 km faturados. Isto respeita a regra 5 do
`CLAUDE.md`: o preço mostrado é sempre uma estimativa de um repositório
simulado, nunca calculado à mão no ecrã — quando o Supabase estiver
ligado, troca-se só a implementação. `ControladorMapa.escolherDestino()`
passou a assíncrono para pedir a estimativa assim que o destino é
escolhido, com um controlo simples de resposta desatualizada (compara o
destino antes e depois do `await`). O botão "Pedir viagem" já mostra o
preço do veículo selecionado e o spinner de carregamento do
`BotaoPrincipal` enquanto a estimativa não chega — mas continua sem criar
uma corrida a sério, porque isso é o ciclo completo do sprint 3b.

Backend Supabase, passo 1 (migrações) feito, ainda sem projeto criado nem
`supabase_flutter` no `pubspec.yaml`. Três migrações em `supabase/migrations/`:
`esquema` (tabelas), `funcoes` (RPCs e gatilhos) e `seguranca` (RLS, grants,
storage, realtime). Decisões que importam para o código Dart:

- `perfis` **não tem tipo**. Um telefone = um utilizador do Supabase Auth, e a
  mesma pessoa pode usar as duas apps. Ser motoqueiro = ter linha em
  `motoqueiros`. O `Utilizador.tipo` continua a vir do ponto de entrada
  (`tipoAplicacaoProvider`), como no repositório simulado.
- O histórico é a tabela `corridas` (filtrada por `passageiro_id` ou
  `motoqueiro_id`), mais `eventos_corrida` (auditoria, preenchida por
  gatilho) e `avaliacoes`.
- A app nunca escreve em `corridas`, `posicoes_motoqueiro` nem no estado de
  verificação do motoqueiro — só através de RPCs (`pedir_corrida`,
  `aceitar_corrida`, `submeter_cadastro`, …). O preço é calculado no
  servidor a partir da tabela `tarifas` (mesmos valores que
  `RepositorioPrecosSimulado`).
- `estimar_precos` recebe **coordenadas**, não distância — o servidor
  calcula a distância. A interface `RepositorioPrecos` terá de mudar quando
  for ligada.
- Erros de negócio vêm como exceção com mensagem-chave estável
  (`corrida_ativa_existente`, `documentos_em_falta`, `transicao_invalida`,
  …), para a app traduzir para português.
- A aprovação de motoqueiros é feita fora da app (painel do Supabase /
  `service_role`).

Validado num Postgres 16 + PostGIS local com imitações de `auth`/`storage`:
RLS (um terceiro utilizador não vê nada), ciclo completo de uma corrida,
cadastro e avaliações.

Backend Supabase, passos 3 a 5 (ligação na app) feitos. `pubspec.yaml`
ganhou `supabase_flutter` e `image_picker`. Credenciais por
`--dart-define-from-file=env/dev.json` (`SUPABASE_URL`,
`SUPABASE_PUBLISHABLE_KEY`; modelo em `env/dev.exemplo.json`, os reais
ignorados pelo git) — `nucleo/configuracao/configuracao_supabase.dart`.
**Sem as chaves, tudo continua simulado** (código `123456`): cada provider de
repositório, e o `selectorImagemProvider`, escolhem a implementação por
`ConfiguracaoSupabase.configurado`. `arrancarApp` só chama
`Supabase.initialize` quando configurado.

- `nucleo/supabase/cliente_supabase.dart`: `clienteSupabaseProvider`,
  conversão de telefone local ↔ E.164 e `traduzirErroSupabase()` (chaves de
  negócio, BI/matrícula duplicados, códigos de Auth, Storage, rede). Os
  repositórios reais apanham tudo e relançam como a exceção de domínio
  (`ExcecaoAutenticacao`, `ExcecaoCadastro`, `ExcecaoPrecos`), por isso os
  controladores não mudaram.
- `RepositorioAutenticacaoSupabase`: OTP por SMS, nome em `perfis`.
- `RepositorioCadastroSupabase`: `motoqueiros` (insert/update separados —
  `id` não tem grant de UPDATE, por isso não há upsert), documentos no bucket
  `documentos` em `<uid>/<tipo>` + linha em `documentos`, submissão pela RPC.
  O parâmetro `telefone` de `cadastroAtual` é ignorado (o servidor usa
  `auth.uid()`).
- `RepositorioPrecos.estimarPrecos` recebe agora `origem`/`destino`
  (`Coordenada`); `ControladorMapa` mostra a falha em `EstadoMapa.erro`.
- `SelectorImagemDispositivo` (`image_picker`, máx. 2048 px, JPEG 85).

`Info.plist` do iOS já tem `NSCameraUsageDescription` e
`NSPhotoLibraryUsageDescription` e `NSLocationWhenInUseUsageDescription`
(só "durante o uso" — não há localização em segundo plano).

Recusa de acesso à câmara/galeria tratada na Tela 3: `SelectorImagemDispositivo`
converte os `PlatformException` do `image_picker` em `ExcecaoSelectorImagem`
(`dominio/excecao_selector_imagem.dart`, com `MotivoFalhaImagem`). Sem acesso
→ diálogo com "Cancelar", a outra origem ("Escolher da galeria"/"Tirar
fotografia") e "Abrir definições" (`SelectorImagem.abrirDefinicoesApp()`,
via `Geolocator.openAppSettings()` — sem dependência nova). Sem câmara ou
erro desconhecido → `SnackBar`. No Android a recusa quase não acontece (o
manifesto não declara `CAMERA`); no iOS é o caso normal depois de recusar
uma vez.

Por fazer/verificar: teste manual contra um projeto real (ainda não feito).

Passa a atualizar esta secção sempre que fechares uma secção da
especificação — não esperes pelo fim do sprint.
