import type { PathKind } from "./schema.ts";

export type VoicePreference = "feminine" | "masculine";

export type SessionSpeechEventDTO = {
  type: "speech";
  source: "personal" | "block";
  assetId: string;
  storagePath: string;
  text: string;
  durationMs: number;
};

export type SessionGapEventDTO = {
  type: "gap";
  milliseconds: number;
};

export type SessionSilenceEventDTO = {
  type: "silence";
  breaths: number;
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
  events: SessionEventDTO[];
};

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

  for (const event of manifest.events) {
    if (event.type === "speech") {
      if (!uuidPattern.test(event.assetId)) fail();
      if (!event.storagePath || event.storagePath.includes("..")) fail();
      if (!event.text.trim() || event.text.length > 1_000) fail();
      if (!Number.isInteger(event.durationMs) || event.durationMs < 1 || event.durationMs > 120_000) fail();
      if (event.source !== "personal" && event.source !== "block") fail();
      if (manifest.pathKind === "prepared" && event.source === "personal") fail();
    } else if (event.type === "gap") {
      if (!Number.isInteger(event.milliseconds) || event.milliseconds < 0 || event.milliseconds > 1_000) fail();
    } else if (event.type === "silence") {
      if (!Number.isInteger(event.breaths) || event.breaths < 1 || event.breaths > 60) fail();
      if (event.landOn !== undefined && event.landOn !== null && event.landOn !== "inhale" && event.landOn !== "exhale") fail();
      if (event.displayText !== undefined && event.displayText !== null && event.displayText.length > 520) fail();
    } else {
      fail();
    }
  }
  return manifest;
}

function fail(): never {
  throw new Error("invalid_session_manifest");
}
