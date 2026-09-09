import Foundation

/// Tek bir ölçüm noktasının skoru — PRD §8.2.
///
/// ## Yön: 0…100 ve **düşük iyidir**
///
/// Skor bir "başarı puanı" değil, bir **zorlanma** ölçüsü. Yüksek cevap her
/// maddede kötüye işaret etmiyor (`MeasurementItem.higherMeansBetter`), bu yüzden
/// normalize ederken yön düzeltiliyor ve sonuçta tek bir eksende buluşuyor:
/// düşük = daha az zorlanma.
///
/// Bu yön sunucudaki `calculateScores` ile aynıdır (`generate-path/index.ts`).
/// İkisi ayrı ayrı yazılmış durumda — bkz. `MeasurementScoring` içindeki uyarı.
struct MeasurementScore: Equatable, Sendable {
    /// Katman → 0…100.
    let layers: [MeasurementLayer: Double]
    /// Ağırlıklı bileşik skor (PRD §8.2: duygu %30, davranış %40, öz-yeterlik %30).
    let composite: Double

    func value(for layer: MeasurementLayer) -> Double? { layers[layer] }
}

/// İki ölçüm noktasının karşılaştırması.
///
/// **Skorlar asla mutlak yorumlanmaz** (PRD §8): "senin kaygı puanın 62" diye bir
/// cümle hiçbir yerde kurulmaz. Anlamı olan tek şey kullanıcının kendi
/// geçmişiyle farkı — bu tip o farkı taşır, tek başına skoru değil.
struct MeasurementComparison: Equatable, Sendable {
    /// Yön. Renk **tek başına** bu bilgiyi taşıyamaz; ok ve metinle birlikte
    /// gösterilmesi zorunlu (erişilebilirlik kuralı).
    enum Direction: Equatable, Sendable {
        case improved
        case unchanged
        case worsened
    }

    let baseline: MeasurementScore
    let latest: MeasurementScore
    /// Katman → yön.
    let directions: [MeasurementLayer: Direction]
    /// Katman → yüzde değişim. Negatif = iyileşme (skor düştü).
    let layerChanges: [MeasurementLayer: Double]
    let compositeDirection: Direction
    /// Bileşik skordaki yüzde değişim. Negatif = iyileşme.
    let compositeChange: Double
    /// Baseline tek noktadan mı hesaplandı? PRD §8 iki günün ortalamasını
    /// istiyor; ikinci gün henüz yoksa karşılaştırma yapılabilir ama
    /// ortalamaya dönüş etkisine açık olduğu **söylenmeli**.
    let baselineIsProvisional: Bool

    /// İyileşme yüzdesi, pozitif okunacak biçimde. Kova eşikleri bunu kullanır.
    var compositeImprovement: Double { -compositeChange }

    func direction(for layer: MeasurementLayer) -> Direction {
        directions[layer] ?? .unchanged
    }

    func improvement(for layer: MeasurementLayer) -> Double {
        -(layerChanges[layer] ?? 0)
    }
}

/// Ölçüm skorlama servisi — PRD §8.2, §7.9.
///
/// ## Burada AI yok ve bu bilinçli
///
/// Path üretim hattındaki sekiz adımın üçünde model yok: ölçüm skorlaması, kova
/// ataması ve path uzunluğu **deterministiktir** (PRD-Ek Path Üretimi). Gerekçe
/// ticari değil etik: "Kova C'de satış yok" bir taahhüt; kovayı bir modelin
/// belirlediği üründe o taahhüdün anlamı kalmaz.
///
/// ## Maksimum değerler maddeden okunur, elle yazılmaz
///
/// Sunucu tarafı (`generate-path/index.ts` → `calculateScores`) bugün maddenin
/// tavanını (`emotion.intensity` → 10, diğerleri → 4) ve ters yönlü maddelerin
/// listesini (`selfEfficacy.*`, `behavior.breaksTaken`) **elle** taşıyor. İstemci
/// tarafı bunları `MeasurementItem`den okuyor: cevap kovası eklendiğinde ya da
/// yeni bir ters yönlü madde yazıldığında burası kendiliğinden doğru kalıyor.
///
/// > **Sürüklenme riski:** iki uygulama bugün aynı sonucu üretiyor (doğrulandı),
/// > ama tek kaynak değiller. `MeasurementLibrary` değiştiğinde sunucudaki
/// > `calculateScores` da elden geçirilmeli. Kalıcı çözüm skorlamanın tek yerde
/// > kalması; o karar ölçüm servisinin sunucuya taşınmasıyla birlikte verilecek.
enum MeasurementScoring {

    // MARK: - Tek nokta skoru

