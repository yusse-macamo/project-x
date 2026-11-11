-- Preço mínimo por tipo de veículo: nenhuma viagem fica abaixo dele. A mota
-- custa pelo menos 50 MT (com base 30 + 15/km, as viagens até ~1,3 km
-- ficavam abaixo disso). Os outros veículos não têm mínimo além da tarifa.

alter table public.tarifas
  add column if not exists preco_minimo numeric(10, 2) not null default 0
    check (preco_minimo >= 0);

update public.tarifas set preco_minimo = 50 where tipo_veiculo = 'mota';

create or replace function privado.calcular_preco(tipo public.tipo_veiculo, distancia_km numeric)
returns numeric
language sql
stable
set search_path = ''
as $$
  select round(
    greatest(
      t.preco_minimo,
      t.base + t.por_km * greatest(distancia_km, t.distancia_minima_km)
    ),
    2
  )
  from public.tarifas t
  where t.tipo_veiculo = tipo;
$$;
