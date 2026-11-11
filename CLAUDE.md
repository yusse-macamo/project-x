# ROTA (MotoTáxi Inhambane)

App de mototáxi para a província de Inhambane, com o nome de produto **ROTA**.
Liga passageiros a mototaxistas, com preço por zona ou por distância, sempre
decidido no servidor. Expansão futura: transporte de mercadorias
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
- Strings visíveis ao utilizador **com acentuação correta**, a tratar por "tu",
  com a linguagem das maquetes da ROTA: "Introduz o código", não "Introduz o
  codigo". Evitar género nas frases sobre o motoqueiro ("Traz o troco", não "Ele
  traz o troco").
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
6. **Uma só app, passageiro e motorista escolhidos dentro dela.** Depois do
   código, `FaseAutenticacao.escolherTipo` leva a `/tipo`
   (`EcraEscolherTipo`): "Sou passageiro" ou "Sou motorista". A escolha fica
   em `Utilizador.tipo` (`null` = ainda não escolheu), guardada por
   `RepositorioAutenticacao.guardarTipo` (no Supabase, `perfis.papel`:
   `passageiro`/`motorista`). Muda-se pelo menu com
   `mudarTipoComConfirmacao` (menu ☰ do passageiro; separador Perfil e ecrã
   de aprovação do motorista). O `redirect` decide sempre pelo `tipo` do
   `Utilizador` autenticado. Um só ponto de entrada, `lib/main.dart`; no
   Android há um único flavor, `passageiro` (id `mz.rota.passageiro`, nome
   "ROTA"), mantido para não mudar o id já instalado:

   ```
   flutter run --flavor passageiro --dart-define-from-file=env/dev.json
   ```

   Ordem das fases: código → escolher tipo → nome (se faltar) → mapa ou
   cadastro do motorista.

## Regras de UI

- Cores **apenas** de `CoresApp` ou de `Theme.of(context).colorScheme`.
  Nunca `Color(0xFF…)` fora de `nucleo/tema/cores_app.dart`.
- Reutilizar `BotaoPrincipal`, `BotaoSecundario`, `CampoTexto`, `EstadoVazio`,
  `IndicadorCarregamento` antes de criar widgets novos.
- Margem lateral de ecrã: 24. Espaço entre blocos: 32. Entre elementos
  relacionados: 8 ou 12.
- Raio de canto: 12 para controlos (`TemaApp.raioPequeno`), 16 para cartões
  (`TemaApp.raio`).
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

Navegação para trás e terminar sessão (pedido explícito, fora de spec):

- Todos os ecrãs de fase com recuo têm seta **e** `PopScope(canPop: false)`
  a chamar o mesmo método do controlador — sem isto o voltar do sistema
  Android fechava a app, porque cada fase substitui a rota anterior.
  Código → número (`voltarAoNumero`); completar perfil → confirmação +
  `terminarSessao`; cadastro dados → `ControladorCadastro.voltarDoPrimeiroPasso()`
  (volta ao ecrã de rejeitado se veio corrigir; senão confirmação +
  terminar sessão); mota → dados; documentos → mota (bloqueado durante
  envios). Mapa e painel do motoqueiro são raiz: o voltar sai da app (no
  painel, primeiro regressa ao separador Início).
- Terminar sessão: menu lateral do mapa (`_MenuLateral`, substitui o
  placeholder do botão ☰), separador Perfil do painel do motoqueiro, e
  ícone no AppBar do ecrã de aguardar aprovação (pendente e rejeitado).
  Diálogo partilhado em `partilhado/widgets/dialogo_confirmacao.dart`.
- `ControladorCadastro` e `ControladorMapa` observam o id do utilizador
  autenticado no `build()` — mudar de sessão repõe o estado inicial, para
  ninguém herdar cadastro/destino de outra pessoa no mesmo telemóvel.
- `RepositorioAutenticacao.codigoDeTeste` (`'123456'` no simulado, `null`
  no Supabase): o ecrã do código mostra uma faixa "Modo de teste" só
  quando não há SMS real. Os separadores Corridas/Ganhos do motoqueiro
  mostram `EstadoVazio` em vez do corpo do Início.

