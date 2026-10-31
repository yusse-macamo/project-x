create extension if not exists postgis with schema extensions;

create schema if not exists privado;

create type public.estado_verificacao as enum ('incompleto', 'pendente', 'aprovado', 'rejeitado');
create type public.tipo_documento as enum ('carta_conducao', 'livrete', 'bilhete_identidade', 'selfie');
create type public.tipo_veiculo as enum ('camioneta', 'txopela', 'mota', 'carro');
create type public.estado_corrida as enum ('pedida', 'aceite', 'em_curso', 'terminada', 'cancelada');

-- Um perfil por número de telefone. Não guarda "passageiro" ou "motoqueiro":
-- a mesma pessoa pode usar as duas apps. Ser motoqueiro é ter uma linha em
-- public.motoqueiros.
create table public.perfis (
  id uuid primary key references auth.users (id) on delete cascade,
  telefone text unique,
  nome text check (nome is null or char_length(nome) between 3 and 80),
  url_foto text,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

create table public.motoqueiros (
  id uuid primary key references public.perfis (id) on delete cascade,
  nome_completo text not null check (char_length(nome_completo) between 3 and 120),
  numero_bi text not null unique,
  bairro text not null,
  distrito text not null,
  contacto_emergencia text not null,
  tipo_veiculo public.tipo_veiculo not null default 'mota',
  matricula text unique,
  marca text,
  modelo text,
  cor text,
  ano_fabrico smallint check (ano_fabrico between 1970 and 2100),
  estado_verificacao public.estado_verificacao not null default 'incompleto',
  motivo_rejeicao text,
  submetido_em timestamptz,
  verificado_em timestamptz,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

create table public.documentos (
  motoqueiro_id uuid not null references public.motoqueiros (id) on delete cascade,
  tipo public.tipo_documento not null,
  caminho_storage text not null,
  enviado_em timestamptz not null default now(),
  primary key (motoqueiro_id, tipo)
);

create table public.tarifas (
  tipo_veiculo public.tipo_veiculo primary key,
  base numeric(10, 2) not null check (base >= 0),
  por_km numeric(10, 2) not null check (por_km >= 0),
  distancia_minima_km numeric(6, 2) not null default 0.5 check (distancia_minima_km >= 0),
  atualizado_em timestamptz not null default now()
);

insert into public.tarifas (tipo_veiculo, base, por_km) values
  ('mota', 30, 15),
  ('txopela', 40, 12),
  ('carro', 70, 22),
  ('camioneta', 150, 35);

-- O histórico de passageiros e motoqueiros é esta tabela. "on delete restrict"
-- impede que apagar uma conta apague corridas de outra pessoa.
create table public.corridas (
  id uuid primary key default gen_random_uuid(),
  passageiro_id uuid not null references public.perfis (id) on delete restrict,
  motoqueiro_id uuid references public.motoqueiros (id) on delete restrict,
  tipo_veiculo public.tipo_veiculo not null,
  origem extensions.geography(point, 4326) not null,
  origem_nome text,
  destino extensions.geography(point, 4326) not null,
  destino_nome text,
  distancia_km numeric(8, 2) not null check (distancia_km >= 0),
  preco_estimado numeric(10, 2) not null check (preco_estimado >= 0),
  preco_final numeric(10, 2) check (preco_final >= 0),
  estado public.estado_corrida not null default 'pedida',
  cancelada_por uuid references public.perfis (id) on delete set null,
  motivo_cancelamento text check (char_length(motivo_cancelamento) <= 300),
  pedida_em timestamptz not null default now(),
  aceite_em timestamptz,
  iniciada_em timestamptz,
  terminada_em timestamptz,
  cancelada_em timestamptz
);

create index corridas_passageiro_idx on public.corridas (passageiro_id, pedida_em desc);
create index corridas_motoqueiro_idx on public.corridas (motoqueiro_id, pedida_em desc);
create index corridas_pedidas_origem_idx on public.corridas using gist (origem) where estado = 'pedida';
create unique index corridas_uma_ativa_por_passageiro on public.corridas (passageiro_id)
  where estado in ('pedida', 'aceite', 'em_curso');
create unique index corridas_uma_ativa_por_motoqueiro on public.corridas (motoqueiro_id)
  where estado in ('aceite', 'em_curso');

create table public.eventos_corrida (
  id bigint generated always as identity primary key,
  corrida_id uuid not null references public.corridas (id) on delete cascade,
  estado public.estado_corrida not null,
  autor_id uuid references public.perfis (id) on delete set null,
  ocorrido_em timestamptz not null default now()
);

create index eventos_corrida_corrida_idx on public.eventos_corrida (corrida_id, ocorrido_em);

create table public.avaliacoes (
  corrida_id uuid not null references public.corridas (id) on delete cascade,
  autor_id uuid not null references public.perfis (id) on delete cascade,
  avaliado_id uuid not null references public.perfis (id) on delete cascade,
  nota smallint not null check (nota between 1 and 5),
  comentario text check (char_length(comentario) <= 500),
  criada_em timestamptz not null default now(),
  primary key (corrida_id, autor_id)
);

create index avaliacoes_avaliado_idx on public.avaliacoes (avaliado_id);

-- Só a última posição de cada motoqueiro; o percurso não é guardado.
create table public.posicoes_motoqueiro (
  motoqueiro_id uuid primary key references public.motoqueiros (id) on delete cascade,
  posicao extensions.geography(point, 4326) not null,
  disponivel boolean not null default false,
  atualizada_em timestamptz not null default now()
);

create index posicoes_disponiveis_idx on public.posicoes_motoqueiro using gist (posicao) where disponivel;
