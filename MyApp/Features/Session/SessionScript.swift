import Foundation

/// Oturumun sahnelerini kuran saf kurallar.
///
/// İki kaynak var ve ikisi de buradan geçiyor: sunucunun manifesti (ses hazırsa
/// asıl kaynak) ve istemcideki blok kütüphanesi (ses yoksa ya da henüz
/// gelmediyse). Kurallar ekrandan bağımsız — onboarding'in ilk oturumu ile
/// onboarding sonrası günlük adım aynı sahneleri kuruyor.
enum SessionScript {

    /// Sunucudan gelen yuvalar + istemcideki sabit bloklar.
    ///
    /// Kişiselleştirme **çerçevede**: açılış, geçişler ve kapanış sunucudan
    /// geliyor; teknik sabit (PRD-Ek Path Üretimi §4). Yuva boşsa yerine
    /// jenerik metin konuyor — eksik yuva oturumu kısaltmaz.
    static func build(
        step: GeneratedPathStep?,
        ownWords: String?,
        targetMinutes: Int
    ) -> [SessionSegment] {
        let slots = step?.slotCopy ?? [:]
        var opening: [SessionSegment] = []
        var technique: [SessionSegment] = []
        var closing: [SessionSegment] = []

        opening.append(SessionSegment(
            id: "opening",
            text: slots[BlockLibrary.Slot.opening.rawValue]
                ?? String(localized: Copy.Session.fallbackOpening),
            kind: .opening,
            duration: 2 * BreathCycle.period
        ))

        // Kullanıcının kendi cümlesi — akışın aha momenti. B1 atlandıysa bu
        // sahne hiç kurulmuyor; uydurma bir cümle geri yansıtmak, kişiselleştirme
        // iddiasını en görünür yerde çürütürdü.
        if let ownWords, !ownWords.isEmpty {
            opening.append(SessionSegment(
                id: "ownWords",
                text: "“\(ownWords)”",
                kind: .ownWords,
                duration: 2 * BreathCycle.period
            ))
        }

        if let bridge = slots[BlockLibrary.Slot.techniqueBridge.rawValue] {
            technique.append(SessionSegment(
                id: "bridge.technique",
                text: bridge,
                kind: .bridge,
                duration: BreathCycle.period
            ))
        }

        let blocks = (step?.blockIds ?? [BlockLibrary.breathAwareness.id])
            .compactMap(BlockLibrary.block(id:))
        let resolvedBlocks = blocks.isEmpty ? [BlockLibrary.breathAwareness] : blocks

        for block in resolvedBlocks {
            for cue in block.cues {
                technique.append(SessionSegment(
                    id: "\(block.id).\(cue.id)",
                    text: String(localized: cue.text),
                    kind: .technique,
                    duration: cue.duration
                ))
            }
        }

        if let mid = slots[BlockLibrary.Slot.midBridge.rawValue], technique.count > 2 {
            technique.insert(
                SessionSegment(
                    id: "bridge.mid",
                    text: mid,
                    kind: .bridge,
                    duration: BreathCycle.period
                ),
                at: technique.count / 2
            )
        }

        closing.append(SessionSegment(
            id: "closing",
            text: slots[BlockLibrary.Slot.closing.rawValue]
                ?? String(localized: Copy.Session.fallbackClosing),
            kind: .closing,
            duration: 2 * BreathCycle.period
        ))

        // E2'nin cevabı burada karşılığını buluyor: teknik kısmın uzunluğu
        // kullanıcının seçtiği süreye ölçekleniyor. Açılış ve kapanış
        // ölçeklenmiyor — bir kez okunan cümleyi uzatmak sessizlik üretiyor.
        let target = TimeInterval(targetMinutes * 60)
        let fixed = (opening + closing).reduce(0) { $0 + $1.duration }
        let natural = technique.reduce(0) { $0 + $1.duration }
        if natural > 0 {
            let factor = min(max((target - fixed) / natural, 0.7), 2.2)
            technique = technique.map { segment in
                var scaled = segment
                // Tam nefes döngüsüne yuvarlanıyor: yarım döngüde değişen metin
                // nefesi ortasından kesiyordu.
                let cycles = max(1, (segment.duration * factor / BreathCycle.period).rounded())
                scaled.duration = cycles * BreathCycle.period
                return scaled
            }
        }

        return opening + technique + closing
    }

    static func build(from manifest: SessionManifest) -> [SessionSegment] {
        var lastText = ""
        return manifest.events.enumerated().map { index, event in
            switch event {
            case .speech(let speech):
                lastText = speech.text
                let kind: SessionSegment.Kind = speech.source == .personal ? .bridge : .technique
                return SessionSegment(
                    id: "speech.\(speech.assetID.uuidString)",
                    text: speech.text,
                    kind: kind,
                    duration: TimeInterval(speech.durationMilliseconds) / 1_000
                )
            case .gap(let milliseconds):
                return SessionSegment(
                    id: "gap.\(index)",
                    text: lastText,
                    kind: .bridge,
                    duration: TimeInterval(milliseconds) / 1_000
                )
            case .silence(let silence):
                if let displayText = silence.displayText { lastText = displayText }
                return SessionSegment(
                    id: "silence.\(index)",
                    text: lastText,
                    kind: .technique,
                    duration: TimeInterval(silence.breaths) * BreathCycle.period
                )
            }
        }
    }
}