Interfaces ROTA (11 maquetes, pedido explícito, fora de spec). O nome passa a
ROTA em toda a app, incluindo o splash (substitui "VilaMova") e o nome em
Android/iOS. Paleta: azul-marinho, amarelo, verde-azulado, terracota e creme
(substitui turquesa/coral). Funcionalidades novas: `capulana/`, `corrida/`,
`paragens/`, `voz/`, mais `inicio/dominio/praca.dart`.

- Navegação: a viagem é toda por fase. Destino escolhido sem corrida →
  `/corrida/escolher`; depois `FaseCorrida` → `/corrida/a-caminho`,
  `/corrida/em-viagem`, `/corrida/avaliar`. No motoqueiro, `FaseMotoqueiro` →
  `/motoqueiro/pedido`, `/motoqueiro/corrida`. Empilhadas: sinal, capulana,
  gravar paragem, pesquisa, ajustar ponto. O `EcraCorridaMotoqueiro` (código de
  subida e terminar) não está nas maquetes: existe para o fluxo não ficar sem
  saída depois de aceitar.
- **Tudo o que é novo está simulado, mesmo com o Supabase configurado**, porque
  o servidor ainda não tem estas colunas: `repositorioCorridaProvider`,
  `repositorioPedidosMotoqueiroProvider`, paragens, praças, capulana (só em
  memória) e voz. Motoqueiro "Abílio", coordenadas dos marcos e tabela por zona
  são dados de exemplo. `modoDeTeste` faz aparecer `FaixaModoTeste` nos ecrãs
  de corrida. Com Supabase, os preços são reais mas só por quilómetro:
  `suportaTabelaPorZona` e `extraCargaMt` escondem a zona e a carga.
- Sem dependências novas, `pubspec.yaml` intacto: capulanas e praia em
  `CustomPaint` (`FundoCapulana`, `_PintorPraia`), veículos com ícones, letra do
  sistema, mapa real com filtro de cor (não o ilustrado das maquetes).
- Incompleto de propósito: **SOS não envia alerta** (o diálogo di-lo, e tem de
  ser ligado antes de uso real); notas de voz só contam o tempo; Ligar e
  WhatsApp copiam para a área de transferência; "Brilho no máximo" só dá uma
  indicação; PT/EN só traduz o ecrã de entrada; `ContactosApp.linhaPedidos` é
  `null` até haver número real.
- Base de dados por alterar: o código de subida não pode ficar em `corridas`,
  porque o motoqueiro tem `select` em todas as colunas da sua corrida.

Verificado com um teste temporário, já apagado: fluxo do passageiro (entrada à
avaliação) e do motoqueiro (pedido a viagem), em 2 tamanhos e nos 2 temas, sem
exceções nem transbordos, mas sem mapa real e sem o tipo de letra real. Durante
isso, `confirmarSubida`/`concluir` deixaram de esperar pelo `cancel()` da
subscrição, porque o `await` prendia o fluxo no teste.

Por fazer/verificar: teste manual contra um projeto real (ainda não feito);
teste manual no telemóvel das interfaces ROTA e das alterações de navegação
(a instalação falhou — ver conversa); textos do cadastro revistos só por
pesquisa de palavras.

Plano para produção (7 fases, aprovado): 1 fundações, 2 cadastro para todos
os veículos, 3 corridas reais com Realtime, 4 ecrãs em falta, 5 segurança e
comunicação, 6 painel de administração, 7 acabamento.

Fase 1 feita (Android): flavors `passageiro`/`motorista` com ids `mz.rota.*`
e nomes por `manifestPlaceholders["nomeApp"]` (o `resValue` está desligado no
AGP atual); namespace e `MainActivity` em `mz.rota`. `TipoAplicacao.sabor`
liga cada ponto de entrada ao seu flavor. `AMBIENTE` (`dev`/`prod`) em
`env/*.json` → `ConfiguracaoAmbiente`; em `prod` a app recusa arrancar sem
Supabase. Assinatura de release por `android/key.properties` (modelo em
`key.properties.exemplo`); sem ele, o release usa a chave de debug. iOS
ainda com um único alvo (`com.example.projectx`): os esquemas por flavor
precisam de um Mac. Ainda simulados mesmo em `prod` até à fase 3: corrida,
pedidos, GPS, lugares, paragens, praças, capulana e voz.

