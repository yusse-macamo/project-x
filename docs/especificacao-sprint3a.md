# Especificação — sprint 3a: localização e mapa

Primeiro sprint com dependências externas reais: GPS, mapas e um serviço de
pesquisa de moradas. Nada aqui envolve corridas — o objetivo é o passageiro
abrir a app, ver-se no mapa e escolher um destino.

O ciclo da corrida e o cálculo de preço ficam para o sprint 3b.

Funcionalidade: `lib/funcionalidades/localizacao/` (serviços de posição e
lugares) e `lib/funcionalidades/inicio/` (os ecrãs).

---

## 1. Dependências

```yaml
dependencies:
  flutter_map: ^7.0.2
  latlong2: ^0.9.1
  geolocator: ^12.0.0
  http: ^1.2.0
```

Não acrescentes mais nada sem me perguntares. Em particular, não uses
`permission_handler` — o `geolocator` já cobre o que precisamos e evita uma
segunda fonte de verdade sobre permissões.

### Configuração nativa

`android/app/src/main/AndroidManifest.xml`, dentro de `<manifest>`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

`minSdkVersion` mínimo 21. Não acrescentes ainda permissões de segundo plano —
essas pertencem à app do motoqueiro, no sprint 4, e pedidas cedo demais
prejudicam a aprovação na Play Store.

---

## 2. Domínio — `funcionalidades/localizacao/dominio/`

`coordenada.dart`:

```dart
class Coordenada {
  const Coordenada({required this.latitude, required this.longitude});
  // operator ==, hashCode, toString
  // double distanciaEmMetrosAte(Coordenada outra)  -> Haversine
}
```

O cálculo de Haversine fica aqui, em Dart puro, sem imports de Flutter. Serve
de recurso quando não houver rota disponível — nunca substitui a distância de
rota para efeitos de preço.

`local.dart`:

```dart
class Local {
  final String nome;          // 'Mercado Central'
  final String? descricao;    // 'Maxixe, Inhambane'
  final Coordenada coordenada;
  final TipoLocal tipo;       // pesquisado, favorito, recente, pontoNoMapa
}

enum TipoLocal { pesquisado, favorito, recente, pontoNoMapa }
```

`excecoes.dart`: `ExcecaoLocalizacao` e `ExcecaoPesquisa`, ambas com mensagem
pronta para mostrar ao utilizador.

---

## 3. Estado das permissões

```dart
enum EstadoPermissaoLocalizacao {
  desconhecido,
  concedida,
  negada,            // pode voltar a pedir
  negadaPermanente,  // só nas definições do sistema
  servicoDesligado,  // GPS desligado no telemóvel
}
```

Os três últimos são situações distintas com saídas distintas. Tratá-los como
um só "sem permissão" é o erro clássico e deixa o utilizador sem caminho.

---

## 4. Repositório de localização — `dados/repositorio_localizacao.dart`

```dart
abstract interface class RepositorioLocalizacao {
  Future<EstadoPermissaoLocalizacao> verificarPermissao();
  Future<EstadoPermissaoLocalizacao> pedirPermissao();
  Future<Coordenada> posicaoAtual();
  Stream<Coordenada> acompanharPosicao();
  Future<void> abrirDefinicoesApp();
  Future<void> abrirDefinicoesLocalizacao();
}
```

`RepositorioLocalizacaoGeolocator` é a implementação real.

- `posicaoAtual` com precisão `high` e tempo limite de 15 segundos. Se
  expirar, tenta a última posição conhecida antes de falhar.
- `acompanharPosicao` com `distanceFilter: 20` metros. **Não** transmitir
  continuamente: cada atualização custa bateria e, mais à frente, dados
  móveis.
- Erros do `geolocator` são convertidos em `ExcecaoLocalizacao` com mensagem
  em português. Nenhuma exceção do pacote sobe até à camada de apresentação.

Mantém também `RepositorioLocalizacaoSimulado`, que devolve uma coordenada
fixa em Inhambane-cidade (-23.865, 35.383) e permite escolher o estado de
permissão a devolver. É o que permite trabalhar nos ecrãs sem depender do
emulador.

---

## 5. Repositório de lugares — `dados/repositorio_lugares.dart`

```dart
abstract interface class RepositorioLugares {
  Future<List<Local>> pesquisar(String termo, {Coordenada? perto});
  Future<Local?> localEmCoordenada(Coordenada coordenada);
}
```

`RepositorioLugaresNominatim` usa a API pública do OpenStreetMap.

Requisitos não negociáveis, porque a política de uso do serviço é explícita:

- Cabeçalho `User-Agent` próprio e identificável em todos os pedidos.
- No máximo um pedido por segundo. A pesquisa é atrasada em 600 ms desde a
  última tecla, e um pedido novo cancela o anterior.
- Resultados limitados a Moçambique (`countrycodes=mz`) e enviesados para a
  área visível do mapa.
- `limit=8`.
- Memória de resultados recentes por termo, para não repetir pedidos iguais.

**Aviso a manter no código, junto à classe:** o serviço público do Nominatim
não é aceitável para produção com volume real. Antes do lançamento é preciso
instância própria ou fornecedor pago. O mesmo se aplica aos mosaicos do mapa —
os servidores públicos do OpenStreetMap proíbem uso intensivo.

Mantém `RepositorioLugaresSimulado` com uma dúzia de locais reais de Inhambane
e Maxixe, para desenvolvimento sem rede.

