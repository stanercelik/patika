/**
 * RevenueCat v2 sunucu çağrıları. Anahtar yalnız sunucuda
 * (`REVENUECAT_SECRET_API_KEY`, izin: customer information → purchases read).
 */

/**
 * RevenueCat iç ürün kimliği → App Store ürün kimliği. v2 satın alma kaydı ürünü
 * iç kimlikle verir ve genişletme desteklemez. Ürünler yeniden oluşturulursa bu
 * tablo güncellenir; tabloda olmayan kimlik ürün API'sinden sorulur.
 */
const STORE_PRODUCT_BY_RC_ID: Record<string, string> = {
  prod7da9830769: "path.unlock.7d",
  prod26e26ba104: "path.unlock.14d",
  prod75a52cf897: "path.unlock.21d",
  proda8a391f7d4: "path.unlock.28d",
};

export type OwnedPurchase = {
  transactionId: string;
  storeProductId: string;
  purchasedAt: string;
};

type PurchaseItem = {
  customer_id?: string;
  product_id?: string;
  status?: string;
  store?: string;
  store_purchase_identifier?: string | number;
  purchased_at?: number;
};

function credentials(): { project: string; key: string } | null {
  const project = Deno.env.get("REVENUECAT_PROJECT_ID");
  const key = Deno.env.get("REVENUECAT_SECRET_API_KEY");
  return project && key ? { project, key } : null;
}

async function storeProductId(rcProductId: string, project: string, key: string): Promise<string | null> {
  const known = STORE_PRODUCT_BY_RC_ID[rcProductId];
  if (known) return known;
  const response = await fetch(
    `https://api.revenuecat.com/v2/projects/${encodeURIComponent(project)}/products/${encodeURIComponent(rcProductId)}`,
    { headers: { Authorization: `Bearer ${key}` } },
  );
  if (!response.ok) return null;
  const body = await response.json() as { store_identifier?: string };
  return body.store_identifier ?? null;
}

/**
 * Kullanıcının bu ürün için sahip olduğu (`owned`) App Store satın almaları,
 * en yenisi önce. Webhook gelmeden hakkı yazabilmek için kullanılır.
 */
export async function ownedPurchases(userId: string, storeProduct: string): Promise<OwnedPurchase[]> {
  const creds = credentials();
  if (!creds) return [];
  const response = await fetch(
    `https://api.revenuecat.com/v2/projects/${encodeURIComponent(creds.project)}/customers/${encodeURIComponent(userId)}/purchases?limit=50`,
    { headers: { Authorization: `Bearer ${creds.key}` } },
  );
  if (!response.ok) {
    console.error("revenuecat_purchases_failed", response.status);
    return [];
  }
  const body = await response.json() as { items?: PurchaseItem[] };
  const result: OwnedPurchase[] = [];
  for (const item of body.items ?? []) {
    if (item.status !== "owned" || item.customer_id !== userId) continue;
    if (!["app_store", "test_store"].includes(item.store ?? "")) continue;
    if (!item.product_id || item.store_purchase_identifier == null || !item.purchased_at) continue;
    const store = await storeProductId(item.product_id, creds.project, creds.key);
    if (store !== storeProduct) continue;
    result.push({
      transactionId: String(item.store_purchase_identifier),
      storeProductId: store,
      purchasedAt: new Date(item.purchased_at).toISOString(),
    });
  }
  return result.sort((a, b) => b.purchasedAt.localeCompare(a.purchasedAt));
}