Passa a atualizar esta secção sempre que fechares uma secção da
especificação — não esperes pelo fim do sprint.

Ecrã principal do passageiro simplificado (pedido explícito): mapa em ecrã
inteiro, botão ☰, pílula "Perto de…", botão de recentrar e uma folha em baixo
com "Para onde vais?". Saíram a barra de separadores, o botão "Fala", o bloco
das praças, os chips de paragens, o "Rede fraca? Pede por SMS" e a capulana.
Perfil, viagens e paragens passaram para o menu lateral, como rotas
empilhadas (`/conta/perfil`, `/conta/viagens`, `/conta/paragens`). O
`redirect` só deixa passar rotas empilhadas com sessão iniciada — senão
terminar sessão a partir do Perfil deixava o utilizador nesse ecrã.
`terminarSessaoComConfirmacao` (em `aba_perfil.dart`) é partilhado pelo menu
e pelo Perfil.

Código por SMS ou WhatsApp (pedido explícito): `CanalCodigo` em
`autenticacao/dominio/`. A escolha fica só no ecrã do código: "Entrar" no ecrã
do número chama `continuarParaCodigo(telefone)`, que muda de fase **sem
enviar**; o ecrã do código pergunta "Como queres receber o código?" e só então
`enviarCodigo(canal)` envia e põe `EstadoAutenticacao.codigoEnviado` a `true`
(a contagem de 60 s começa aí). Depois da contagem, "Reenviar por SMS" e
"Reenviar por WhatsApp". No Supabase passa a
`signInWithOtp(channel: OtpChannel.whatsapp)`; a confirmação continua com
`OtpType.sms`. **O WhatsApp só funciona com o remetente de WhatsApp do Twilio
configurado no painel do Supabase** — por fazer. No simulado, os dois canais
aceitam `123456`.

Pedido de viagem num só ecrã (pedido explícito): `EcraEscolherViagem` e a rota
`/corrida/escolher` foram apagados; `FaseCorrida.semCorrida` resolve sempre
para `/inicio`. A folha em baixo do mapa (`inicio/apresentacao/widgets/
folha_pedido_viagem.dart`) mostra "Para onde vais?" e os três veículos; com
destino, mostra a linha do destino (✕ limpa), preços por veículo, forma de
pagamento, "Mais opções" (zona, carga, barco, nota) e "Pedir …". O mapa
desenha a rota e enquadra-a. Com destino, o voltar do sistema limpa o destino.
Sem faixa de capulana no ecrã principal. Nota: `EcraMapaInicio` e a folha
importam `controladorCorridaProvider` de `corrida/apresentacao/` — já
acontecia antes, mas contraria a regra de não importar de `apresentacao/` de
outra funcionalidade; resolver se o controlador mudar de sítio.

Veículos com fotografias reais (pedido explícito): `assets/veiculos/`
(`mota.jpg`, `txopela.jpg`, `taxi.jpg`, 600×400, recortadas de fotos da
Wikimedia Commons sob CC BY-SA 4.0). `pubspec.yaml` ganhou a secção `assets:`
(sem dependências novas). `IlustracaoVeiculo` mostra a foto em 3:2 com cantos
arredondados, e `tamanho` passou a ser a altura (por omissão 48, antes 56 de
ícone). A camioneta continua com ícone. A licença obriga a mostrar os
créditos: `nucleo/constantes/creditos_imagens.dart` + `EcraCreditosImagens`
(`/conta/creditos-imagens`, no menu lateral). Ao trocar ou acrescentar fotos,
atualizar essa lista.

Uma só app (pedido explícito, substitui as duas apps da Fase 1):
`TipoAplicacao`, `tipoAplicacaoProvider`, `main_passageiro.dart`,
`main_motoqueiro.dart` e o flavor `motorista` foram removidos. Escolha de tipo
em `/tipo` (ver regra 6). Migração `20261108000004_papel.sql` acrescenta
`perfis.papel` — aplicada no projeto Supabase (11/11/2026). A instalação antiga
"ROTA Motorista" (`mz.rota.motorista`) fica no telemóvel até ser desinstalada
à mão.