    /// Ham cevapları 0…100 skora çevirir.
    ///
    /// Cevaplanmamış maddeler **atlanır**, sıfır sayılmaz: cevapsız bir madde
    /// "hiç zorlanmıyorum" demek değil, "bilmiyoruz" demek. Sıfır saymak
    /// eksik ölçümü yapay olarak iyi gösterirdi.
    ///
    /// - Returns: Hiçbir madde cevaplanmamışsa `nil`.
    static func score(
        responses: [String: Double],
        items: [MeasurementItem]
    ) -> MeasurementScore? {
        var byLayer: [MeasurementLayer: [Double]] = [:]

        for item in items {
            guard let raw = responses[item.id] else { continue }
            byLayer[item.layer, default: []].append(normalized(raw, for: item))
        }
        guard !byLayer.isEmpty else { return nil }

        let layers = byLayer.mapValues { values in
            values.reduce(0, +) / Double(values.count)
        }

        // Ağırlıklar eksik katmana göre yeniden dağıtılıyor: bir katmanın
        // maddesi hiç cevaplanmadıysa bileşik skoru düşük göstermek yerine
        // kalan katmanların ağırlığı normalize ediliyor.
        let totalWeight = layers.keys.reduce(0) { $0 + $1.weight }
        let composite = totalWeight > 0
            ? layers.reduce(0) { $0 + $1.value * $1.key.weight } / totalWeight
            : 0

        return MeasurementScore(layers: layers, composite: composite)
    }

    /// Tek bir maddenin ham cevabını 0…100 zorlanma değerine çevirir.
    static func normalized(_ raw: Double, for item: MeasurementItem) -> Double {
        let maximum = maximumRawValue(for: item)
        guard maximum > 0 else { return 0 }
        let ratio = min(max(raw / maximum, 0), 1) * 100
        // Yüksek cevabın iyiye işaret ettiği maddelerde eksen çevriliyor ki
        // bütün maddeler aynı yönde toplanabilsin.
        return item.higherMeansBetter ? 100 - ratio : ratio
    }

    /// Maddenin cevap tavanı — cevap biçiminden türetilir.
    static func maximumRawValue(for item: MeasurementItem) -> Double {
        switch item.style {
        case .intensity:
            Double(MeasurementLibrary.intensityRange.upperBound)
        case .choice(let options):
            options.map(\.value).max() ?? 0
        }
    }

    // MARK: - Baseline

    /// Baseline **tek nokta değil, ilk iki ölçümün ortalamasıdır** (PRD §8).
    ///
    /// Gerekçe istatistiksel: insanlar uygulamayı en kötü hissettikleri gün
    /// indiriyor. Tek noktalı bir baseline, ortalamaya dönüşü (regression to the
    /// mean) ürünün etkisi gibi gösterir — yani hiçbir şey yapmasak bile 7. günde
    /// "iyileşme" ölçerdik. İkinci gün gelmediyse karşılaştırma yine yapılır ama
    /// `baselineIsProvisional` ile işaretlenir.
    static func baseline(from points: [MeasurementScore]) -> (score: MeasurementScore, isProvisional: Bool)? {
        let used = Array(points.prefix(2))
        switch used.count {
        case 0: return nil
        case 1: return (used[0], true)
        default: return (average(used), false)
        }
    }

    private static func average(_ scores: [MeasurementScore]) -> MeasurementScore {
        var sums: [MeasurementLayer: (total: Double, count: Int)] = [:]
        for score in scores {
            for (layer, value) in score.layers {
                let current = sums[layer] ?? (0, 0)
                sums[layer] = (current.total + value, current.count + 1)
            }
        }
        let layers = sums.mapValues { $0.total / Double($0.count) }
        let composite = scores.reduce(0) { $0 + $1.composite } / Double(scores.count)
        return MeasurementScore(layers: layers, composite: composite)
    }

    // MARK: - Karşılaştırma

    /// İki noktayı karşılaştırır.
    ///
    /// - Parameter items: Yön eşiğini hesaplamak için gerekli — bkz. `resolution`.
    static func compare(
        baseline: MeasurementScore,
        latest: MeasurementScore,
        items: [MeasurementItem],
        baselineIsProvisional: Bool
    ) -> MeasurementComparison {
        var directions: [MeasurementLayer: MeasurementComparison.Direction] = [:]
        var changes: [MeasurementLayer: Double] = [:]

        for layer in MeasurementLayer.allCases {
            guard let before = baseline.layers[layer], let after = latest.layers[layer] else { continue }
            changes[layer] = percentChange(from: before, to: after)
            directions[layer] = direction(
                from: before,
                to: after,
                threshold: resolution(of: layer, items: items)
            )
        }

        // Bileşik eşik, katman eşiklerinin ağırlıklı toplamı: bileşik skor da
        // öyle hesaplanıyor, eşiğin başka bir yerden gelmesi tutarsız olurdu.
        let compositeThreshold = MeasurementLayer.allCases.reduce(0.0) { total, layer in
            total + resolution(of: layer, items: items) * layer.weight
        }

        return MeasurementComparison(
            baseline: baseline,
            latest: latest,
            directions: directions,
            layerChanges: changes,
            compositeDirection: direction(
                from: baseline.composite,
                to: latest.composite,
                threshold: compositeThreshold
            ),
            compositeChange: percentChange(from: baseline.composite, to: latest.composite),
            baselineIsProvisional: baselineIsProvisional
        )
    }

