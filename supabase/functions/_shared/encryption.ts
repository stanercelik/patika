import { requireEnv } from "./auth.ts";

const encoder = new TextEncoder();

export async function encryptSensitiveText(value: string): Promise<string> {
  const keyBytes = decodeKey(requireEnv("PATIKA_DATA_ENCRYPTION_KEY"));
  const key = await crypto.subtle.importKey("raw", keyBytes.buffer as ArrayBuffer, "AES-GCM", false, ["encrypt"]);
  const nonce = crypto.getRandomValues(new Uint8Array(12));
  const encrypted = await crypto.subtle.encrypt({ name: "AES-GCM", iv: nonce }, key, encoder.encode(value));
  return `v1.${encodeBase64(nonce)}.${encodeBase64(new Uint8Array(encrypted))}`;
}

function decodeKey(value: string): Uint8Array<ArrayBuffer> {
  const decoded = new Uint8Array(Array.from(atob(value), (character) => character.charCodeAt(0)));
  if (decoded.byteLength !== 32) throw new Error("server_configuration_missing");
  return decoded;
}

function encodeBase64(value: Uint8Array): string {
  let binary = "";
  for (const byte of value) binary += String.fromCharCode(byte);
  return btoa(binary);
}