Cadastro do motorista por veículo (pedido explícito). Depois do código,
`/tipo` mostra 4 opções diretas: Passageiro, Mototaxista, Txopelista,
Taxista (as três últimas guardam `TipoUtilizador.motoqueiro` e põem o veículo
em `EstadoCadastro.tipoVeiculo`). Cada tipo tem a sua rota de fase com um só
formulário (`EcraCadastroMotorista(tipo:)`): `/cadastro/mota`,
`/cadastro/txopela`, `/cadastro/taxi`. Todos: nome, email, cor, placa, foto
do motorista, veículo de frente, de trás com a placa; txopela e táxi + carta
de condução; táxi + marca e modelo (`documentosExigidos`, `exigeMarcaModelo`
no domínio). As fotos ficam locais até "Enviar para aprovação", que faz
`ControladorCadastro.enviarParaAprovacao`: guarda dados → veículo → envia
fotos → submete, e pára no primeiro erro. `FaseCadastro` ficou
`inicial/formulario/pendente/rejeitado/aprovado`; `/cadastro`
(`EcraCadastroACarregar`) só aparece a quem volta sem tipo escolhido nesta
sessão. Recuar do formulário volta à escolha
(`ControladorAutenticacao.voltarAEscolherTipo`, e `cancelarEscolhaTipo`
regressa onde estava). No menu do passageiro: "Trabalhar como motorista".
Saíram BI, bairro, distrito, contacto de emergência, livrete, ano de fabrico,
`distritos_inhambane.dart`, `IndicadorPasso` e os 3 ecrãs de passos. Migração
`20261108000005_cadastro_por_veiculo.sql` — validada num Postgres 16 +
PostGIS local e aplicada no Supabase (11/11/2026). A aprovação continua manual (painel do Supabase).

GPS real e paragens (pedido explícito): `repositorioLocalizacaoProvider` passa
a usar `RepositorioLocalizacaoGeolocator` (o simulado fica só como classe). O
ecrã "Gravar paragem" tem a secção "Onde fica?": ao abrir pede a posição
exata ao GPS e põe o pin lá ("A tua localização atual"); arrastar o mapa muda
para "Ponto escolhido no mapa", com o botão "Usar a minha localização atual".
Saiu a faixa de capulana desse ecrã. Preço mínimo: a mota nunca custa menos de
50 MT — `RepositorioPrecosSimulado._precoMinimo` e migração
`20261108000006_preco_minimo.sql` (`tarifas.preco_minimo`, `calcular_preco`
com `greatest`) — aplicada no Supabase (11/11/2026). O login com Supabase está
ligado (`env/dev.json`), com Twilio Verify; enquanto a conta Twilio for trial,
os números de Moçambique não recebem SMS — usar os números de teste do
Supabase. Sessão guardada: quem já entrou não pede código outra vez; o
splash mostra "Tentar de novo" se a verificação falhar sem internet.

Microfone real (pedido explícito; pacotes aprovados pelo utilizador:
`speech_to_text`, `record`, `just_audio`; `RECORD_AUDIO` + `queries`
RecognitionService no Android, `NSMicrophoneUsageDescription` e
`NSSpeechRecognitionUsageDescription` no iOS). Em "Vais onde?" o microfone
**dita o destino** (`ReconhecedorVoz` + `ControladorDitado`, pt_MZ → pt_PT →
pt_BR): a frase passa por `extrairDestino` ("quero ir ao…" sai),
`ControladorPesquisaDestino.pesquisarPorVoz` pesquisa já e, havendo
resultado, o primeiro é escolhido e o ecrã principal mostra veículos e
preços. A pesquisa simulada de lugares passou a ser palavra a palavra, sem
acentos (`correspondencia_texto.dart`), com desempate pela distância. Em
"Gravar paragem" o `PainelVoz` grava a sério (m4a em `Directory.systemTemp`)
e tem "Ouvir"; saiu o aviso "Modo de teste" e o parâmetro `aoUsar`. A nota de
voz do pedido de corrida (`ControladorCorrida.definirNotaVoz`) deixou de ser
preenchida pela pesquisa. As notas de voz ainda não são enviadas para o
Supabase (ficam no telemóvel).

