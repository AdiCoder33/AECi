-- Allow editing submitted clinical cases until assessment is completed

drop policy if exists "clinical update" on public.clinical_cases;
create policy "clinical update" on public.clinical_cases
for update
using (created_by = auth.uid())
with check (created_by = auth.uid());
