// MP3 süresi — çerçeve başlıklarını yürüyerek.
//
// ## Neden hizalamadan değil
//
// TTS sağlayıcısı karakter hizalaması döndürüyor ve eskiden süre son karakterin
// bitiş zamanından türetiliyordu. Bu, dosyanın baş ve son sessizliğini içermiyor:
// dosya beyan edilenden uzun çıkıyor, oynatıcı bir sonraki dosyayı beyan edilen
// süreye göre başlattığında dolgu planlanan boşluğun üstüne biniyordu.
//
// Burada gerçek çerçeveler sayılıyor. Sonuç yine bir **planlama** değeri: istemci
// dosyayı yükleyince kendi ölçtüğüne göre zamanlar (`SessionAudioPlayer`).
//
// ID3v2 etiketi ve Xing/Info/VBRI çerçevesi ses taşımıyor, sayılmıyor.

const BITRATES_KBPS: Readonly<Record<string, readonly number[]>> = {
  // "<MPEG sürümü>-<katman>" -> bit hızı, indeks 1..14
  "1-1": [32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448],
  "1-2": [32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384],
  "1-3": [32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320],
  "2-1": [32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256],
  "2-2": [8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160],
  "2-3": [8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160],
};

const SAMPLE_RATES: Readonly<Record<string, readonly number[]>> = {
  "1": [44_100, 48_000, 32_000],
  "2": [22_050, 24_000, 16_000],
  "2.5": [11_025, 12_000, 8_000],
};

type FrameHeader = {
  frameBytes: number;
  samples: number;
  sampleRate: number;
  xingOffset: number;
};

function parseHeader(bytes: Uint8Array, at: number): FrameHeader | null {
  if (at + 4 > bytes.length) return null;
  if (bytes[at] !== 0xff || (bytes[at + 1] & 0xe0) !== 0xe0) return null;

  const versionBits = (bytes[at + 1] >> 3) & 0x03;
  const layerBits = (bytes[at + 1] >> 1) & 0x03;
  if (versionBits === 1 || layerBits === 0) return null;
  const version = versionBits === 3 ? "1" : versionBits === 2 ? "2" : "2.5";
  const layer = 4 - layerBits; // bitler: 01 = Katman III, 10 = II, 11 = I
  const protectedByCrc = (bytes[at + 1] & 0x01) === 0;

  const bitrateIndex = (bytes[at + 2] >> 4) & 0x0f;
  const sampleRateIndex = (bytes[at + 2] >> 2) & 0x03;
  const padding = (bytes[at + 2] >> 1) & 0x01;
  if (bitrateIndex === 0 || bitrateIndex === 15 || sampleRateIndex === 3) return null;

  const table = BITRATES_KBPS[`${version === "1" ? "1" : "2"}-${layer}`];
  const bitrate = table?.[bitrateIndex - 1];
  const sampleRate = SAMPLE_RATES[version]?.[sampleRateIndex];
  if (!bitrate || !sampleRate) return null;

  const mono = ((bytes[at + 3] >> 6) & 0x03) === 3;
  let samples: number;
  let frameBytes: number;
  if (layer === 1) {
    samples = 384;
    frameBytes = (Math.floor((12 * bitrate * 1_000) / sampleRate) + padding) * 4;
  } else {
    samples = layer === 3 && version !== "1" ? 576 : 1_152;
    const coefficient = layer === 3 && version !== "1" ? 72 : 144;
    frameBytes = Math.floor((coefficient * bitrate * 1_000) / sampleRate) + padding;
  }
  if (frameBytes < 4) return null;

  const sideInfo = version === "1" ? (mono ? 17 : 32) : (mono ? 9 : 17);
  return {
    frameBytes,
    samples,
    sampleRate,
    xingOffset: at + 4 + (protectedByCrc ? 2 : 0) + sideInfo,
  };
}

function id3v2Length(bytes: Uint8Array): number {
  if (bytes.length < 10 || bytes[0] !== 0x49 || bytes[1] !== 0x44 || bytes[2] !== 0x33) return 0;
  const size = ((bytes[6] & 0x7f) << 21) | ((bytes[7] & 0x7f) << 14) | ((bytes[8] & 0x7f) << 7) | (bytes[9] & 0x7f);
  const footer = (bytes[5] & 0x10) !== 0 ? 10 : 0;
  return 10 + size + footer;
}

function tagAt(bytes: Uint8Array, offset: number, tag: string): boolean {
  if (offset + tag.length > bytes.length) return false;
  for (let index = 0; index < tag.length; index += 1) {
    if (bytes[offset + index] !== tag.charCodeAt(index)) return false;
  }
  return true;
}

/// Gerçek ses çerçevelerinin toplam süresi, milisaniye. Çözülemeyen dosya için 0.
export function mp3DurationMs(input: ArrayBuffer | Uint8Array): number {
  const bytes = input instanceof Uint8Array ? input : new Uint8Array(input);
  let cursor = id3v2Length(bytes);
  let seconds = 0;
  let isFirstFrame = true;

  while (cursor + 4 <= bytes.length) {
    const header = parseHeader(bytes, cursor);
    if (!header) {
      // Senkron kaybı: bir sonraki olası başlığa ilerle (bozuk baş/son baytlar).
      cursor += 1;
      continue;
    }
    const carriesNoAudio = isFirstFrame && (
      tagAt(bytes, header.xingOffset, "Xing") ||
      tagAt(bytes, header.xingOffset, "Info") ||
      tagAt(bytes, cursor + 36, "VBRI")
    );
    if (!carriesNoAudio) seconds += header.samples / header.sampleRate;
    isFirstFrame = false;
    cursor += header.frameBytes;
  }
  return Math.round(seconds * 1_000);
}
