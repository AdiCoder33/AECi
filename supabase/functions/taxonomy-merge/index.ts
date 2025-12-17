// Deno Deploy Edge Function: taxonomy-merge
// Input: { fromTermId, toTermId }
// Replaces occurrences of fromTerm.term in elog_entries.keywords with toTerm.term
// and marks fromTerm as deprecated with replacement.
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

type Payload = { fromTermId: string; toTermId: string };

serve(async (req) => {
  try {
    const payload = (await req.json()) as Payload;
    const url = Deno.env.get("SUPABASE_URL")!;
    const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(url, key);

    const { data: fromTerm, error: fromErr } = await supabase
      .from("keyword_terms")
      .select("id, term, normalized")
      .eq("id", payload.fromTermId)
      .single();
    if (fromErr || !fromTerm) throw fromErr ?? new Error("fromTerm not found");

    const { data: toTerm, error: toErr } = await supabase
      .from("keyword_terms")
      .select("id, term, normalized")
      .eq("id", payload.toTermId)
      .single();
    if (toErr || !toTerm) throw toErr ?? new Error("toTerm not found");

    // Update fromTerm -> deprecated
    await supabase
      .from("keyword_terms")
      .update({ status: "deprecated", replacement_term_id: toTerm.id })
      .eq("id", fromTerm.id);

    // Replace keywords in elog_entries
    const { data: entries, error: entriesErr } = await supabase
      .from("elog_entries")
      .select("id, keywords");
    if (entriesErr) throw entriesErr;

    let updatedCount = 0;
    for (const entry of entries ?? []) {
      const kws: string[] = entry.keywords ?? [];
      const replaced = kws.map((k) =>
        k.toLowerCase() === fromTerm.normalized.toLowerCase() ||
        k.toLowerCase() === fromTerm.term.toLowerCase()
          ? toTerm.term
          : k
      );
      const changed = JSON.stringify(kws) !== JSON.stringify(replaced);
      if (changed) {
        await supabase.from("elog_entries").update({ keywords: replaced }).eq("id", entry.id);
        updatedCount++;
      }
    }

    // Log audit
    await supabase.from("audit_events").insert({
      actor_id: null,
      action: "taxonomy_merge",
      target_type: "keyword_term",
      target_id: fromTerm.id,
      metadata: { from: fromTerm.term, to: toTerm.term, updatedCount },
    });

    return new Response(JSON.stringify({ updatedEntriesCount: updatedCount }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      headers: { "Content-Type": "application/json" },
      status: 400,
    });
  }
});
