import type { SupabaseClient } from "npm:@supabase/supabase-js@2.116.0";
import {
  DEFAULT_TTS_MODEL,
  renditionHash,
  synthesize,
  type VoicePreference,
} from "./tts.ts";
import {
  validateSessionManifest,
  type SessionEventDTO,
  type SessionManifestDTO,
  type SessionSpeechEventDTO,
} from "./session.ts";

type ScriptEntry =
  | { type: "fixed"; text: string }
  | { type: "slot"; name: string }
  | { type: "silence"; breaths: number; landOn?: "inhale" | "exhale" | null; displayText?: string | null };

export type BlockRow = {
  id: string;
  version: number;
  locale: string;
  script: ScriptEntry[];
  audio_tag: string | null;
  breath_pattern: { inhale?: number; hold?: number; exhale?: number; rest?: number } | null;
  reviewed_at: string | null;
};

const PERSONAL_SLOT_ORDER = ["step_opening", "technique_bridge", "mid_bridge", "step_closing"];

export async function processAudioJob(adminClient: SupabaseClient, jobId: string) {
  const { data: job } = await adminClient.from("generation_jobs")
    .select("id,user_id,path_id,path_step_id,rendition_hash,status,attempt_count")
    .eq("id", jobId).eq("kind", "audio").maybeSingle();
  if (!job?.path_step_id || !job.path_id || !job.rendition_hash) throw new Error("audio_job_not_found");

  await adminClient.from("generation_jobs").update({
    status: "processing",
    attempt_count: Math.min(10, (job.attempt_count ?? 0) + 1),
    last_error_code: null,
  }).eq("id", job.id);

  try {
    const [{ data: step }, { data: path }, { data: profile }] = await Promise.all([
      adminClient.from("path_steps").select("id,path_id,user_id,block_ids,slot_copy,step_question")
        .eq("id", job.path_step_id).eq("user_id", job.user_id).single(),
      adminClient.from("program_paths").select("id,kind")
        .eq("id", job.path_id).eq("user_id", job.user_id).single(),
      adminClient.from("profiles").select("locale,voice_preference")
        .eq("user_id", job.user_id).maybeSingle(),
    ]);
    if (!step || !path) throw new Error("audio_job_not_found");

    const locale = normalizedLocale(profile?.locale);
    const voice: VoicePreference = profile?.voice_preference === "masculine" ? "masculine" : "feminine";
    const pathKind = path.kind === "prepared" ? "prepared" : "personalized";
    const framing = locale === "en"
      ? ["opening.arrival.en.v1", "closing.day.en.v1"]
      : ["opening.arrival.v1", "closing.day.v1"];
    const requestedBlockIds = [framing[0], ...(step.block_ids ?? []), framing[1]];
    const { data: rows, error: blocksError } = await adminClient.from("blocks")
      .select("id,version,locale,script,audio_tag,breath_pattern,reviewed_at").in("id", requestedBlockIds);
    if (blocksError) throw new Error("database_read_failed");
    const byId = new Map((rows ?? []).map((row) => [row.id, row as BlockRow]));
    const blocks = requestedBlockIds.map((id) => byId.get(id));
    if (blocks.some((block) => !block)) throw new Error("audio_copy_unavailable");
    if (Deno.env.get("PATIKA_ALLOW_UNREVIEWED_AUDIO") !== "true" && blocks.some((block) => !block?.reviewed_at)) {
      throw new Error("unreviewed_content");
    }

    const slotCopy = (step.slot_copy ?? {}) as Record<string, unknown>;
    const personalTexts = PERSONAL_SLOT_ORDER
      .map((name) => ({ name, text: typeof slotCopy[name] === "string" ? String(slotCopy[name]).trim() : "" }))
      .filter(({ text }) => text.length > 0);
    const personalAssets = new Map<string, SessionSpeechEventDTO>();
    if (pathKind === "personalized") {
      for (const [index, slot] of personalTexts.entries()) {
        personalAssets.set(slot.name, await renderPersonalAsset(adminClient, {
          userId: job.user_id,
          stepId: step.id,
          slotName: slot.name,
          text: slot.text,
          locale,
          voice,
          previousText: personalTexts[index - 1]?.text ?? null,
          nextText: personalTexts[index + 1]?.text ?? null,
        }));
      }
    }

    const events: SessionEventDTO[] = [];
    const usedSlots = new Set<string>();
    for (const block of blocks as BlockRow[]) {
      for (const [segmentIndex, entry] of block.script.entries()) {
        if (entry.type === "fixed") {
          appendSpeech(events, await renderSharedBlockAsset(adminClient, block, segmentIndex, entry.text, voice));
        } else if (entry.type === "slot") {
          if (pathKind === "prepared" || usedSlots.has(entry.name)) continue;
          const asset = personalAssets.get(entry.name);
          if (asset) appendSpeech(events, asset);
          usedSlots.add(entry.name);
        } else if (entry.type === "silence") {
          events.push({ type: "silence", breaths: entry.breaths, landOn: entry.landOn ?? null, displayText: entry.displayText ?? null });
        }
      }
    }

    const manifest: SessionManifestDTO = validateSessionManifest({
      version: 1,
      stepId: step.id,
      pathKind,
      locale,
      voice,
      question: pathKind === "personalized" ? step.step_question ?? null : null,
      events,
    });
    const { data: stored, error: manifestError } = await adminClient.from("session_manifests").upsert({
      user_id: job.user_id,
      path_step_id: step.id,
      version: 1,
      path_kind: pathKind,
      locale,
      voice_preference: voice,
      adaptive_question: manifest.question,
      manifest,
      total_duration_ms: durationOf(events, blocks as BlockRow[]),
      rendition_hash: job.rendition_hash,
    }, { onConflict: "path_step_id,version" }).select("id").single();
    if (manifestError || !stored) throw new Error("database_write_failed");

    await Promise.all([
      adminClient.from("path_steps").update({ audio_status: "ready" }).eq("id", step.id),
      adminClient.from("generation_jobs").update({ status: "succeeded", completed_at: new Date().toISOString() }).eq("id", job.id),
    ]);
    return { status: "ready" as const, manifestId: stored.id };
  } catch (error) {
    const code = error instanceof Error ? error.message : "audio_generation_failed";
    await Promise.all([
      adminClient.from("path_steps").update({ audio_status: "failed" }).eq("id", job.path_step_id),
      adminClient.from("generation_jobs").update({
        status: code === "unreviewed_content" ? "blocked" : "failed",
        last_error_code: code.slice(0, 120),
      }).eq("id", job.id),
    ]);
    throw error;
  }
}

