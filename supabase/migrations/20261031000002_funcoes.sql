-- Erros de negócio levantados com errcode P0001 e uma mensagem-chave estável
-- (ex.: 'corrida_ativa_existente'). A app traduz a chave para texto em
-- português; nunca mostra a mensagem crua.

-- ---------------------------------------------------------------------------
-- Gatilhos
-- ---------------------------------------------------------------------------

create function privado.definir_atualizado_em()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.atualizado_em := now();
  return new;
end;
$$;

create trigger perfis_atualizado_em before update on public.perfis
  for each row execute function privado.definir_atualizado_em();
create trigger motoqueiros_atualizado_em before update on public.motoqueiros
  for each row execute function privado.definir_atualizado_em();
create trigger tarifas_atualizado_em before update on public.tarifas
  for each row execute function privado.definir_atualizado_em();

create function privado.criar_perfil()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.perfis (id, telefone) values (new.id, new.phone);
  return new;
end;
$$;

create trigger ao_criar_utilizador after insert on auth.users
  for each row execute function privado.criar_perfil();

create function privado.registar_evento_corrida()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' or new.estado is distinct from old.estado then
    insert into public.eventos_corrida (corrida_id, estado, autor_id)
    values (new.id, new.estado, auth.uid());
  end if;
  return new;
end;
$$;

create trigger corridas_evento after insert or update of estado on public.corridas
  for each row execute function privado.registar_evento_corrida();

-- ---------------------------------------------------------------------------
-- Auxiliares (schema privado: não expostas pela API)
-- ---------------------------------------------------------------------------

create function privado.ponto(latitude double precision, longitude double precision)
returns extensions.geography
language plpgsql
immutable
set search_path = ''
as $$
begin
  if latitude not between -90 and 90 or longitude not between -180 and 180 then
    raise exception using errcode = 'P0001', message = 'coordenada_invalida';
  end if;
  return extensions.st_setsrid(extensions.st_makepoint(longitude, latitude), 4326)::extensions.geography;
end;
$$;

create function privado.motoqueiro_aprovado()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.motoqueiros
    where id = auth.uid() and estado_verificacao = 'aprovado'
  );
$$;

create function privado.calcular_preco(tipo public.tipo_veiculo, distancia_km numeric)
returns numeric
language sql
stable
set search_path = ''
as $$
  select round(t.base + t.por_km * greatest(distancia_km, t.distancia_minima_km), 2)
  from public.tarifas t
  where t.tipo_veiculo = tipo;
$$;

-- ---------------------------------------------------------------------------
-- Passageiro
-- ---------------------------------------------------------------------------

create function public.estimar_precos(
  origem_latitude double precision,
  origem_longitude double precision,
  destino_latitude double precision,
  destino_longitude double precision
)
returns table (tipo_veiculo public.tipo_veiculo, distancia_km numeric, preco numeric)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  distancia numeric := round((extensions.st_distance(
    privado.ponto(origem_latitude, origem_longitude),
    privado.ponto(destino_latitude, destino_longitude)
  ) / 1000)::numeric, 2);
begin
  return query
    select t.tipo_veiculo, distancia, privado.calcular_preco(t.tipo_veiculo, distancia)
    from public.tarifas t;
end;
$$;

create function public.pedir_corrida(
  origem_latitude double precision,
  origem_longitude double precision,
  origem_nome text,
  destino_latitude double precision,
  destino_longitude double precision,
  destino_nome text,
  tipo_veiculo public.tipo_veiculo
)
returns public.corridas
language plpgsql
security definer
set search_path = ''
as $$
declare
  origem extensions.geography := privado.ponto(origem_latitude, origem_longitude);
  destino extensions.geography := privado.ponto(destino_latitude, destino_longitude);
  distancia numeric := round((extensions.st_distance(origem, destino) / 1000)::numeric, 2);
  resultado public.corridas;
begin
  if auth.uid() is null then
    raise exception using errcode = 'P0001', message = 'sessao_invalida';
  end if;

  if exists (
    select 1 from public.corridas c
    where c.passageiro_id = auth.uid() and c.estado in ('pedida', 'aceite', 'em_curso')
  ) then
    raise exception using errcode = 'P0001', message = 'corrida_ativa_existente';
  end if;

  insert into public.corridas (
    passageiro_id, tipo_veiculo, origem, origem_nome, destino, destino_nome,
    distancia_km, preco_estimado
  ) values (
    auth.uid(), pedir_corrida.tipo_veiculo, origem, origem_nome, destino, destino_nome,
    distancia, privado.calcular_preco(pedir_corrida.tipo_veiculo, distancia)
  )
  returning * into resultado;

  return resultado;
