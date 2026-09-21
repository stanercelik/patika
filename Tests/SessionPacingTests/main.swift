import Foundation

// Oturum tempo kuralları (K1-K6). Test hedefi yok, elle derlenir:
//
//   swiftc -o /tmp/pacingtest \
//     MyApp/Models/SessionManifest.swift MyApp/Features/Session/SessionTimeline.swift \
//     MyApp/Features/Session/SessionPacing.swift MyApp/Features/Session/SessionSegment.swift \
//     MyApp/Features/Session/SessionManifestScript.swift \
//     Tests/SessionPacingTests/main.swift && /tmp/pacingtest

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError("FAILED: \(message)") }
}
func near(_ a: TimeInterval, _ b: TimeInterval, _ tolerance: TimeInterval = 0.001) -> Bool { abs(a - b) <= tolerance }

let stepID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
func id(_ n: Int) -> UUID { UUID(uuidString: String(format: "%08d-0000-0000-0000-000000000000", n))! }
func speech(_ n: Int, ms: Int, leadIn: Int = 0, text: String? = nil, source: SessionSpeech.Source = .block) -> SessionEvent {
    .speech(SessionSpeech(source: source, assetID: id(n), storagePath: "x\(n).mp3", text: text ?? "Sentence \(n).", durationMilliseconds: ms, leadInMilliseconds: leadIn))
}
func manifest(_ events: [SessionEvent], breathMs: Int? = nil) -> SessionManifest {
    SessionManifest(version: 1, stepID: stepID, pathKind: .prepared, locale: "en", voice: .feminine, question: nil, breathMilliseconds: breathMs, events: events)
}
func assertNoOverlap(_ timeline: SessionTimeline, _ label: String) {
    for i in timeline.entries.indices.dropFirst() {
        expect(timeline.entries[i].start >= timeline.entries[i - 1].end - 1e-9, "\(label): entry \(i) overlaps the previous one")
    }
    expect(near(timeline.duration, timeline.entries.last?.end ?? 0), "\(label): duration is the last end")
}

// K3, kök neden 1: bir vuruş 10 sn'ye yuvarlanmaz.
do {
    let m = manifest([speech(1, ms: 2_000), .silence(.init(milliseconds: 1_500, breaths: 1)), speech(2, ms: 2_000)])
    let t = SessionTimeline(manifest: m)
    expect(near(t.duration, 5.5), "beat is written time, not a breath (got \(t.duration))")
    assertNoOverlap(t, "beat")
}

// Kök neden 4: kutu nefesi 4 nefes = 64 sn (16 sn periyot), 40 sn değil.
do {
    let m = manifest([speech(1, ms: 1_000), .silence(.init(milliseconds: 64_000, breaths: 4, breathMilliseconds: 16_000))])
    expect(near(SessionTimeline(manifest: m).duration, 65), "box breathing is 64 s of silence")
    // ms olmayan eski manifest da bloğun periyodunu kullanır.
    let legacy = manifest([.silence(.init(breaths: 4, breathMilliseconds: 16_000))])
    expect(near(SessionTimeline(manifest: legacy).duration, 64), "breaths x block period")
    // Manifest seviyesinde periyot.
    let inherited = manifest([.silence(.init(breaths: 2))], breathMs: 12_000)
    expect(near(SessionTimeline(manifest: inherited).duration, 24), "breaths x manifest period")
    // Hiçbiri yoksa arka planın 10 sn'si.
    expect(near(SessionTimeline(manifest: manifest([.silence(.init(breaths: 3))])).duration, 30), "default 10 s breath")
}

// K1/K5: join bir olay değil. Boşluk için ayrı sahne yok, sahne sayısı değişmez.
do {
    let m = manifest([speech(1, ms: 3_000), speech(2, ms: 3_000, leadIn: 350)])
    let t = SessionTimeline(manifest: m)
    expect(near(t.duration, 6.35), "lead-in adds to the timeline")
    expect(near(t.entries[1].contentStart, 3.35), "voice starts after the lead-in")
    let segments = SessionManifestScript.segments(from: t)
    expect(segments.count == 2, "a join creates no extra scene (got \(segments.count))")
    expect(near(segments[0].duration, 3.35), "previous scene absorbs the join")
    expect(near(segments[1].duration, 3.0), "new sentence appears when it is heard")
    expect(near(segments.reduce(0) { $0 + $1.duration }, t.duration), "scenes sum to the timeline")
    expect(segments[0].id != segments[1].id, "each sentence has its own id")
    assertNoOverlap(t, "join")
}

