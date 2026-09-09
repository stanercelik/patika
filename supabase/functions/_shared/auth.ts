import { createClient, type SupabaseClient, type User } from "npm:@supabase/supabase-js@2.116.0";

export type RequestContext = {
  user: User;
  userClient: SupabaseClient;
  adminClient: SupabaseClient;
};

export async function authenticate(req: Request): Promise<RequestContext> {
  const authorization = req.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) throw new Error("unauthorized");

  const url = requireEnv("SUPABASE_URL");
  const publishableKey = Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ??
    Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const secretKey = Deno.env.get("SUPABASE_SECRET_KEY") ??
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!publishableKey || !secretKey) throw new Error("server_configuration_missing");

  const userClient = createClient(url, publishableKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await userClient.auth.getUser();
  if (error || !data.user) throw new Error("unauthorized");

  const adminClient = createClient(url, secretKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  return { user: data.user, userClient, adminClient };
}

export function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error("server_configuration_missing");
  return value;
}