    /// Bir katmanda **ölçülebilen en küçük değişim**, 0…100 ölçeğinde.
    ///
    /// Yön eşiği buradan geliyor ve bu bilinçli bir seçim: elimizde gürültü
    /// tahmini üretecek veri yok (Faz 0 tamamlanmadı), o yüzden uydurma bir
    /// sabit yazmak yerine **aracın kendi çözünürlüğü** eşik alınıyor. Aracın
    /// ifade edemediği bir fark, fark değildir.
    ///
    /// Örnek: duygu katmanı iki maddeli; şiddet ölçeğinde bir kademe 100/10 = 10
    /// puan, katmana yansıması 10/2 = 5 puan. Yani duygu katmanında 5 puandan
    /// küçük bir hareket "değişmedi" sayılır.
    ///
    /// > Bu eşik **geçicidir**. Faz 0'da aynı kullanıcıya art arda iki gün
    /// > uygulanan ölçümün kendi oynaklığı görüldüğünde buraya gerçek bir
    /// > gürültü tabanı yazılmalı; büyük ihtimalle bundan yüksek olacak.
    static func resolution(of layer: MeasurementLayer, items: [MeasurementItem]) -> Double {
        let layerItems = items.filter { $0.layer == layer }
        guard !layerItems.isEmpty else { return .infinity }

        let smallestStep = layerItems.compactMap { item -> Double? in
            let maximum = maximumRawValue(for: item)
            guard maximum > 0 else { return nil }
            return smallestRawStep(for: item) / maximum * 100
        }.min()

        guard let smallestStep else { return .infinity }
        return smallestStep / Double(layerItems.count)
    }

    private static func smallestRawStep(for item: MeasurementItem) -> Double {
        switch item.style {
        case .intensity:
            return 1
        case .choice(let options):
            let values = options.map(\.value).sorted()
            let gaps = zip(values, values.dropFirst()).map { $1 - $0 }
            return gaps.filter { $0 > 0 }.min() ?? 1
        }
    }

    private static func direction(
        from before: Double,
        to after: Double,
        threshold: Double
    ) -> MeasurementComparison.Direction {
        let delta = after - before
        guard abs(delta) >= threshold else { return .unchanged }
        // Skor zorlanma ölçüyor: düşmesi iyileşmedir.
        return delta < 0 ? .improved : .worsened
    }

    private static func percentChange(from before: Double, to after: Double) -> Double {
        // Zaten sıfırdaysa iyileşecek bir şey yok ve bölme tanımsız.
        guard before > 0 else { return 0 }
        return (after - before) / before * 100
    }

    // MARK: - Kova ataması (PRD §7.9)

    /// Path sonu kovası. **Deterministik ve muhafazakâr.**
    ///
    /// Eşikler `OutcomeBucket` dokümantasyonundan birebir geliyor ve orada da
    /// yazdığı gibi **tahmindir, Faz 0 verisiyle kalibre edilmelidir**
    /// (PRD açık soru #5).
    ///
    /// Sıra önemli ve iki yerde bilinçli olarak sıkı taraf seçiliyor:
    ///
    /// 1. **Herhangi bir katmanda kötüleşme varsa Kova C** — diğer iki katman ne
    ///    kadar iyileşmiş olursa olsun. Bir boyutu kötüleşmiş kullanıcıya
    ///    "belirgin ilerleme" demek, ölçümü satışa çevirmek olurdu.
    /// 2. **%5–10 aralığı da Kova C.** Kural metni B'yi %10'dan başlatıyor, C'yi
    ///    %5'te bitiriyor; aradaki boşluk aşağı yuvarlanıyor. Yön tesadüf değil:
    ///    Kova C satış yapılmayan kovadır, yani belirsizlikte hata yapmanın
    ///    bedelini şirket ödüyor, kullanıcı değil (PRD karar #3).
    static func bucket(for comparison: MeasurementComparison) -> OutcomeBucket {
        if comparison.directions.values.contains(.worsened) { return .noProgress }

        let composite = comparison.compositeImprovement
        let strongLayers = MeasurementLayer.allCases.filter {
            comparison.improvement(for: $0) >= 30
        }
        if composite >= 25 || strongLayers.count >= 2 { return .clearProgress }
        if composite >= 10 { return .partialProgress }
        return .noProgress
    }
}
