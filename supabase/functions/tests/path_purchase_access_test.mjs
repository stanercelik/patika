import assert from "node:assert/strict";
import { test } from "node:test";
import { canAccessStep, productForLength } from "../_shared/path-access.ts";

function database(kind, granted, expiresAt = null) {
  return {
    from(table) {
      const query = {
        select() { return query; },
        eq() { return query; },
        is() { return query; },
        async single() {
          assert.equal(table, "program_paths");
          return { data: { kind }, error: null };
        },
        async maybeSingle() {
          assert.equal(table, "path_purchase_grants");
          return { data: granted ? { path_id: "path", expires_at: expiresAt } : null, error: null };
        },
      };
      return query;
    },
  };
}

test("only supported path lengths map to purchasable products", () => {
  assert.equal(productForLength(7), "path.unlock.7d");
  assert.equal(productForLength(14), "path.unlock.14d");
  assert.equal(productForLength(21), "path.unlock.21d");
  assert.equal(productForLength(28), "path.unlock.28d");
  assert.equal(productForLength(8), null);
});

test("the first personal step remains free", async () => {
  assert.equal(await canAccessStep(database("personalized", false), "user", { path_id: "path", day: 1 }), true);
});

test("prepared steps remain free", async () => {
  assert.equal(await canAccessStep(database("prepared", false), "user", { path_id: "path", day: 2 }), true);
});

test("the second personal step requires a server grant for that path", async () => {
  const step = { path_id: "path", day: 2 };
  assert.equal(await canAccessStep(database("personalized", false), "user", step), false);
  assert.equal(await canAccessStep(database("personalized", true), "user", step), true);
  assert.equal(await canAccessStep(database("personalized", true, "2020-01-01T00:00:00Z"), "user", step), false);
});