// K5: metinsiz bekleme önceki cümleyle tek sahne; metinli bekleme kendi sahnesi.
do {
    let quiet = manifest([speech(1, ms: 2_000), .silence(.init(milliseconds: 20_000, breaths: 2, displayText: nil))])
    let s1 = SessionManifestScript.segments(from: quiet)
    expect(s1.count == 1 && near(s1[0].duration, 22), "silence without text merges into the sentence")
    let labelled = manifest([speech(1, ms: 2_000), .silence(.init(milliseconds: 20_000, breaths: 2, displayText: "Rest."))])
    let s2 = SessionManifestScript.segments(from: labelled)
    expect(s2.count == 2 && s2[1].text == "Rest.", "silence with display text is its own scene")
}

// Kök neden 3: ölçüm durationMs'i ezer, toplam süre dosyaları izler.
do {
    let m = manifest([speech(1, ms: 2_000), speech(2, ms: 3_000, leadIn: 300)])
    let t = SessionTimeline(manifest: m, measured: [id(1): 2.4, id(2): 2.7])
    expect(near(t.duration, 2.4 + 0.3 + 2.7), "measured durations replace the declared ones")
    expect(near(t.entries[1].start, 2.4), "next file starts where the measured one ends")
    assertNoOverlap(t, "measured")
    // Ölçülmemiş dosya bildirilen süreye düşer.
    let partial = SessionTimeline(manifest: m, measured: [id(1): 2.4])
    expect(near(partial.duration, 2.4 + 0.3 + 3.0), "unmeasured files keep the declared length")
}

// K4: fade-in sessizliğin nefesle karşılaştırmasına göre.
expect(near(SessionPacing.fadeIn(afterGap: 12, breath: 10), SessionPacing.fadeInLong), "long silence gets the soft entry")
expect(near(SessionPacing.fadeIn(afterGap: 4, breath: 10), SessionPacing.fadeInShort), "short silence gets the short entry")
expect(near(SessionPacing.fadeIn(afterGap: 10, breath: 10), SessionPacing.fadeInShort), "exactly one breath is still short")

do {
    let m = manifest([
        speech(1, ms: 2_000),
        speech(2, ms: 2_000, leadIn: 350),
        .silence(.init(milliseconds: 30_000, breaths: 3)),
        speech(3, ms: 2_000),
    ])
    let t = SessionTimeline(manifest: m)
    expect(near(t.entries[0].fadeIn, SessionPacing.fadeInShort), "opening enters softly")
    expect(near(t.entries[1].fadeIn, SessionPacing.declick), "a join is only declicked, not faded")
    expect(near(t.entries[1].fadeOut, SessionPacing.fadeOut), "speech before silence fades out")
    expect(near(t.entries[0].fadeOut, SessionPacing.declick), "speech before a join only declicks")
    expect(near(t.entries[3].fadeIn, SessionPacing.fadeInLong), "return after a long silence is gentle")
    assertNoOverlap(t, "fades")
}

// Eski manifestler: yalnızca breaths ve gap olayı hâlâ okunur ve doğru zamanlanır.
do {
    let json = Data("""
    {"version":1,"stepId":"11111111-1111-1111-1111-111111111111","pathKind":"personalized","locale":"tr","voice":"feminine","question":null,"events":[
      {"type":"speech","source":"personal","assetId":"22222222-2222-2222-2222-222222222222","storagePath":"u/s/a.mp3","text":"Burada başla.","durationMs":2000},
      {"type":"gap","milliseconds":300},
      {"type":"silence","breaths":2,"landOn":"exhale"}
    ]}
    """.utf8)
    let old = try! JSONDecoder().decode(SessionManifest.self, from: json)
    let t = SessionTimeline(manifest: old)
    expect(near(t.duration, 2.0 + 0.3 + 20.0), "legacy manifest keeps its timing")
    expect(t.entries[0].leadIn == 0, "legacy speech has no lead-in")
    // Kesin boşluk metinsiz bekleme gibi önceki cümleye katılır.
    expect(SessionManifestScript.segments(from: t).count == 1, "legacy gap merges, no flicker")
}

// v2 manifest gidiş-dönüş: alanlar korunur.
do {
    let m = manifest([speech(1, ms: 2_000, leadIn: 0), speech(2, ms: 2_000, leadIn: 350), .silence(.init(milliseconds: 1_500, breaths: 1, breathMilliseconds: 10_000, landOn: nil, displayText: nil))], breathMs: 10_000)
    let back = try! JSONDecoder().decode(SessionManifest.self, from: try! JSONEncoder().encode(m))
    expect(back == m, "v2 manifest round-trips")
    expect(back.breathMilliseconds == 10_000, "manifest breath survives")
}

// Sözleşme: ms de breaths de yoksa reddedilir; bilinmeyen sürüm reddedilir.
do {
    let bad = Data("""
    {"version":1,"stepId":"11111111-1111-1111-1111-111111111111","pathKind":"prepared","locale":"en","voice":"feminine","question":null,"events":[{"type":"silence"}]}
    """.utf8)
    do { _ = try JSONDecoder().decode(SessionManifest.self, from: bad); fatalError("silence without duration accepted") } catch {}
}

print("SessionPacingTests passed")
