import Foundation

/// Manifestin zaman çizelgesi: hem ses hem ekran **aynı** sayıları buradan okur.
///
/// Önceden üç saat vardı ve birbirini tutmuyordu: oynatıcı sonraki dosyayı
/// `Σ durationMs` anında başlatıyor, ekran sahneleri manifestin süresinden ve
/// sabit 10 sn'lik nefesten kuruyor, gerçek ise MP3'ün kendisiydi. Çizelge tek
/// yerde kuruluyor; oynatıcı dosyayı yükleyip **ölçtüğünde** (`measured`) yeniden
/// kuruyor ve ekran sahnelerini o çizelgeden türetiyor.
///
/// Değişmez: `entries[i].start >= entries[i-1].end` — çizelgede asla çakışma yok.
struct SessionTimeline: Equatable, Sendable {
    struct Entry: Equatable, Sendable {
        let event: SessionEvent
        let start: TimeInterval
        let end: TimeInterval
        /// Konuşmadan önceki bağlantı boşluğu; `[start, start + leadIn)` aralığı
        /// sessizdir, ses `contentStart`ta başlar. Konuşma dışı olaylarda 0.
        let leadIn: TimeInterval
        /// Kenar geçişleri (K4). Oynatıcı yalnızca uç tamponlara uygular.
        let fadeIn: TimeInterval
        let fadeOut: TimeInterval

        /// Sesin (ya da sessizliğin içeriğinin) gerçekten başladığı an.
        var contentStart: TimeInterval { start + leadIn }
    }

    let entries: [Entry]
    let duration: TimeInterval
    /// Çözülmüş nefes periyodu (saniye).
    let breathPeriod: TimeInterval

    /// - Parameter measured: dosyadan **ölçülmüş** konuşma süreleri (asset kimliğine
    ///   göre, saniye). Manifestin `durationMs`i bir planlama değeridir; ölçüm
    ///   varsa onu ezer, toplam süre dosyaları izler.
    init(manifest: SessionManifest, measured: [UUID: TimeInterval] = [:]) {
        let breathMilliseconds = manifest.resolvedBreathMilliseconds
        let breath = TimeInterval(breathMilliseconds) / 1_000
        var cursor: TimeInterval = 0
        var built: [Entry] = []
        let events = manifest.events

        for (index, event) in events.enumerated() {
            let previous = index > 0 ? events[index - 1] : nil
            let next = index + 1 < events.count ? events[index + 1] : nil
            let entry: Entry

            switch event {
            case .speech(let speech):
                let leadIn = TimeInterval(speech.leadInMilliseconds) / 1_000
                let length = measured[speech.assetID] ?? TimeInterval(speech.durationMilliseconds) / 1_000
                let fadeIn: TimeInterval
                switch previous {
                case .speech, .none:
                    // Bitişik konuşma ya da açılış: yalnızca tıklama önleyici / kısa giriş.
                    fadeIn = previous == nil ? SessionPacing.fadeInShort : SessionPacing.declick
                case .gap(let milliseconds):
                    fadeIn = SessionPacing.fadeIn(afterGap: TimeInterval(milliseconds) / 1_000, breath: breath)
                case .silence(let silence):
                    let gap = TimeInterval(silence.duration(defaultBreathMilliseconds: breathMilliseconds)) / 1_000
                    fadeIn = SessionPacing.fadeIn(afterGap: gap, breath: breath)
                }
                let followedByQuiet: Bool
                switch next {
                case .silence, .gap: followedByQuiet = true
                case .speech, .none: followedByQuiet = false
                }
                entry = Entry(
                    event: event,
                    start: cursor,
                    end: cursor + leadIn + length,
                    leadIn: leadIn,
                    fadeIn: fadeIn,
                    fadeOut: followedByQuiet ? SessionPacing.fadeOut : SessionPacing.declick
                )
            case .gap(let milliseconds):
                entry = Entry(event: event, start: cursor, end: cursor + TimeInterval(milliseconds) / 1_000, leadIn: 0, fadeIn: 0, fadeOut: 0)
            case .silence(let silence):
                let length = TimeInterval(silence.duration(defaultBreathMilliseconds: breathMilliseconds)) / 1_000
                entry = Entry(event: event, start: cursor, end: cursor + length, leadIn: 0, fadeIn: 0, fadeOut: 0)
            }
            cursor = entry.end
            built.append(entry)
        }

        entries = built
        duration = cursor
        breathPeriod = breath
    }

    func currentEvent(at time: TimeInterval) -> Entry? {
        guard time >= 0, time < duration else { return nil }
        return entries.first { time >= $0.start && time < $0.end }
    }
}
