import { assertEquals } from "jsr:@std/assert@1.0.14";
import { requestIsAuthentic } from "../_shared/webhook-auth.ts";

const body = '{"event":{"id":"e1"}}';

function withEnv(values: Record<string, string | undefined>, run: () => Promise<void>) {
  return async () => {
    const previous: Record<string, string | undefined> = {};
    for (const [key, value] of Object.entries(values)) {
      previous[key] = Deno.env.get(key);
      if (value === undefined) Deno.env.delete(key);
      else Deno.env.set(key, value);
    }
    try {
      await run();
    } finally {
      for (const [key, value] of Object.entries(previous)) {
        if (value === undefined) Deno.env.delete(key);
        else Deno.env.set(key, value);
      }
    }
  };
}

async function hmac(secret: string, message: string): Promise<string> {
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const signature = new Uint8Array(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(message)));
  return Array.from(signature, (byte) => byte.toString(16).padStart(2, "0")).join("");
}

Deno.test("no secret configured rejects every request", withEnv(
  { REVENUECAT_WEBHOOK_SIGNING_SECRET: undefined, REVENUECAT_WEBHOOK_AUTH_TOKEN: undefined },
  async () => {
    const headers = new Headers({ Authorization: "Bearer anything" });
    assertEquals(await requestIsAuthentic(headers, body), false);
  },
));

Deno.test("authorization token must match exactly", withEnv(
  { REVENUECAT_WEBHOOK_SIGNING_SECRET: undefined, REVENUECAT_WEBHOOK_AUTH_TOKEN: "tok_123" },
  async () => {
    assertEquals(await requestIsAuthentic(new Headers({ Authorization: "Bearer tok_123" }), body), true);
    assertEquals(await requestIsAuthentic(new Headers({ Authorization: "Bearer tok_124" }), body), false);
    assertEquals(await requestIsAuthentic(new Headers({ Authorization: "Bearer tok_12" }), body), false);
    assertEquals(await requestIsAuthentic(new Headers(), body), false);
  },
));

Deno.test("configured HMAC secret takes precedence over the token", withEnv(
  { REVENUECAT_WEBHOOK_SIGNING_SECRET: "whsec", REVENUECAT_WEBHOOK_AUTH_TOKEN: "tok_123" },
  async () => {
    assertEquals(await requestIsAuthentic(new Headers({ Authorization: "Bearer tok_123" }), body), false);
    const t = Math.floor(Date.now() / 1000);
    const signature = await hmac("whsec", `${t}.${body}`);
    const headers = new Headers({ "X-RevenueCat-Webhook-Signature": `t=${t},v1=${signature}` });
    assertEquals(await requestIsAuthentic(headers, body), true);
    assertEquals(await requestIsAuthentic(headers, body + " "), false);
  },
));