Destino no ecrã principal (pedido explícito): a folha tem uma caixa de texto
real com o microfone dentro; ao escrever ou ditar, a folha mostra
`ListaLugares`/`ResultadosPesquisa` (agora em
`inicio/apresentacao/widgets/lista_destinos.dart`) e "Marcar no mapa"; ao
escolher, mostra veículos e preços. `EcraPesquisaDestino` só continua a ser
usado por `EcraEmViagem`. O ditado procura primeiro nos marcos e paragens
conhecidos (`pesquisarPorVoz(conhecidos:)`), depois na lista de lugares.
"Perto de: …" só aparece com um marco a menos de 3 km. Crédito do mapa sem o
"flutter_map" ("© OpenStreetMap", obrigatório pela licença). O `PainelVoz` da
paragem tem passos claros: gravar → parar → Ouvir / Gravar de novo / Apagar.

Site público (pedido explícito; plano aprovado: página de apresentação em `/`
+ app Flutter web em `/app/`, alojados no Cloudflare Pages, publicados por
GitHub Actions a cada push para `main`, mesmo Supabase que a app). Passo 1
feito — a app compila para web (`flutter build web --base-href /app/`):
`partilhado/widgets/imagem_local.dart` (`ImagemLocal`: `Image.network` no
browser, onde o `image_picker` devolve `blob:`, e `Image.file` no telemóvel)
substitui os `Image.file` do cadastro, da paragem e da capulana; o envio de
fotos usa `XFile(caminho).readAsBytes()` + `uploadBinary`; o `GravadorVoz`
grava Opus em memória no browser e toca por `setUrl`. Ícones e
`web/index.html`/`manifest.json` com o nome e as cores da ROTA (ícones
gerados: "R" amarelo sobre marinho — provisórios até haver logótipo).
Passo 2 feito — `site/` é HTML estático sem dependências (`index.html`,
`privacidade.html`, `404.html`, `estilo.css` com tema claro/escuro,
`robots.txt`, `sitemap.xml`, `_headers`, `_redirects`). Tem cópias das fotos
de `assets/veiculos/` em `site/imagens/veiculos/` (ao trocar fotos, trocar
nos dois sítios e nos créditos do rodapé) e dos ícones de `web/`. Marcadores
substituídos na publicação: `__ENDERECO_SITE__` (endereço público, sem `/`
final) e `__CONTACTO__` (email da política de privacidade). A app usa
endereços com `#`, por isso `/app/` não precisa de reescrita; `_headers`
põe `/app/*` em `no-cache` para cada publicação chegar logo aos browsers.
Passo 3 feito — `.github/workflows/publicar-site.yml`: a cada push para
`main` (ou à mão), compila a app web com `AMBIENTE=prod` e as chaves do
Supabase dos segredos do GitHub, junta `site/` + `build/web` em `dist/app`,
substitui os marcadores e publica com `wrangler pages deploy` (cria o
projeto na primeira vez). Segredos: `CLOUDFLARE_API_TOKEN`,
`CLOUDFLARE_ACCOUNT_ID`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`.
Variáveis: `CONTACTO_EMAIL` (obrigatória), `CLOUDFLARE_PROJETO` (por
omissão `rota`), `ENDERECO_SITE` (por omissão `https://<projeto>.pages.dev`).
A versão do Flutter está fixada no workflow (3.44.6) — atualizar ao mudar a
local. Verificado localmente (junção e `/app/` a abrir servida por HTTP);
ainda não corrido no GitHub. A app web abre ao público já com corridas
simuladas — decisão do utilizador.

Migrações 4, 5 e 6 aplicadas no projeto Supabase em 11/11/2026, coladas
no SQL Editor como um só script com `if not exists`, numa transação (não há
acesso direto à base de dados nem histórico de migrações da CLI). Antes,
validadas num Postgres 16 + PostGIS em Docker com imitações de `auth`/
`storage`: a 000005 tinha `exigidos || 'carta_conducao'` sem `::text`, o
que dava "malformed array literal" e impedia qualquer txopela ou táxi de
submeter o cadastro — corrigido antes de aplicar. Testado: mota submete sem
carta; txopela e táxi dão `documentos_em_falta` sem carta e submetem com
ela; mota numa viagem de 300 m custa 50 MT.
