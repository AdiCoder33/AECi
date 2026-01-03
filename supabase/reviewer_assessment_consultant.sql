-- Allow consultants to submit reviewer assessments

drop policy if exists "reviewer assessments insert" on public.reviewer_assessments;
create policy "reviewer assessments insert"
on public.reviewer_assessments
for insert
to authenticated
with check (
  reviewer_id = auth.uid()
  and exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.designation in ('Reviewer', 'Consultant')
  )
);
