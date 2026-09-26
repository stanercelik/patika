// Kriz taraması — değiştirilemez güvenlik kuralı (CLAUDE.md).
//
// Kullanıcının yazdığı her serbest metin bu tek kaynaktan geçer: path üretimi
// (generate-path), adım cevabı (complete-step) ve defter notu (save-note) aynı
// taramayı paylaşır; biri gevşek, diğeri sık olamaz. Eşik bilerek gevşek:
// yanlış pozitifin bedeli destek ekranını görmek, yanlış negatifin bedeli
// güvenlik ihlalidir.
//
// MVP yalnızca İngilizce (2026-09-21): asıl liste İngilizce. Cihazdaki ön filtre
// (`CrisisClassifier.swift`) ile **aynı ifadeler** ve aynı normalizasyon; ikisi
// ayrışırsa istemci "temiz" der, sunucu yakalar ya da tersi. Ayrışmayı
// `crisis_contract_test.ts` denetler.
//
// Kural: ifade **tek başına** ciddi olmalı ("dayanamıyorum" gibi abartılar girmez).

/// Kesme işareti düşer, tire boşluk olur, boşluklar tekleşir, küçük harf.
export function normalizeForCrisis(text: string): string {
  // Dil bağımsız küçük harf: "tr" yerelinde "I" noktasız "ı" olur ve "I wish" eşleşmez.
  // Türkçe "İ" küçülünce "i" + birleşik nokta verir; nokta ve "ı" ASCII'ye eşlenir
  // (istemcideki `turkishToASCII` ile aynı sonuç).
  return text
    .toLowerCase()
    .replace(/\u0307/g, "")
    .replace(/\u0131/g, "i")
    .replace(/[\u2019']/g, "")
    .replace(/-/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

// Normalize edilmiş biçimde yazılı (tireler boşluk, kesme işareti yok).
export const crisisPhrases: readonly string[] = [
  // İngilizce — niyet
  "suicide", "suicidal", "kill myself", "killing myself", "end my life", "ending my life",
  "take my own life", "want to die", "wanna die", "wish i were dead", "wish i was dead",
  "better off dead", "better off without me", "dont want to live", "do not want to live",
  "dont want to be alive", "no reason to live", "not worth living", "no point in living",
  "dont want to wake up", "end it all",
  // İngilizce — kendine zarar, plan, araç
  "hurt myself", "harm myself", "self harm", "cut myself", "cutting myself", "slit my wrists",
  "hang myself", "shoot myself", "overdose", "take all my pills", "jump off a bridge",
  "jump off a building",
  // Türkçe (yeniden açılırsa; şimdilik dokunulmuyor)
  "intihar", "kendimi oldur", "kendimi öldür", "yasamak istemiyorum", "yaşamak istemiyorum",
  "canima kiymak", "canıma kıymak",
];

export function crisisSignalForText(text: string): boolean {
  const normalized = normalizeForCrisis(text);
  if (!normalized) return false;
  return crisisPhrases.some((phrase) => normalized.includes(phrase));
}
