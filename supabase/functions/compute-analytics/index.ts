// Edge Function: compute-analytics
// Input: { scope, scopeId, periodDays }
// Computes simple metrics and stores snapshot.
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

type Payload = { scope: "user" | "consultant" | "centre" | "institution"; scopeId: string; periodDays: number };

serve(async (req) => {
  try {
    const payload = (await req.json()) as Payload;
    const url = Deno.env.get("SUPABASE_URL")!;
    const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(url, key);

    const periodEnd = new Date();
    const periodStart = new Date();
    periodStart.setDate(periodEnd.getDate() - (payload.periodDays ?? 30));

    const { data: entries, error } = await supabase
      .from("elog_entries")
      .select("id, module_type, status, created_by, updated_at, quality_score, keywords")
      .gte("created_at", periodStart.toISOString())
      .lte("created_at", periodEnd.toISOString());
    if (error) throw error;

    let filtered = entries ?? [];
    if (payload.scope === "user") {
      filtered = filtered.filter((e) => e.created_by === payload.scopeId);
    } else if (payload.scope === "consultant") {
      const { data: trainees } = await supabase
        .from("supervisor_assignments")
        .select("trainee_id")
        .eq("consultant_id", payload.scopeId);
      const traineeIds = new Set((trainees ?? []).map((t) => t.trainee_id));
      filtered = filtered.filter((e) => traineeIds.has(e.created_by));
    } else if (payload.scope === "centre") {
      const { data: profiles } = await supabase
        .from("profiles")
        .select("id")
        .eq("centre", payload.scopeId);
      const ids = new Set((profiles ?? []).map((p) => p.id));
      filtered = filtered.filter((e) => ids.has(e.created_by));
    }

    const metrics: Record<string, unknown> = {};
    metrics["count"] = filtered.length;
    const byStatus: Record<string, number> = {};
    const byModule: Record<string, number> = {};
    let qualitySum = 0;
    for (const e of filtered) {
      byStatus[e.status] = (byStatus[e.status] ?? 0) + 1;
      byModule[e.module_type] = (byModule[e.module_type] ?? 0) + 1;
      qualitySum += e.quality_score ?? 0;
    }
    metrics["byStatus"] = byStatus;
    metrics["byModule"] = byModule;
    metrics["avgQuality"] = filtered.length ? qualitySum / filtered.length : 0;
    const keywordCounts: Record<string, number> = {};
    for (const e of filtered) {
      (e.keywords ?? []).forEach((k: string) => {
        keywordCounts[k] = (keywordCounts[k] ?? 0) + 1;
      });
    }
    metrics["topKeywords"] = Object.entries(keywordCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10);

    await supabase.from("analytics_snapshots").upsert({
      scope: payload.scope,
      scope_id: payload.scopeId,
      period_start: periodStart.toISOString().slice(0, 10),
      period_end: periodEnd.toISOString().slice(0, 10),
      metrics,
    });

    await supabase.from("audit_events").insert({
      actor_id: null,
      action: "compute_analytics",
      target_type: payload.scope,
      target_id: payload.scopeId,
      metadata: { periodDays: payload.periodDays },
    });

    return new Response(JSON.stringify({ metrics }), {
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
