import type { PathKind } from "./schema.ts";

export type VoicePreference = "feminine" | "masculine";

export type SessionSpeechEventDTO = {
  type: "speech";
  source: "personal" | "block";
  assetId: string;
  storagePath: string;
  text: string;
  /// Dosyanın gerçek çözülmüş uzunluğu. **Planlama** değeri: toplam süre, ses
  /// gelmeden çizilen iz. Oynatıcı ona göre zamanlamaz, yüklediği dosyayı ölçer.
  durationMs: number;
  /// Bu konuşmadan **önce** bırakılacak bağlantı boşluğu (0..2000). Bir olay
  /// değil, sonraki konuşmanın özelliği: ekranda ayrı bir sahne üretmez.
  /// Komşu dolgular düşülmüş değerdir (`joinLeadInMs`).
  leadInMs?: number;
};

/// Yeni manifestlerde üretilmez; eski manifestler için doğrulanır ve çalınır.
export type SessionGapEventDTO = {
  type: "gap";
  milliseconds: number;
};

export type SessionSilenceEventDTO = {
  type: "silence";
  /// Yetkili süre (250..300000). v2 manifestlerde her zaman yazılır.
  ms?: number;
  /// Eski istemciler için ayna; `ms` ile tutarlı olmak zorunda. Yalnızca `breaths`
  /// taşıyan eski manifestler de geçerli.
  breaths?: number;
  /// Sessizliğin hizalandığı nefes periyodu (4000..30000). Yoksa manifestinki.
  breathMs?: number;
  landOn?: "inhale" | "exhale" | null;
  displayText?: string | null;
};

export type SessionEventDTO =
  | SessionSpeechEventDTO
  | SessionGapEventDTO
  | SessionSilenceEventDTO;

export type SessionManifestDTO = {
  version: 1;
  stepId: string;
  pathKind: PathKind;
  locale: string;
  voice: VoicePreference;
  question: string | null;
  /// Varsayılan nefes periyodu, milisaniye (varsayılan 10000).
  breathMs?: number;
  events: SessionEventDTO[];
};

export const DEFAULT_BREATH_MS = 10_000;
export const MAX_LEAD_IN_MS = 2_000;
export const MIN_SILENCE_MS = 250;
export const MAX_SILENCE_MS = 300_000;

/// `ms` sessizliğinin eski istemcilere bırakılan nefes sayısı yansıması.
export function mirrorBreaths(ms: number, breathMs: number): number {
  return Math.min(60, Math.max(1, Math.round(ms / breathMs)));
}

const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export function shouldAskAdaptiveQuestion(pathKind: PathKind, question: string | null): boolean {
  return pathKind === "personalized" && typeof question === "string" && question.trim().length > 0;
}

export function validateSessionManifest(manifest: SessionManifestDTO): SessionManifestDTO {
  if (manifest.version !== 1 || !uuidPattern.test(manifest.stepId)) fail();
  if (manifest.pathKind !== "personalized" && manifest.pathKind !== "prepared") fail();
  if (!/^tr(?:-|$)|^en(?:-|$)/i.test(manifest.locale)) fail();
  if (manifest.voice !== "feminine" && manifest.voice !== "masculine") fail();
  if (manifest.question !== null && (manifest.question.trim().length < 1 || manifest.question.length > 120)) fail();
  if (manifest.pathKind === "prepared" && manifest.question !== null) fail();
  if (!Array.isArray(manifest.events) || manifest.events.length < 1 || manifest.events.length > 100) fail();
  if (manifest.breathMs !== undefined && !isBreathMs(manifest.breathMs)) fail();

  for (const event of manifest.events) {
    if (event.type === "speech") {
      if (!uuidPattern.test(event.assetId)) fail();
      if (!event.storagePath || event.storagePath.includes("..")) fail();
      if (!event.text.trim() || event.text.length > 1_000) fail();
      if (!Number.isInteger(event.durationMs) || event.durationMs < 1 || event.durationMs > 120_000) fail();
      if (event.source !== "personal" && event.source !== "block") fail();
      if (manifest.pathKind === "prepared" && event.source === "personal") fail();
      if (event.leadInMs !== undefined && (!Number.isInteger(event.leadInMs) || event.leadInMs < 0 || event.leadInMs > MAX_LEAD_IN_MS)) fail();
    } else if (event.type === "gap") {
      if (!Number.isInteger(event.milliseconds) || event.milliseconds < 0 || event.milliseconds > 1_000) fail();
    } else if (event.type === "silence") {
      if (event.ms === undefined && event.breaths === undefined) fail();
      if (event.ms !== undefined && (!Number.isInteger(event.ms) || event.ms < MIN_SILENCE_MS || event.ms > MAX_SILENCE_MS)) fail();
      if (event.breaths !== undefined && (!Number.isInteger(event.breaths) || event.breaths < 1 || event.breaths > 60)) fail();
      if (event.breathMs !== undefined && !isBreathMs(event.breathMs)) fail();
      if (event.ms !== undefined && event.breaths !== undefined) {
        // Ayna yalan söyleyemez: eski istemci `breaths`i okuyup çalıyor.
        const period = event.breathMs ?? manifest.breathMs ?? DEFAULT_BREATH_MS;
        if (event.breaths !== mirrorBreaths(event.ms, period)) fail();
      }
      if (event.landOn !== undefined && event.landOn !== null && event.landOn !== "inhale" && event.landOn !== "exhale") fail();
      if (event.displayText !== undefined && event.displayText !== null && event.displayText.length > 520) fail();
    } else {
      fail();
    }
  }
  return manifest;
}

function isBreathMs(value: unknown): boolean {
  return typeof value === "number" && Number.isInteger(value) && value >= 4_000 && value <= 30_000;
}

function fail(): never {
  throw new Error("invalid_session_manifest");
}
