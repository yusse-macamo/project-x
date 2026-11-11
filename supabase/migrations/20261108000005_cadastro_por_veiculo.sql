-- Cadastro do motorista por tipo de veículo (mota, txopela, táxi).
--
-- Todos: nome, email, foto do motorista, foto do veículo de frente e de trás
-- (com a placa), cor e placa. Txopela e táxi: + carta de condução.
-- Táxi: + marca e modelo. Saem do cadastro o BI, bairro, distrito, contacto
-- de emergência, livrete e ano de fabrico — as colunas ficam (nullable) para
-- não perder dados antigos.

alter type public.tipo_documento add value if not exists 'foto_motorista';
alter type public.tipo_documento add value if not exists 'veiculo_frente';
alter type public.tipo_documento add value if not exists 'veiculo_traseira';

alter table public.motoqueiros
  alter column numero_bi drop not null,
  alter column bairro drop not null,
  alter column distrito drop not null,
  alter column contacto_emergencia drop not null,
  add column email text check (
    email is null or email ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]{2,}$'
  );

grant insert (email) on public.motoqueiros to authenticated;
grant update (email) on public.motoqueiros to authenticated;

create or replace function public.submeter_cadastro()
returns public.motoqueiros
language plpgsql
security definer
set search_path = ''
as $$
declare
  resultado public.motoqueiros;
  exigidos text[];
begin
  select * into resultado from public.motoqueiros where id = auth.uid() for update;

  if not found then
    raise exception using errcode = 'P0001', message = 'cadastro_inexistente';
  end if;
  if resultado.estado_verificacao not in ('incompleto', 'rejeitado') then
    raise exception using errcode = 'P0001', message = 'cadastro_ja_submetido';
  end if;
  if resultado.tipo_veiculo not in ('mota', 'txopela', 'carro') then
    raise exception using errcode = 'P0001', message = 'tipo_veiculo_invalido';
  end if;
  if resultado.nome_completo is null or resultado.email is null then
    raise exception using errcode = 'P0001', message = 'dados_pessoais_em_falta';
  end if;
  if resultado.matricula is null or resultado.cor is null
     or (resultado.tipo_veiculo = 'carro'
         and (resultado.marca is null or resultado.modelo is null)) then
    raise exception using errcode = 'P0001', message = 'dados_veiculo_em_falta';
  end if;

  exigidos := array['foto_motorista', 'veiculo_frente', 'veiculo_traseira'];
  if resultado.tipo_veiculo <> 'mota' then
    exigidos := exigidos || 'carta_conducao';
  end if;
  if exists (
    select 1 from unnest(exigidos) as e(tipo)
    where not exists (
      select 1 from public.documentos d
      where d.motoqueiro_id = auth.uid() and d.tipo::text = e.tipo
    )
  ) then
    raise exception using errcode = 'P0001', message = 'documentos_em_falta';
  end if;

  update public.motoqueiros
  set estado_verificacao = 'pendente', motivo_rejeicao = null, submetido_em = now()
  where id = auth.uid()
  returning * into resultado;

  return resultado;
end;
$$;
