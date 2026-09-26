/**
 * RevenueCat iki yolla kimlik kanıtlar. HMAC imzası (`REVENUECAT_WEBHOOK_SIGNING_SECRET`)
 * tanımlıysa zorunludur: gövdenin bütünlüğünü de korur. Tanımlı değilse webhook'a
 * API ile kurulabilen gizli `Authorization` başlığı (`REVENUECAT_WEBHOOK_AUTH_TOKEN`)
 * aranır. İkisi de yoksa her istek reddedilir. Her iki durumda satın alma ayrıca
 * RevenueCat API'sinden doğrulanır; sahte bir olay tek başına hak açamaz.
 */
export async function requestIsAuthentic(headers: Headers, raw: string): Promise<boolean> {
  if (Deno.env.get("REVENUECAT_WEBHOOK_SIGNING_SECRET")) {
    return await signatureIsValid(headers.get("X-RevenueCat-Webhook-Signature"), raw);
  }
  const token = Deno.env.get("REVENUECAT_WEBHOOK_AUTH_TOKEN");
  if (!token) return false;
  return constantTimeEqual(headers.get("Authorization") ?? "", `Bearer ${token}`);
}

function constantTimeEqual(a: string, b: string): boolean {
  const left = new TextEncoder().encode(a);
  const right = new TextEncoder().encode(b);
  let difference = left.length ^ right.length;
  for (let i = 0; i < Math.max(left.length, right.length); i++) {
    difference |= (left[i] ?? 0) ^ (right[i] ?? 0);
  }
  return difference === 0;
}

async function signatureIsValid(header: string | null, raw: string): Promise<boolean> {
  const secret = Deno.env.get("REVENUECAT_WEBHOOK_SIGNING_SECRET");
  const match = /^t=(\d+),v1=([0-9a-f]{64})$/i.exec(header ?? "");
  if (!secret || !match || Math.abs(Date.now() / 1000 - Number(match[1])) > 300) return false;
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const signature = new Uint8Array(await crypto.subtle.sign("HMAC", key,
    new TextEncoder().encode(`${match[1]}.${raw}`)));
  const supplied = Uint8Array.from(match[2].match(/.{2}/g) ?? [], (pair) => parseInt(pair, 16));
  let difference = 0;
  for (let i = 0; i < signature.length; i++) difference |= signature[i] ^ supplied[i];
  return difference === 0;
}

async function verifiedPurchase(transactionId: string): Promise<{ status: string } | null> {
  const project = required("REVENUECAT_PROJECT_ID");
  const key = required("REVENUECAT_SECRET_API_KEY");
  const url = new URL(`https://api.revenuecat.com/v2/projects/${encodeURIComponent(project)}/purchases`);
  url.searchParams.set("store_purchase_identifier", transactionId);
  const response = await fetch(url, { headers: { Authorization: `Bearer ${key}` } });
  if (!response.ok) return null;
  const body = await response.json() as { items?: Array<{
    store_purchase_identifier?: string | number; status?: string;
  }> };
  const item = body.items?.find((purchase) =>
    String(purchase.store_purchase_identifier) === transactionId);
  return item ? { status: item.status ?? "unknown" } : null;
}