end;
$$;

create function public.motoqueiro_da_corrida(corrida_id uuid)
returns table (
  nome text,
  url_foto text,
  telefone text,
  matricula text,
  marca text,
  modelo text,
  cor text,
  tipo_veiculo public.tipo_veiculo
)
language sql
stable
security definer
set search_path = ''
as $$
  select m.nome_completo, p.url_foto, p.telefone, m.matricula, m.marca, m.modelo, m.cor, m.tipo_veiculo
  from public.corridas c
  join public.motoqueiros m on m.id = c.motoqueiro_id
  join public.perfis p on p.id = m.id
  where c.id = motoqueiro_da_corrida.corrida_id
    and c.passageiro_id = auth.uid();
$$;

-- ---------------------------------------------------------------------------
-- Motoqueiro
-- ---------------------------------------------------------------------------

create function public.submeter_cadastro()
returns public.motoqueiros
language plpgsql
security definer
set search_path = ''
as $$
declare
  resultado public.motoqueiros;
begin
  select * into resultado from public.motoqueiros where id = auth.uid() for update;

  if not found then
    raise exception using errcode = 'P0001', message = 'cadastro_inexistente';
  end if;
  if resultado.estado_verificacao not in ('incompleto', 'rejeitado') then
    raise exception using errcode = 'P0001', message = 'cadastro_ja_submetido';
  end if;
  if resultado.matricula is null or resultado.marca is null or resultado.modelo is null
     or resultado.cor is null or resultado.ano_fabrico is null then
    raise exception using errcode = 'P0001', message = 'dados_veiculo_em_falta';
  end if;
  if (select count(*) from public.documentos d where d.motoqueiro_id = auth.uid())
     < (select count(*) from unnest(enum_range(null::public.tipo_documento))) then
    raise exception using errcode = 'P0001', message = 'documentos_em_falta';
  end if;

  update public.motoqueiros
  set estado_verificacao = 'pendente', motivo_rejeicao = null, submetido_em = now()
  where id = auth.uid()
  returning * into resultado;

  return resultado;
end;
$$;