---

## 6. Controlador — `apresentacao/controladores/controlador_mapa.dart`

`EstadoMapa`: estado da permissão, posição atual (`Coordenada?`), a carregar,
erro, destino escolhido (`Local?`).

`ControladorMapa extends Notifier<EstadoMapa>` com: `iniciar()`,
`pedirPermissao()`, `actualizarPosicao()`, `escolherDestino(Local)`,
`limparDestino()`.

Como no sprint 1, `build()` não faz trabalho assíncrono — quem arranca é o
ecrã.

---

## 7. Ecrã — `EcraPermissaoLocalizacao`

Aparece quando a permissão não está concedida. Um ecrã, quatro conteúdos:

| Estado | Título | Corpo | Ação |
|---|---|---|---|
| negada | Precisamos da sua localização | Para lhe mostrar os mototaxistas mais próximos e calcular o preço até ao destino | Permitir |
| negadaPermanente | Localização bloqueada | A permissão foi recusada e só pode ser reactivada nas definições do telemóvel | Abrir definições |
| servicoDesligado | GPS desligado | Ligue a localização no seu telemóvel para continuar | Ligar localização |
| a pedir | — | indicador de carregamento | — |

Em todos os casos, uma ação secundária discreta: "Escolher a origem no mapa",
que permite avançar sem GPS. Não deixes ninguém preso neste ecrã — em muitos
telemóveis de gama baixa o GPS demora ou falha, e uma app que não deixa
continuar perde o utilizador nesse momento.

---

## 8. Ecrã — `EcraMapaInicio` (substitui o marcador de posição)

**Corpo:** `FlutterMap` a ocupar o ecrã, com:
- camada de mosaicos do OpenStreetMap, com `userAgentPackageName` definido;
- marcador da posição atual (círculo âmbar com anel claro);
- atribuição do OpenStreetMap visível — é obrigatória pela licença, e não pode
  ser removida nem escondida atrás de um toque.

**Sobreposto:** botão de menu no canto superior esquerdo; botão de recentrar
no canto inferior direito, acima da folha.

**Folha inferior fixa**, com cerca de um terço do ecrã: saudação com o
primeiro nome, campo "Para onde vai?" que abre a pesquisa, e duas linhas de
atalho (casa e trabalho, ou destinos recentes).

**Estados:** enquanto não há posição, o mapa aparece centrado em
Inhambane-cidade com um indicador discreto no topo; se a localização falhar,
uma barra fina com a mensagem e um botão "Tentar de novo" — nunca um ecrã de
erro em página inteira, porque o mapa continua a ser útil sem posição.

---

## 9. Ecrã — `EcraPesquisaDestino`

Aberto com `context.push()`, e não por mudança de fase — é um ecrã empilhado,
que devolve um `Local` ao fechar.

Campo de pesquisa no topo com foco automático. Por baixo, uma lista que muda
com o estado:

- **campo vazio:** favoritos e destinos recentes;
- **a escrever, menos de 3 caracteres:** mantém a lista anterior, sem pesquisar;
- **a pesquisar:** três linhas cinzentas de esqueleto, não um indicador central;
- **com resultados:** nome a cheio, descrição por baixo em texto secundário;
- **sem resultados:** `EstadoVazio` com a ação "Escolher no mapa";
- **erro de rede:** mensagem curta e botão "Tentar de novo", mantendo o que
  o utilizador já escreveu.

No fim da lista, sempre, uma linha "Escolher no mapa" que abre o ecrã seguinte.

---

## 10. Ecrã — `EcraAjustarPonto`

Mapa com um pino fixo no centro do ecrã — o mapa move-se por baixo do pino,
não o contrário. É mais fácil de acertar com uma mão só.

Enquanto o mapa se move, o cartão inferior mostra "A obter morada"; parado,
faz geocodificação inversa e mostra a morada. Botão "Confirmar" devolve o
`Local` ao ecrã anterior.

---

## 11. Rotas

Acrescentar `/permissao-localizacao` como rota de fase, e
`/pesquisa-destino` e `/ajustar-ponto` como rotas empilhadas.

**Isto obriga a rever o `redirect`**, pela ressalva já registada na secção
"Regras de arquitetura" do `CLAUDE.md`: hoje ele força sempre a rota canónica
da fase, o que expulsaria o utilizador de qualquer ecrã empilhado.

Solução pedida: `Rotas` passa a expor um conjunto `rotasEmpilhadas`, e o
`redirect` devolve `null` de imediato quando a rota atual pertence a esse
conjunto. Mostra-me o `redirect` alterado antes de aplicares.

---

## Critérios de aceitação

1. `flutter analyze` sem avisos.
2. Com permissão concedida, o mapa abre centrado na posição real.
3. Recusar a permissão leva ao ecrã correspondente, e "Permitir" volta a
   pedir; recusar duas vezes leva ao ecrã de definições.
4. Com o GPS desligado, aparece o ecrã do serviço desligado, não o da
   permissão negada.
5. É possível chegar ao fim do fluxo sem GPS, pela opção de escolher no mapa.
6. A pesquisa não dispara antes de 600 ms de pausa nem com menos de 3 letras.
7. Sem rede, a pesquisa mostra erro com repetição e não deita a app abaixo.
8. Abrir a pesquisa e voltar atrás não expulsa o utilizador do mapa.
9. A atribuição do OpenStreetMap está visível no mapa.
10. Tudo legível em tema claro e escuro.
