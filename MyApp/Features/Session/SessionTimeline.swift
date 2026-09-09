import Foundation

struct SessionTimeline: Equatable, Sendable {
    struct Entry: Equatable, Sendable {
        let event: SessionEvent
        let start: TimeInterval
        let end: TimeInterval
    }

    let entries: [Entry]
    let duration: TimeInterval

    init(manifest: SessionManifest, breathDuration: TimeInterval = 10) {
        var cursor: TimeInterval = 0
        entries = manifest.events.map { event in
            let eventDuration: TimeInterval
            switch event {
            case .speech(let speech): eventDuration = TimeInterval(speech.durationMilliseconds) / 1_000
            case .gap(let milliseconds): eventDuration = TimeInterval(milliseconds) / 1_000
            case .silence(let silence): eventDuration = TimeInterval(silence.breaths) * breathDuration
            }
            let entry = Entry(event: event, start: cursor, end: cursor + eventDuration)
            cursor = entry.end
            return entry
        }
        duration = cursor
    }

    func currentEvent(at time: TimeInterval) -> Entry? {
        guard time >= 0, time < duration else { return nil }
        return entries.first { time >= $0.start && time < $0.end }
    }
}

