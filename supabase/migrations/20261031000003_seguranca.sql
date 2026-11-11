-- Regra geral: a app (role authenticated) só lê o que é seu e só escreve
-- diretamente em perfis, motoqueiros e documentos — e mesmo aí só nas colunas
-- listadas abaixo. Tudo o que envolve corridas, preço ou posição passa pelas
-- funções em 20261031000002_funcoes.sql.

revoke all on all tables in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;
revoke all on all functions in schema public from public, anon;
revoke all on all functions in schema privado from public, anon, authenticated;
revoke all on schema privado from public, anon;
grant usage on schema privado to authenticated;
grant execute on function privado.motoqueiro_aprovado() to authenticated;

alter default privileges in schema public revoke all on tables from anon, authenticated;
alter default privileges in schema public revoke execute on functions from public, anon;

alter table public.perfis enable row level security;
alter table public.motoqueiros enable row level security;
alter table public.documentos enable row level security;
alter table public.tarifas enable row level security;
alter table public.corridas enable row level security;
alter table public.eventos_corrida enable row level security;
alter table public.avaliacoes enable row level security;
alter table public.posicoes_motoqueiro enable row level security;

-- perfis --------------------------------------------------------------------

grant select on public.perfis to authenticated;
grant update (nome, url_foto) on public.perfis to authenticated;

create policy "ver o próprio perfil" on public.perfis
  for select to authenticated
  using (id = auth.uid());

create policy "passageiro e motoqueiro veem-se numa corrida partilhada" on public.perfis
  for select to authenticated
  using (exists (
    select 1 from public.corridas c
    where (c.passageiro_id = auth.uid() and c.motoqueiro_id = perfis.id)
       or (c.motoqueiro_id = auth.uid() and c.passageiro_id = perfis.id)
  ));

create policy "alterar o próprio perfil" on public.perfis
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- motoqueiros ---------------------------------------------------------------

grant select on public.motoqueiros to authenticated;
grant insert (
  id, nome_completo, numero_bi, bairro, distrito, contacto_emergencia,
  tipo_veiculo, matricula, marca, modelo, cor, ano_fabrico
) on public.motoqueiros to authenticated;
grant update (
  nome_completo, numero_bi, bairro, distrito, contacto_emergencia,
  tipo_veiculo, matricula, marca, modelo, cor, ano_fabrico
) on public.motoqueiros to authenticated;

create policy "ver o próprio cadastro" on public.motoqueiros
  for select to authenticated
  using (id = auth.uid());

create policy "criar o próprio cadastro" on public.motoqueiros
  for insert to authenticated
  with check (id = auth.uid());

create policy "alterar o cadastro enquanto não está submetido" on public.motoqueiros
  for update to authenticated
  using (id = auth.uid() and estado_verificacao in ('incompleto', 'rejeitado'))
  with check (id = auth.uid());

-- documentos ----------------------------------------------------------------

grant select, insert, update, delete on public.documentos to authenticated;

create policy "ver os próprios documentos" on public.documentos
  for select to authenticated
  using (motoqueiro_id = auth.uid());

create policy "gerir documentos enquanto o cadastro não está submetido" on public.documentos
  for all to authenticated
  using (
    motoqueiro_id = auth.uid()
    and exists (
      select 1 from public.motoqueiros m
      where m.id = auth.uid() and m.estado_verificacao in ('incompleto', 'rejeitado')
    )
  )
  with check (
    motoqueiro_id = auth.uid()
    and caminho_storage like auth.uid()::text || '/%'
    and exists (
      select 1 from public.motoqueiros m
      where m.id = auth.uid() and m.estado_verificacao in ('incompleto', 'rejeitado')
    )
  );

-- tarifas -------------------------------------------------------------------

grant select on public.tarifas to authenticated;

create policy "tarifas são públicas para quem tem sessão" on public.tarifas
  for select to authenticated
  using (true);

-- corridas e histórico ------------------------------------------------------

grant select on public.corridas to authenticated;
grant select on public.eventos_corrida to authenticated;
grant select on public.avaliacoes to authenticated;

create policy "ver as próprias corridas" on public.corridas
  for select to authenticated
  using (auth.uid() in (passageiro_id, motoqueiro_id));

create policy "ver eventos das próprias corridas" on public.eventos_corrida
  for select to authenticated
  using (exists (
    select 1 from public.corridas c
    where c.id = eventos_corrida.corrida_id
      and auth.uid() in (c.passageiro_id, c.motoqueiro_id)
  ));

create policy "ver avaliações feitas ou recebidas" on public.avaliacoes
  for select to authenticated
  using (auth.uid() in (autor_id, avaliado_id));

-- posições ------------------------------------------------------------------

grant select on public.posicoes_motoqueiro to authenticated;

create policy "motoqueiro vê a própria posição" on public.posicoes_motoqueiro
  for select to authenticated
  using (motoqueiro_id = auth.uid());

create policy "passageiro vê o motoqueiro da corrida em curso" on public.posicoes_motoqueiro
  for select to authenticated
  using (exists (
    select 1 from public.corridas c
    where c.motoqueiro_id = posicoes_motoqueiro.motoqueiro_id
      and c.passageiro_id = auth.uid()
      and c.estado in ('aceite', 'em_curso')
  ));

-- funções expostas à app ----------------------------------------------------

grant execute on function public.estimar_precos(double precision, double precision, double precision, double precision) to authenticated;
grant execute on function public.pedir_corrida(double precision, double precision, text, double precision, double precision, text, public.tipo_veiculo) to authenticated;
grant execute on function public.motoqueiro_da_corrida(uuid) to authenticated;
grant execute on function public.submeter_cadastro() to authenticated;
grant execute on function public.atualizar_posicao(double precision, double precision, boolean) to authenticated;
grant execute on function public.corridas_disponiveis(double precision) to authenticated;
grant execute on function public.aceitar_corrida(uuid) to authenticated;
grant execute on function public.iniciar_corrida(uuid) to authenticated;
grant execute on function public.terminar_corrida(uuid) to authenticated;
grant execute on function public.cancelar_corrida(uuid, text) to authenticated;
grant execute on function public.avaliar_corrida(uuid, smallint, text) to authenticated;

-- storage: documentos do cadastro, privados, em <id do motoqueiro>/<ficheiro>

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('documentos', 'documentos', false, 5242880, array['image/jpeg', 'image/png'])
on conflict (id) do nothing;

create policy "motoqueiro lê os próprios documentos" on storage.objects
  for select to authenticated
  using (bucket_id = 'documentos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "motoqueiro envia os próprios documentos" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'documentos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "motoqueiro substitui os próprios documentos" on storage.objects
  for update to authenticated
  using (bucket_id = 'documentos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "motoqueiro apaga os próprios documentos" on storage.objects
  for delete to authenticated
  using (bucket_id = 'documentos' and (storage.foldername(name))[1] = auth.uid()::text);

-- realtime: acompanhar o estado da corrida e a posição do motoqueiro

alter publication supabase_realtime add table public.corridas, public.posicoes_motoqueiro;
