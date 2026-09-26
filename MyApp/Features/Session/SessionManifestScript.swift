import Foundation

/// Sunucu manifestinden ekran sahnelerini kuran saf kurallar.
///
/// Sahneler artık `manifest.events` değil **`SessionTimeline`** üzerinden kuruluyor:
/// ekran ile ses farklı sayı hesaplayamaz. Eskiden sahne süresi `durationMs`ten ve
/// sabit 10 sn'lik nefesten geliyordu; ses ise dosyanın gerçek uzunluğuyla çalıyordu.
enum SessionManifestScript {

    static func segments(from manifest: SessionManifest, measured: [UUID: TimeInterval] = [:]) -> [SessionSegment] {
        segments(from: SessionTimeline(manifest: manifest, measured: measured))
    }

    static func segments(from timeline: SessionTimeline) -> [SessionSegment] {
        var segments: [SessionSegment] = []
        var lastText = ""

        for (index, entry) in timeline.entries.enumerated() {
            switch entry.event {
            case .speech(let speech):
                lastText = speech.text
                let kind: SessionSegment.Kind = speech.source == .personal ? .bridge : .technique
                var duration = entry.end - entry.start
                // K1: bağlantı boşluğu bir önceki sahnenin sonunda geçer, yeni cümle
                // **duyulduğu anda** belirir. Boşluk için ayrı bir sahne (ve cross-fade)
                // olsaydı aynı cümle 350 ms için solup geri gelirdi.
                if entry.leadIn > 0, !segments.isEmpty {
                    segments[segments.count - 1].duration += entry.leadIn
                    duration -= entry.leadIn
                }
                segments.append(SessionSegment(
                    id: "speech.\(speech.assetID.uuidString)",
                    text: speech.text,
                    kind: kind,
                    duration: duration
                ))
            case .gap, .silence:
                let duration = entry.end - entry.start
                if case .silence(let silence) = entry.event, let displayText = silence.displayText {
                    // Metin taşıyan sessizlik (ör. Keşfet'in "quiet" satırı) kendi sahnesi.
                    lastText = displayText
                    segments.append(SessionSegment(id: "silence.\(index)", text: lastText, kind: .technique, duration: duration))
                } else if !segments.isEmpty {
                    // K5: metinsiz bekleme önceki konuşmanın sahnesine katılır. Son cümle
                    // duraklama boyunca ekranda kalır, yeniden belirmez.
                    segments[segments.count - 1].duration += duration
                } else {
                    segments.append(SessionSegment(id: "silence.\(index)", text: lastText, kind: .technique, duration: duration))
                }
            }
        }
        return segments
    }
}
