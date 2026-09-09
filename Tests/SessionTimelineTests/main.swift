import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

let stepID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
let assetID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
let manifest = SessionManifest(
    version: 1,
    stepID: stepID,
    pathKind: .personalized,
    locale: "tr",
    voice: .feminine,
    question: "Bugün en çok hangi anı fark ettin?",
    events: [
        .speech(.init(source: .personal, assetID: assetID, storagePath: "u/s/a.mp3", text: "Burada başla.", durationMilliseconds: 2_000)),
        .gap(milliseconds: 300),
        .silence(.init(breaths: 2, landOn: .exhale, displayText: nil)),
    ]
)
let timeline = SessionTimeline(manifest: manifest)
expect(abs(timeline.duration - 22.3) < 0.001, "timeline duration")
expect(timeline.currentEvent(at: 0)?.event == manifest.events[0], "first event")
expect(timeline.currentEvent(at: 2.15)?.event == manifest.events[1], "gap boundary")
expect(timeline.currentEvent(at: 2.3)?.event == manifest.events[2], "silence boundary")
expect(timeline.currentEvent(at: 22.3) == nil, "end boundary")

let decoder = JSONDecoder()
let unknownVersion = Data("""
{"version":2,"stepId":"11111111-1111-1111-1111-111111111111","pathKind":"personalized","locale":"tr","voice":"feminine","question":null,"events":[]}
""".utf8)
do {
    _ = try decoder.decode(SessionManifest.self, from: unknownVersion)
    fatalError("unknown manifest version accepted")
} catch {}

let preparedWithQuestion = Data("""
{"version":1,"stepId":"11111111-1111-1111-1111-111111111111","pathKind":"prepared","locale":"en","voice":"masculine","question":"How was it?","events":[]}
""".utf8)
do {
    _ = try decoder.decode(SessionManifest.self, from: preparedWithQuestion)
    fatalError("prepared manifest question accepted")
} catch {}

print("SessionTimelineTests passed")