create function public.atualizar_posicao(
  latitude double precision,
  longitude double precision,
  disponivel boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not privado.motoqueiro_aprovado() then
    raise exception using errcode = 'P0001', message = 'motoqueiro_nao_aprovado';
  end if;

  insert into public.posicoes_motoqueiro (motoqueiro_id, posicao, disponivel, atualizada_em)
  values (auth.uid(), privado.ponto(latitude, longitude), atualizar_posicao.disponivel, now())
  on conflict (motoqueiro_id) do update
  set posicao = excluded.posicao, disponivel = excluded.disponivel, atualizada_em = excluded.atualizada_em;
end;
$$;

create function public.corridas_disponiveis(raio_km double precision default 5)
returns table (
  id uuid,
  tipo_veiculo public.tipo_veiculo,
  origem_latitude double precision,
  origem_longitude double precision,
  origem_nome text,
  destino_latitude double precision,
  destino_longitude double precision,
  destino_nome text,
  distancia_km numeric,
  preco_estimado numeric,
  distancia_ate_origem_km numeric,
  pedida_em timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    c.id,
    c.tipo_veiculo,
    extensions.st_y(c.origem::extensions.geometry),
    extensions.st_x(c.origem::extensions.geometry),
    c.origem_nome,
    extensions.st_y(c.destino::extensions.geometry),
    extensions.st_x(c.destino::extensions.geometry),
    c.destino_nome,
    c.distancia_km,
    c.preco_estimado,
    round((extensions.st_distance(c.origem, p.posicao) / 1000)::numeric, 2),
    c.pedida_em
  from public.posicoes_motoqueiro p
  join public.motoqueiros m on m.id = p.motoqueiro_id
  join public.corridas c
    on c.estado = 'pedida'
   and c.tipo_veiculo = m.tipo_veiculo
   and extensions.st_dwithin(c.origem, p.posicao, least(raio_km, 20) * 1000)
  where p.motoqueiro_id = auth.uid()
    and p.disponivel
    and m.estado_verificacao = 'aprovado'
    and c.passageiro_id <> auth.uid()
  order by extensions.st_distance(c.origem, p.posicao);
$$;

create function public.aceitar_corrida(corrida_id uuid)
returns public.corridas
language plpgsql
security definer
set search_path = ''
as $$
declare
  resultado public.corridas;
begin
  if not privado.motoqueiro_aprovado() then
    raise exception using errcode = 'P0001', message = 'motoqueiro_nao_aprovado';
  end if;
  if exists (
    select 1 from public.corridas c
    where c.motoqueiro_id = auth.uid() and c.estado in ('aceite', 'em_curso')
  ) then
    raise exception using errcode = 'P0001', message = 'corrida_ativa_existente';
  end if;

  update public.corridas c
  set motoqueiro_id = auth.uid(), estado = 'aceite', aceite_em = now()
  where c.id = aceitar_corrida.corrida_id
    and c.estado = 'pedida'
    and c.passageiro_id <> auth.uid()
    and c.tipo_veiculo = (select m.tipo_veiculo from public.motoqueiros m where m.id = auth.uid())
  returning * into resultado;

  if not found then
    raise exception using errcode = 'P0001', message = 'corrida_indisponivel';
  end if;
  return resultado;
end;
$$;

create function public.iniciar_corrida(corrida_id uuid)
returns public.corridas
language plpgsql
security definer
set search_path = ''
as $$
declare
  resultado public.corridas;
begin
  update public.corridas c
  set estado = 'em_curso', iniciada_em = now()
  where c.id = iniciar_corrida.corrida_id
    and c.motoqueiro_id = auth.uid()
    and c.estado = 'aceite'
  returning * into resultado;

  if not found then
    raise exception using errcode = 'P0001', message = 'transicao_invalida';
  end if;
  return resultado;
end;
$$;

create function public.terminar_corrida(corrida_id uuid)
returns public.corridas
language plpgsql
security definer
set search_path = ''
as $$
declare
  resultado public.corridas;
begin
  update public.corridas c
  set estado = 'terminada', terminada_em = now(), preco_final = c.preco_estimado
  where c.id = terminar_corrida.corrida_id
    and c.motoqueiro_id = auth.uid()
    and c.estado = 'em_curso'
  returning * into resultado;

  if not found then
    raise exception using errcode = 'P0001', message = 'transicao_invalida';
  end if;
  return resultado;
end;
$$;

-- ---------------------------------------------------------------------------
-- Ambos
-- ---------------------------------------------------------------------------

create function public.cancelar_corrida(corrida_id uuid, motivo text default null)
returns public.corridas
language plpgsql
security definer
set search_path = ''
as $$
declare
  resultado public.corridas;
begin
  update public.corridas c
  set estado = 'cancelada',
      cancelada_em = now(),
      cancelada_por = auth.uid(),
      motivo_cancelamento = left(cancelar_corrida.motivo, 300)
  where c.id = cancelar_corrida.corrida_id
    and auth.uid() in (c.passageiro_id, c.motoqueiro_id)
    and c.estado in ('pedida', 'aceite')
  returning * into resultado;

  if not found then
    raise exception using errcode = 'P0001', message = 'transicao_invalida';
  end if;
  return resultado;
end;
$$;

create function public.avaliar_corrida(corrida_id uuid, nota smallint, comentario text default null)
returns public.avaliacoes
language plpgsql
security definer
set search_path = ''
as $$
declare
  corrida public.corridas;
  resultado public.avaliacoes;
begin
  select * into corrida from public.corridas c where c.id = avaliar_corrida.corrida_id;

  if not found or corrida.estado <> 'terminada'
     or auth.uid() not in (corrida.passageiro_id, corrida.motoqueiro_id) then
    raise exception using errcode = 'P0001', message = 'corrida_indisponivel';
  end if;

  insert into public.avaliacoes (corrida_id, autor_id, avaliado_id, nota, comentario)
  values (
    corrida.id,
    auth.uid(),
    case when auth.uid() = corrida.passageiro_id then corrida.motoqueiro_id else corrida.passageiro_id end,
    avaliar_corrida.nota,
    avaliar_corrida.comentario
  )
  on conflict on constraint avaliacoes_pkey do nothing
  returning * into resultado;

  if not found then
    raise exception using errcode = 'P0001', message = 'avaliacao_ja_feita';
  end if;
  return resultado;
end;
$$;
