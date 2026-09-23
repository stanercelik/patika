import type { SupabaseClient } from "npm:@supabase/supabase-js@2.116.0";

export const productForLength = (days: number): string | null =>
  [7, 14, 21, 28].includes(days) ? `path.unlock.${days}d` : null;

/** The same rule protects audio generation, playback, and completion. */
export async function canAccessStep(
  adminClient: SupabaseClient,
  userId: string,
  step: { path_id: string; day: number },
): Promise<boolean> {
  if (step.day === 1) return true;
  const { data: path, error: pathError } = await adminClient.from("program_paths")
    .select("kind").eq("id", step.path_id).eq("user_id", userId).single();
  if (pathError || !path) throw new Error("path_not_found");
  if (path.kind === "prepared") return true;
  const { data: grant, error } = await adminClient.from("path_purchase_grants")
    .select("path_id").eq("path_id", step.path_id).eq("user_id", userId)
    .is("revoked_at", null).maybeSingle();
  if (error) throw new Error("access_check_failed");
  return !!grant;
}
