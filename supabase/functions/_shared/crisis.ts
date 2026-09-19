// Kriz taraması — değiştirilemez güvenlik kuralı (CLAUDE.md).
//
// Kullanıcının yazdığı her serbest metin bu tek kaynaktan geçer: path üretimi
// (generate-path), adım cevabı (complete-step) ve defter notu (save-note) aynı
// taramayı paylaşır; biri gevşek, diğeri sık olamaz. Eşik bilerek gevşek:
// yanlış pozitifin bedeli destek ekranını görmek, yanlış negatifin bedeli
// güvenlik ihlalidir.

const crisisPatterns = [
  /intihar/i, /kendimi oldur/i, /kendimi öldür/i, /yasamak istemiyorum/i,
  /yaşamak istemiyorum/i, /canima kiymak/i, /canıma kıymak/i, /self[ -]?harm/i,
  /kill myself/i, /suicide/i,
];

export function crisisSignalForText(text: string): boolean {
  return crisisPatterns.some((pattern) => pattern.test(text));
}
