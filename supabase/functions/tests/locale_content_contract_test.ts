import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { approvedEnglishBlockIds } from "../_shared/schema.ts";

const migration = await Deno.readTextFile(new URL(
  "../../migrations/20260909150100_seed_blocks_en.sql",
  import.meta.url,
));
const previewScript = await Deno.readTextFile(new URL(
  "../../../scripts/render-voice-previews.sh",
  import.meta.url,
));

Deno.test("every approved English block and framing block has a draft seed", () => {
  const required = ["opening.arrival.en.v1", ...approvedEnglishBlockIds, "closing.day.en.v1"];
  assertEquals(required.every((id) => migration.includes(`('${id}'`)), true);
  assertEquals(migration.includes("reviewed_at"), true);
  assertEquals(migration.includes("NULL"), true);
});

Deno.test("preview renderer has one immutable app asset for each locale and voice", () => {
  for (const locale of ["tr", "en"]) {
    for (const voice of ["feminine", "masculine"]) {
      assertEquals(previewScript.includes(`voice-preview-$pref-$lang.mp3`), true);
      assertEquals(previewScript.includes(`render "$VOICE_${voice.toUpperCase()}" ${voice}`), true);
      assertEquals(previewScript.includes(`${locale} "$TEXT_${locale.toUpperCase()}"`), true);
    }
  }
});

