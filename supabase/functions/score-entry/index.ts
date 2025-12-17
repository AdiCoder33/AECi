// Edge Function: score-entry
// Input: { entryId }
// Computes quality_score and quality_issues for an entry and updates the row.
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

type Payload = { entryId: string };

serve(async (req) => {
  try {
    const payload = (await req.json()) as Payload;
    const url = Deno.env.get("SUPABASE_URL")!;
    const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(url, key);

    const { data: entry, error } = await supabase
      .from("elog_entries")
      .select("id, module_type, keywords, payload")
      .eq("id", payload.entryId)
      .single();
    if (error || !entry) throw error ?? new Error("Entry not found");

    const keywords: string[] = entry.keywords ?? [];
    const payloadFields = entry.payload ?? {};

    let score = 100;
    const issues: string[] = [];

    if (keywords.length === 0) {
      score -= 20;
      issues.push("Add at least one keyword");
    }

    const module = entry.module_type;
    const required: string[] = [];
    if (module === "cases") {
      required.push("briefDescription");
      if (!payloadFields["briefDescription"]) {
        score -= 20;
        issues.push("Brief description is required");
      }
      const followDesc = payloadFields["followUpVisitDescription"];
      const followImgs = payloadFields["followUpVisitImagingPaths"] ?? [];
      if ((followDesc && (!followImgs || followImgs.length === 0)) ||
        (!followDesc && followImgs && followImgs.length > 0)) {
        score -= 5;
        issues.push("Follow-up description/imaging mismatch");
      }
    } else if (module === "images") {
      if (!payloadFields["keyDescriptionOrPathology"]) {
        score -= 20;
        issues.push("Key description is required");
      }
      const uploads = payloadFields["uploadImagePaths"] ?? [];
      if (!uploads || uploads.length === 0) {
        score -= 25;
        issues.push("At least one image upload is required");
      }
    } else if (module === "learning") {
      if (!payloadFields["preOpDiagnosisOrPathology"]) {
        score -= 15;
        issues.push("Pre-op diagnosis required");
      }
      const link = payloadFields["surgicalVideoLink"] as string | undefined;
      if (!link || !link.startsWith("http")) {
        score -= 15;
        issues.push("Valid surgical video link required");
      }
      if (!payloadFields["teachingPoint"]) {
        score -= 15;
        issues.push("Teaching point required");
      }
    } else if (module === "records") {
      if (!payloadFields["preOpDiagnosisOrPathology"]) {
        score -= 15;
        issues.push("Pre-op diagnosis required");
      }
      const link = payloadFields["surgicalVideoLink"] as string | undefined;
      if (!link || !link.startsWith("http")) {
        score -= 15;
        issues.push("Valid surgical video link required");
      }
      if (!payloadFields["learningPointOrComplication"]) {
        score -= 15;
        issues.push("Learning point or complication required");
      }
    }

    if (score < 0) score = 0;

    await supabase
      .from("elog_entries")
      .update({ quality_score: score, quality_issues: issues })
      .eq("id", entry.id);

    await supabase.from("audit_events").insert({
      actor_id: null,
      action: "score_entry",
      target_type: "elog_entry",
      target_id: entry.id,
      metadata: { score, issues },
    });

    return new Response(JSON.stringify({ score, issues }), {
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
