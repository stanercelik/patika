// Ölçüm maddelerinin cevap tavanları ve yönü.
//
// İstemcideki `MeasurementLibrary` ile **birebir aynı** olmak zorunda. Daha
// önce bu bilgi `calculateScores` içinde "emotion.intensity ise 10, değilse 4"
// diye tahmin ediliyordu ve yanlıştı: davranış maddelerinin çoğu dört kovalı
// (0–3), beş değil. En kötü cevabı veren kullanıcı 100 yerine 75 puan alıyor,
// yani zorlanması sistematik olarak olduğundan düşük ölçülüyordu.
//
// Bu tablo elle tutuluyor çünkü madde kütüphanesi istemcide (metinleriyle
// birlikte) ve sunucuya taşımak Türkçe metinleri de taşımak demek. Bir madde
// eklendiğinde **her iki taraf** güncellenmeli; istemcideki
// `Tests/MeasurementScoringTests` bu tabloyu bağlayan vakayı taşıyor.
//
// `higherMeansBetter`: yüksek cevabın iyiye işaret ettiği maddeler. Skor
// zorlanma ölçtüğü için bunlarda eksen çevriliyor.
export type MeasurementItemSpec = { max: number; higherMeansBetter: boolean };

export const measurementItems: Record<string, MeasurementItemSpec> = {
  "emotion.intensity": { max: 10, higherMeansBetter: false },
  "emotion.frequency": { max: 4, higherMeansBetter: false },

  "behavior.sleepLatency": { max: 4, higherMeansBetter: false },
  "behavior.dailyImpact": { max: 4, higherMeansBetter: false },
  "behavior.avoidanceCount": { max: 3, higherMeansBetter: false },
  "behavior.nightWakings": { max: 3, higherMeansBetter: false },
  "behavior.missedStudySessions": { max: 3, higherMeansBetter: false },
  "behavior.declinedInvitations": { max: 3, higherMeansBetter: false },
  "behavior.regrettedReactions": { max: 3, higherMeansBetter: false },
  "behavior.disruptedDays": { max: 3, higherMeansBetter: false },
  // Tek ters yönlü davranış maddesi: burada yüksek cevap iyi habere işaret.
  "behavior.breaksTaken": { max: 3, higherMeansBetter: true },

  "selfEfficacy.knowsWhatToDo": { max: 4, higherMeansBetter: true },
  "selfEfficacy.believesChangePossible": { max: 4, higherMeansBetter: true },
};

/// Doğrulamada kullanılan tavan. Tanınmayan madde kimliği reddedilmiyor —
/// eski bir uygulama sürümü yeni bir maddeyle gelirse ölçüm tamamen
/// kaybolmasın diye — ama tavanı bilinmediği için serbest bırakılmıyor.
export function maximumFor(key: string): number {
  return measurementItems[key]?.max ?? 10;
}

/// 0…100 zorlanma değeri. Düşük = daha az zorlanma.
export function normalize(key: string, raw: number): number {
  const spec = measurementItems[key];
  const maximum = spec?.max ?? 10;
  const ratio = Math.min(100, Math.max(0, (raw / maximum) * 100));
  return spec?.higherMeansBetter ? 100 - ratio : ratio;
}
