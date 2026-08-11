# Especificação de telas — sprint 2: cadastro do motoqueiro

Funcionalidade: `lib/funcionalidades/cadastro_motoqueiro/`

Cinco telas. Um motoqueiro que acabou de se autenticar pelo telemóvel entra
aqui, preenche três passos, envia documentos e fica à espera de aprovação.
Enquanto não for aprovado, não recebe pedidos.

---

## Domínio

`dominio/motoqueiro.dart`

```dart
enum EstadoVerificacao { incompleto, pendente, aprovado, rejeitado }
enum TipoDocumento { cartaConducao, livrete, bilheteIdentidade, selfie }
```

`Motoqueiro`: id, telefone, nomeCompleto, numeroBi, bairro, distrito,
contactoEmergencia, matricula, marca, modelo, cor, anoFabrico,
estadoVerificacao, motivoRejeicao, documentos (mapa TipoDocumento → caminho),
dataSubmissao. Getter `passoAtual` que devolve o primeiro passo incompleto.

`Documento`: tipo, caminhoLocal, urlRemota, enviado, erro.

O domínio não importa Flutter.

---

## Repositório

`dados/repositorio_cadastro.dart`

```dart
abstract interface class RepositorioCadastro {
  Future<Motoqueiro?> cadastroAtual(String telefone);
  Future<Motoqueiro> guardarDadosPessoais({...});
  Future<Motoqueiro> guardarDadosMota({...});
  Future<Motoqueiro> enviarDocumento({required TipoDocumento tipo, required String caminho});
  Future<Motoqueiro> submeterParaAprovacao();
}
```

Implementação simulada em memória, com atrasos de 800 ms. `enviarDocumento`
falha propositadamente na primeira tentativa do livrete, para o ecrã de
documentos ter de mostrar erro e permitir repetir. `submeterParaAprovacao`
devolve estado `pendente`; ao fim de 20 segundos passa a `aprovado`, para se
poder ver a transição sem backend.

---

## Tela 1 — `EcraCadastroPassoDados`

**Objetivo:** recolher a identidade do motoqueiro.

**Cabeçalho:** indicador de progresso "Passo 1 de 3" com uma barra fina.
Título "Os seus dados". Subtítulo: "Precisamos de confirmar quem conduz a mota."

**Campos**
| Campo | Tipo | Validação |
|---|---|---|
| Nome completo | texto, capitalização de palavras | mínimo nome e apelido |
| Número do BI | texto, maiúsculas | 13 caracteres, formato moçambicano |
| Bairro | texto | não vazio |
| Distrito | seleção | lista dos distritos de Inhambane (ver abaixo) |
| Contacto de emergência | telefone, prefixo +258 | 9 dígitos, 82–87, diferente do próprio número |

Distritos: Inhambane (cidade), Maxixe, Vilankulo, Massinga, Morrumbene,
Homoíne, Jangamo, Zavala, Inharrime, Panda, Funhalouro, Govuro, Inhassoro,
Mabote.

**Comportamento**
- O botão "Continuar" só fica ativo com o formulário válido.
- A validação corre ao perder o foco de cada campo, não a cada tecla.
- O teclado nunca tapa o campo focado — usar `SingleChildScrollView`.
- Ao voltar a este passo, os campos vêm preenchidos com o que já foi guardado.

**Erro:** se `guardarDadosPessoais` falhar, snackbar com a mensagem do
repositório e o botão volta ao estado normal. Nada se perde do formulário.

---

## Tela 2 — `EcraCadastroPassoMota`

**Objetivo:** identificar o veículo.

**Cabeçalho:** "Passo 2 de 3". Título "A sua mota".

**Campos:** matrícula (formato moçambicano, maiúsculas, mostrada em espaçamento
monoespaçado), marca, modelo, cor (seleção), ano de fabrico (seleção, dos
últimos 30 anos até ao atual).

**Comportamento**
- A matrícula é normalizada ao sair do campo: maiúsculas, espaços arrumados.
- Aviso discreto por baixo da matrícula: "O passageiro vê esta matrícula antes
  de embarcar. Confirme que está correta."
- Botão de retroceder no cabeçalho volta ao passo 1 sem perder dados.

---

## Tela 3 — `EcraCadastroPassoDocumentos`

**Objetivo:** enviar quatro documentos. É a tela mais complexa do sprint.

**Cabeçalho:** "Passo 3 de 3". Título "Documentos".

**Corpo:** quatro cartões, um por documento — carta de condução, livrete,
bilhete de identidade, fotografia sua (selfie). Cada cartão mostra:
- ícone, nome do documento e uma linha a dizer o que se espera
  ("Frente e verso legíveis", "Rosto visível, sem óculos escuros")
- estado: por enviar / a enviar (barra de progresso) / enviado (visto verde e
  miniatura) / falhou (texto de erro e botão "Tentar de novo")
- ao tocar num cartão por enviar, abre uma folha inferior com duas opções:
  "Tirar fotografia" e "Escolher da galeria"

**Nesta fase não integres câmara nem galeria.** Cria uma interface
`SelectorImagem` com uma implementação simulada que devolve um caminho falso
após 500 ms. A implementação real entra depois.

**Botão inferior:** "Submeter para aprovação", ativo apenas com os quatro
documentos enviados. Antes de submeter, mostra um diálogo de confirmação com o
resumo: nome, matrícula, número de documentos.

---

## Tela 4 — `EcraAguardaAprovacao`

**Objetivo:** dar destino a quem já submeteu. Três estados no mesmo ecrã.

**Pendente:** ilustração simples (ícone grande), título "Em análise", texto
"Estamos a confirmar os seus documentos. Costuma demorar até 24 horas."
Mostra a data de submissão. Botão secundário "Falar com o suporte".
Faz uma consulta ao repositório a cada 15 segundos para ver se mudou.

**Rejeitado:** cor de erro no cabeçalho, título "Cadastro não aprovado", o
motivo devolvido pelo repositório em destaque, e um botão principal "Corrigir
dados" que devolve ao passo indicado pelo motivo.

**Aprovado:** título "Está aprovado", texto curto, botão "Começar a trabalhar"
que leva ao painel do motoqueiro.

---

## Tela 5 — `EcraPainelMotoqueiro` (esqueleto)

Só o esqueleto nesta fase: interruptor online/offline no topo, dois cartões de
métrica (ganhos de hoje, corridas de hoje) com valores fixos, cartão da
subscrição semanal e navegação inferior de quatro abas. Sem lógica de pedidos.

---

## Rotas

Acrescentar a `Rotas`: `/cadastro/dados`, `/cadastro/mota`,
`/cadastro/documentos`, `/cadastro/aprovacao`, `/motoqueiro`.

O `redirect` passa a considerar também o estado do cadastro quando o utilizador
é do tipo motoqueiro:

```
autenticado + tipo motoqueiro + cadastro incompleto  → passo em falta
autenticado + tipo motoqueiro + pendente/rejeitado   → /cadastro/aprovacao
autenticado + tipo motoqueiro + aprovado             → /motoqueiro
```

Manter a regra: o ecrã não decide para onde vai; o estado decide.

---

## Critérios de aceitação do sprint

1. `flutter analyze` sem avisos.
2. É possível percorrer os três passos, submeter e ver a aprovação chegar.
3. Fechar e reabrir a app retoma no passo correto.
4. Todos os ecrãs legíveis em tema claro e escuro.
5. Nenhuma cor literal fora de `cores_app.dart`.
6. Nenhum `context.go()` dentro de um ecrã para mudar de fase.
