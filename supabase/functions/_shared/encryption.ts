import { requireEnv } from "./auth.ts";

const encoder = new TextEncoder();
const decoder = new TextDecoder();

export async function encryptSensitiveText(value: string): Promise<string> {
  const key = await importKey(["encrypt"]);
  const nonce = crypto.getRandomValues(new Uint8Array(12));
  const encrypted = await crypto.subtle.encrypt({ name: "AES-GCM", iv: nonce }, key, encoder.encode(value));
  return `v1.${encodeBase64(nonce)}.${encodeBase64(new Uint8Array(encrypted))}`;
}

/// Yalnızca verinin sahibine geri okumak için ("Ben" sekmesi, `me-profile`).
/// Çözülen metin hiçbir zaman loglanmaz, LLM'e ya da analitiğe gitmez.
export async function decryptSensitiveText(value: string): Promise<string> {
  const [version, nonce, payload] = value.split(".");
  if (version !== "v1" || !nonce || !payload) throw new Error("invalid_ciphertext");
  const key = await importKey(["decrypt"]);
  const decrypted = await crypto.subtle.decrypt(
    { name: "AES-GCM", iv: decodeBase64(nonce) },
    key,
    decodeBase64(payload),
  );
  return decoder.decode(decrypted);
}

function importKey(usages: KeyUsage[]): Promise<CryptoKey> {
  const keyBytes = decodeKey(requireEnv("PATIKA_DATA_ENCRYPTION_KEY"));
  return crypto.subtle.importKey("raw", keyBytes.buffer as ArrayBuffer, "AES-GCM", false, usages);
}

function decodeKey(value: string): Uint8Array<ArrayBuffer> {
  const decoded = decodeBase64(value);
  if (decoded.byteLength !== 32) throw new Error("server_configuration_missing");
  return decoded;
}

function decodeBase64(value: string): Uint8Array<ArrayBuffer> {
  return new Uint8Array(Array.from(atob(value), (character) => character.charCodeAt(0)));
}

function encodeBase64(value: Uint8Array): string {
  let binary = "";
  for (const byte of value) binary += String.fromCharCode(byte);
  return btoa(binary);
}