export async function renderSharedBlockAsset(
  adminClient: SupabaseClient,
  block: BlockRow,
  segmentIndex: number,
  text: string,
  voice: VoicePreference,
): Promise<SessionSpeechEventDTO> {
  const digest = await renditionHash({ text, locale: block.locale, voice, modelId: DEFAULT_TTS_MODEL, prosody: block.audio_tag });
  const { data: existing } = await adminClient.from("block_audio")
    .select("id,storage_path,duration_ms").eq("rendition_hash", digest).maybeSingle();
  if (existing) return speechEvent("block", existing, text);

  const speech = await synthesize({ text, locale: block.locale, voice, audioTag: block.audio_tag });
  const storagePath = `${block.locale}/${voice}/${digest}.mp3`;
  const { error: uploadError } = await adminClient.storage.from("block_audio")
    .upload(storagePath, speech.bytes, { contentType: speech.contentType, upsert: false });
  if (uploadError && !String(uploadError.message).toLowerCase().includes("already exists")) throw new Error("storage_write_failed");
  const { data: stored, error: storeError } = await adminClient.from("block_audio").upsert({
    block_id: block.id,
    block_version: block.version,
    segment_index: segmentIndex,
    locale: block.locale,
    voice_preference: voice,
    storage_path: storagePath,
    content_type: speech.contentType,
    duration_ms: speech.durationMs,
    model_id: speech.modelId,
    rendition_hash: digest,
  }, { onConflict: "block_id,block_version,segment_index,locale,voice_preference" })
    .select("id,storage_path,duration_ms").single();
  if (storeError || !stored) throw new Error("database_write_failed");
  return speechEvent("block", stored, text);
}

async function renderPersonalAsset(adminClient: SupabaseClient, input: {
  userId: string; stepId: string; slotName: string; text: string; locale: string; voice: VoicePreference;
  previousText: string | null; nextText: string | null;
}): Promise<SessionSpeechEventDTO> {
  const digest = await renditionHash({
    text: input.text, locale: input.locale, voice: input.voice, modelId: DEFAULT_TTS_MODEL,
    prosody: "soft", previousText: input.previousText, nextText: input.nextText,
  });
  const { data: existing } = await adminClient.from("audio_assets")
    .select("id,storage_path,duration_ms").eq("user_id", input.userId).eq("rendition_hash", digest).maybeSingle();
  if (existing) return speechEvent("personal", existing, input.text);

  const speech = await synthesize({
    text: input.text, locale: input.locale, voice: input.voice, prosody: "soft",
    previousText: input.previousText, nextText: input.nextText,
  });
  const storagePath = `${input.userId}/${input.stepId}/${digest}.mp3`;
  const { error: uploadError } = await adminClient.storage.from("private_audio")
    .upload(storagePath, speech.bytes, { contentType: speech.contentType, upsert: false });
  if (uploadError && !String(uploadError.message).toLowerCase().includes("already exists")) throw new Error("storage_write_failed");
  const { data: stored, error: storeError } = await adminClient.from("audio_assets").upsert({
    user_id: input.userId,
    path_step_id: input.stepId,
    slot_name: input.slotName,
    storage_path: storagePath,
    content_type: speech.contentType,
    duration_ms: speech.durationMs,
    model_id: speech.modelId,
    voice_preference: input.voice,
    locale: input.locale,
    rendition_hash: digest,
  }, { onConflict: "path_step_id,slot_name" }).select("id,storage_path,duration_ms").single();
  if (storeError || !stored) throw new Error("database_write_failed");
  return speechEvent("personal", stored, input.text);
}

function speechEvent(source: "personal" | "block", row: { id: string; storage_path: string; duration_ms: number | null }, text: string): SessionSpeechEventDTO {
  return { type: "speech", source, assetId: row.id, storagePath: row.storage_path, text, durationMs: Math.max(1, row.duration_ms ?? 1) };
}

function appendSpeech(events: SessionEventDTO[], event: SessionSpeechEventDTO) {
  if (events.at(-1)?.type === "speech") events.push({ type: "gap", milliseconds: 300 });
  events.push(event);
}

function normalizedLocale(locale: unknown): "tr" | "en" {
  return typeof locale === "string" && locale.toLowerCase().startsWith("tr") ? "tr" : "en";
}

function durationOf(events: SessionEventDTO[], blocks: BlockRow[]): number {
  const pattern = blocks.find((block) => block.breath_pattern)?.breath_pattern;
  const breathMs = pattern
    ? Math.round(((pattern.inhale ?? 4) + (pattern.hold ?? 0.5) + (pattern.exhale ?? 5.5) + (pattern.rest ?? 0)) * 1_000)
    : 10_000;
  return events.reduce((sum, event) => event.type === "speech"
    ? sum + event.durationMs
    : event.type === "gap" ? sum + event.milliseconds : sum + event.breaths * breathMs, 0);
}

