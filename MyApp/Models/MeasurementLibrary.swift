import Foundation

/// Bir ölçüm maddesinin cevap biçimi.
///
/// Yalnızca iki biçim var ve bu bilinçli: her yeni cevap widget'ı yeni bir
/// erişilebilirlik, Dynamic Type ve kontrast yüzeyi demek. Sekiz sorunun yedisi
/// "birini seç" ile sorulabiliyor; sekizincisi (şiddet) ölçek olmadan bilgi
/// kaybediyor.
enum MeasurementAnswerStyle {
    /// 0–10 şiddet ölçeği (PRD-Ek Onboarding §5, D1).
    case intensity
    /// Sıralı kovalar. Sıra anlamlıdır: `value` düşükten yükseğe artar.
    case choice([MeasurementOption])
}

/// Tek bir cevap kovası. `value` ham cevaptır — `Measurement.rawResponses`a
/// olduğu gibi yazılır, normalize edilmez.
struct MeasurementOption: Identifiable, Hashable, Sendable {
    let value: Double
    let label: LocalizedStringResource

    var id: Double { value }

    static func == (lhs: MeasurementOption, rhs: MeasurementOption) -> Bool {
        lhs.value == rhs.value
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

/// Bir ölçüm maddesi.
///
/// ## Madde rotasyonu koda gömülüdür
///
/// PRD §8.3: baştaki ve sondaki test aynı yapıda ama birebir aynı ifadelerle
/// değil. İnsanlar ne cevap verdiklerini hatırlar ve "ilerlemiş görünme"
/// eğilimine girer. Bu yüzden ifade `MeasurementVariant`a göre değişir, cevap
/// kovaları ve `id` **değişmez** — skorlama ve karşılaştırma aynı kalır.
///
/// `prompts` eksik bir varyant taşıyorsa `.a`ya düşer: path tipine özel D5
/// maddesinin varyantları, blok/şablon kütüphanesi yazıldığında (PRD §8.5)
/// oradan gelecek.
struct MeasurementItem: Identifiable {
    /// `Measurement.rawResponses` anahtarı. **Asla değişmez** — değişirse
    /// kullanıcının geçmiş ölçümüyle karşılaştırma kopar.
    let id: String
    let layer: MeasurementLayer
    let prompts: [MeasurementVariant: LocalizedStringResource]
    let hint: LocalizedStringResource?
    let style: MeasurementAnswerStyle
    /// Yüksek cevap iyiye mi işaret? Skorlama bu bayrağı okur; ekranlar okumaz.
    /// (Ölçüm ekranında iyi/kötü hiçbir yerde belli edilmez — PRD §7.3.)
    let higherMeansBetter: Bool

    func prompt(for variant: MeasurementVariant) -> LocalizedStringResource {
        prompts[variant] ?? prompts[.a] ?? ""
    }
}

/// Ölçüm maddeleri (PRD §8.2, §8.5 ve PRD-Ek Onboarding §5).
///
/// Katman ağırlıkları `MeasurementLayer.weight`te; burada yalnızca hangi maddenin
/// hangi katmana ait olduğu var. **Davranış katmanı en çok maddeyi taşır** çünkü
/// en sağlam sinyal odur ve en zor manipüle edilir.
///
/// Bu ekranların sonunda hiçbir skor gösterilmez (PRD §7.3): skorlar ilk kez 7.
/// günde, kullanıcının kendi başlangıcıyla karşılaştırmalı olarak görünür.
enum MeasurementLibrary {

    /// Bir ölçüm noktasının maddeleri.
    ///
    /// D5 kategoriye göre değişir; gerisi sabittir. Gün 14 kısadır (6 madde,
    /// PRD §8.6) — kısaltma duygu sıklığı ve genel kaçınma maddelerinden yapılır,
    /// davranış katmanının omurgası (uyku gecikmesi + path'e özel madde) korunur.
    static func items(
        for point: MeasurementPoint,
        category: ProblemCategory
    ) -> [MeasurementItem] {
        let full = [
            intensity,
            frequency,
            sleepLatency,
            avoidanceCount,
            behaviorItem(for: category),
            knowsWhatToDo,
            believesChangePossible,
            dailyImpact,
        ]

        guard point == .day14 else { return full }
        return full.filter { $0.id != frequency.id && $0.id != avoidanceCount.id }
    }

    // MARK: - Duygu şiddeti (%30)

    static let intensity = MeasurementItem(
        id: "emotion.intensity",
        layer: .emotion,
        prompts: [
            .a: .measurementLibraryIntensityA,
            .b: .measurementLibraryIntensityB,
            .c: .measurementLibraryIntensityC,
        ],
        // İpucu yok: ölçeğin iki ucundaki etiketler ("Hiç yok" / "Çok güçlü")
        // aynı şeyi zaten söylüyor, sorunun altına bir kez daha yazmak ekranı
        // gereksiz metinle dolduruyordu.
        hint: nil,
        style: .intensity,
        higherMeansBetter: false
    )

    static let frequency = MeasurementItem(
        id: "emotion.frequency",
        layer: .emotion,
        prompts: [
            .a: .measurementLibraryFrequencyA,
            .b: .measurementLibraryFrequencyB,
            .c: .measurementLibraryFrequencyC,
        ],
        hint: nil,
        style: .choice([
            .init(value: 0, label: .measurementLibraryFrequency1),
            .init(value: 1, label: .measurementLibraryFrequency2),
            .init(value: 2, label: .measurementLibraryFrequency3),
            .init(value: 3, label: .measurementLibraryFrequency4),
            .init(value: 4, label: .measurementLibraryFrequency5),
        ]),
        higherMeansBetter: false
    )

    // MARK: - Davranış (%40)

    /// Uyku gecikmesi herkese sorulur: uyku, kategoriden bağımsız olarak en
    /// güvenilir davranış sinyali ve neredeyse her zorlanma biçiminde etkileniyor.
    static let sleepLatency = MeasurementItem(
        id: "behavior.sleepLatency",
        layer: .behavior,
        prompts: [
            .a: .measurementLibrarySleepLatencyA,
            .b: .measurementLibrarySleepLatencyB,
            .c: .measurementLibrarySleepLatencyC,
        ],
        hint: nil,
        style: .choice([
            .init(value: 0, label: .measurementLibrarySleepLatency1),
            .init(value: 1, label: .measurementLibrarySleepLatency2),
            .init(value: 2, label: .measurementLibrarySleepLatency3),
            .init(value: 3, label: .measurementLibrarySleepLatency4),
            .init(value: 4, label: .measurementLibrarySleepLatency5),
        ]),
        higherMeansBetter: false
    )

    static let avoidanceCount = MeasurementItem(
        id: "behavior.avoidanceCount",
        layer: .behavior,
        prompts: [
            .a: .measurementLibraryAvoidanceCountA,
            .b: .measurementLibraryAvoidanceCountB,
            .c: .measurementLibraryAvoidanceCountC,
        ],
        hint: nil,
        style: .choice([
            .init(value: 0, label: .measurementLibraryAvoidanceCount1),
            .init(value: 1, label: .measurementLibraryRangeOneToTwo),
            .init(value: 2, label: .measurementLibraryRangeThreeToFive),
            .init(value: 3, label: .measurementLibraryAvoidanceCount2),
        ]),
        higherMeansBetter: false
    )

    /// PRD §8.5 — her path tipinin kendi davranış maddesi vardır.
    ///
    /// PRD tabloda beş path tipi sayıyor; A2'de on kategori var. Karşılığı
    /// olmayan kategoriler (kaygı, kendine sertlik, kayıp, isimsiz) ortak bir
    /// davranış maddesine düşer — uydurma bir madde yazmaktansa daha genel ama
    /// dürüst bir sinyal ölçmek daha iyi. Kategori→path eşlemesi netleştiğinde
    /// (PRD açık soru #3) bu tablo path tipiyle anahtarlanmalı.
    static func behaviorItem(for category: ProblemCategory) -> MeasurementItem {
        switch category {
        case .sleep:
            MeasurementItem(
                id: "behavior.nightWakings",
                layer: .behavior,
                prompts: [.a: .measurementLibraryBehaviorItemSleep1],
                hint: nil,
                style: .choice([
                    .init(value: 0, label: .measurementLibraryBehaviorItemSleep2),
                    .init(value: 1, label: .measurementLibraryBehaviorItemSleep3),
                    .init(value: 2, label: .measurementLibraryBehaviorItemSleep4),
                    .init(value: 3, label: .measurementLibraryBehaviorItemSleep5),
                ]),
                higherMeansBetter: false
            )
        case .exam, .focus:
            MeasurementItem(
                id: "behavior.missedStudySessions",
                layer: .behavior,
                prompts: [.a: .measurementLibraryBehaviorItemExamFocus1],
                hint: nil,
                style: .choice([
                    .init(value: 0, label: .measurementLibraryBehaviorItemExamFocus2),
                    .init(value: 1, label: .measurementLibraryRangeOneToTwo),
                    .init(value: 2, label: .measurementLibraryRangeThreeToFive),
                    .init(value: 3, label: .measurementLibraryBehaviorItemExamFocus3),
                ]),
                higherMeansBetter: false
            )
        case .social:
            MeasurementItem(
                id: "behavior.declinedInvitations",
                layer: .behavior,
                prompts: [.a: .measurementLibraryBehaviorItemSocial1],
                hint: nil,
                style: .choice([
                    .init(value: 0, label: .measurementLibraryBehaviorItemSocial2),
                    .init(value: 1, label: .measurementLibraryBehaviorItemSocial3),
                    .init(value: 2, label: .measurementLibraryBehaviorItemSocial4),
                    .init(value: 3, label: .measurementLibraryBehaviorItemSocial5),
                ]),
                higherMeansBetter: false
            )
        case .burnout:
            MeasurementItem(
                id: "behavior.breaksTaken",
                layer: .behavior,
                prompts: [.a: .measurementLibraryBehaviorItemBurnout1],
                hint: nil,
                style: .choice([
                    .init(value: 0, label: .measurementLibraryBehaviorItemBurnout2),
                    .init(value: 1, label: .measurementLibraryBehaviorItemBurnout3),
                    .init(value: 2, label: .measurementLibraryBehaviorItemBurnout4),
                    .init(value: 3, label: .measurementLibraryBehaviorItemBurnout5),
                ]),
                // Tek ters yönlü madde: burada yüksek cevap iyi habere işaret.
                higherMeansBetter: true
            )
        case .anger:
            MeasurementItem(
                id: "behavior.regrettedReactions",
                layer: .behavior,
                prompts: [.a: .measurementLibraryBehaviorItemAnger1],
                hint: nil,
                style: .choice([
                    .init(value: 0, label: .measurementLibraryBehaviorItemAnger2),
                    .init(value: 1, label: .measurementLibraryRangeOneToTwo),
                    .init(value: 2, label: .measurementLibraryRangeThreeToFive),
                    .init(value: 3, label: .measurementLibraryBehaviorItemAnger3),
                ]),
                higherMeansBetter: false
            )
        case .anxiety, .selfcrit, .grief, .unnamed:
            MeasurementItem(
                id: "behavior.disruptedDays",
                layer: .behavior,
                prompts: [.a: .measurementLibraryBehaviorItemAnxietySelfcritGriefUnnamed1],
                hint: nil,
                style: .choice([
                    .init(value: 0, label: .measurementLibraryBehaviorItemAnxietySelfcritGriefUnnamed2),
                    .init(value: 1, label: .measurementLibraryBehaviorItemAnxietySelfcritGriefUnnamed3),
                    .init(value: 2, label: .measurementLibraryBehaviorItemAnxietySelfcritGriefUnnamed4),
                    .init(value: 3, label: .measurementLibraryBehaviorItemAnxietySelfcritGriefUnnamed5),
                ]),
                higherMeansBetter: false
            )
        }
    }

    // MARK: - Öz-yeterlik (%30)

    /// Öz-yeterlik meditasyonun en gerçekçi çıktısı ve genelde en hızlı iyileşen
    /// boyut (PRD §8.2) — 7. günde pozitif sinyal üretme ihtimali en yüksek olan
    /// katman burası.
    static let knowsWhatToDo = MeasurementItem(
        id: "selfEfficacy.knowsWhatToDo",
        layer: .selfEfficacy,
        prompts: [
            .a: .measurementLibraryKnowsWhatToDoA,
            .b: .measurementLibraryKnowsWhatToDoB,
            .c: .measurementLibraryKnowsWhatToDoC,
        ],
        hint: nil,
        style: .choice(agreementOptions),
        higherMeansBetter: true
    )

    static let believesChangePossible = MeasurementItem(
        id: "selfEfficacy.believesChangePossible",
        layer: .selfEfficacy,
        prompts: [
            .a: .measurementLibraryBelievesChangePossibleA,
            .b: .measurementLibraryBelievesChangePossibleB,
            .c: .measurementLibraryBelievesChangePossibleC,
        ],
        hint: nil,
        style: .choice(agreementOptions),
        higherMeansBetter: true
    )

    /// PRD-Ek Onboarding §5 bu maddeyi "Etki" başlığıyla ayrı bir katman gibi
    /// listeliyor; skorlama modelinde (PRD §8.2) üç katman var. Günlük hayatın
    /// aksaması gözlemlenebilir bir çıktı olduğu için davranış katmanına
    /// yazılıyor — dördüncü bir katman açmak ağırlıkların yeniden dağıtılması
    /// demekti ve o karar Faz 0 verisine bağlı.
    static let dailyImpact = MeasurementItem(
        id: "behavior.dailyImpact",
        layer: .behavior,
        prompts: [
            .a: .measurementLibraryDailyImpactA,
            .b: .measurementLibraryDailyImpactB,
            .c: .measurementLibraryDailyImpactC,
        ],
        hint: nil,
        style: .choice([
            .init(value: 0, label: .measurementLibraryDailyImpact1),
            .init(value: 1, label: .measurementLibraryDailyImpact2),
            .init(value: 2, label: .measurementLibraryDailyImpact3),
            .init(value: 3, label: .measurementLibraryDailyImpact4),
            .init(value: 4, label: .measurementLibraryDailyImpact5),
        ]),
        higherMeansBetter: false
    )

    /// 1–5 katılım ölçeği. "Kararsızım" ortada duruyor ve dürüst bir cevap —
    /// kullanıcıyı bir yöne itmemek için tarafsız ifade edildi.
    static let agreementOptions: [MeasurementOption] = [
        .init(value: 0, label: .measurementLibraryAgreementOptions1),
        .init(value: 1, label: .measurementLibraryAgreementOptions2),
        .init(value: 2, label: .measurementLibraryAgreementOptions3),
        .init(value: 3, label: .measurementLibraryAgreementOptions4),
        .init(value: 4, label: .measurementLibraryAgreementOptions5),
    ]

    /// D1'in ölçek sınırları.
    static let intensityRange = 0...10
}
