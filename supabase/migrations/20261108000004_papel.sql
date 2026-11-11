-- Uma só app: a pessoa escolhe, depois do código, se usa a ROTA como
-- passageiro ou como motorista, e pode trocar mais tarde pelo menu.
-- `null` = ainda não escolheu. Ser motorista aprovado continua a depender da
-- linha em `motoqueiros` e do seu estado de verificação.

alter table public.perfis
  add column papel text check (papel is null or papel in ('passageiro', 'motorista'));

grant update (papel) on public.perfis to authenticated;
