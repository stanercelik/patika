import AVFoundation
import Foundation

// Oynatıcının zamanlaması, çevrimdışı işlenen gerçek dalga formu üstünden.
//
//   swiftc -o /tmp/schedtest \
//     MyApp/Models/SessionManifest.swift MyApp/Features/Session/SessionTimeline.swift \
//     MyApp/Features/Session/SessionPacing.swift MyApp/Features/Session/SessionScheduler.swift \
//     Tests/SessionSchedulerTests/main.swift && /tmp/schedtest
//
// Simülatör ses yakalamadığı için tempo yalnızca burada ölçülebiliyor.

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError("FAILED: \(message)") }
}

setbuf(stdout, nil)
let rate = 44_100.0
let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: rate, channels: 1, interleaved: false)!
let toneLevel: Float = 0.5
/// Test düzeneğinin kazancı: `mainMixerNode` mono kaynağı ortaya panlarken -3 dB
/// (eşit güç) uyguluyor. Oynatıcıdan değil, çıkış karıştırıcısından geliyor.
let rigGain: Float = 0.70710678
let bodyLevel = toneLevel * rigGain

/// Sabit seviyeli ton dosyası: fade'ler ve boşluklar seviyeden okunur.
func makeTone(seconds: Double, name: String) -> AVAudioFile {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("sched-\(name).caf")
    try? FileManager.default.removeItem(at: url)
    let frames = AVAudioFrameCount(seconds * rate)
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
    buffer.frameLength = frames
    for index in 0..<Int(frames) { buffer.floatChannelData![0][index] = toneLevel }
    do {
        let writer = try AVAudioFile(forWriting: url, settings: format.settings, commonFormat: .pcmFormatFloat32, interleaved: false)
        try writer.write(from: buffer)
    } catch { fatalError("cannot write fixture: \(error)") }
    return try! AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false)
}

func id(_ n: Int) -> UUID { UUID(uuidString: String(format: "%08d-0000-0000-0000-000000000000", n))! }
func speech(_ n: Int, ms: Int, leadIn: Int = 0) -> SessionEvent {
    .speech(SessionSpeech(source: .block, assetID: id(n), storagePath: "x", text: "S\(n)", durationMilliseconds: ms, leadInMilliseconds: leadIn))
}

/// Çizelgeyi bir motorda çevrimdışı işler ve tüm örnekleri döndürür.
func render(_ timeline: SessionTimeline, files: [UUID: AVAudioFile], from start: TimeInterval) -> [Float] {
    let engine = AVAudioEngine()
    let voice = AVAudioPlayerNode()
    engine.attach(voice)
    engine.connect(voice, to: engine.mainMixerNode, format: format)
    try! engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 4_096)
    try! engine.start()
    SessionScheduler(voice: voice).schedule(timeline: timeline, files: files, format: format, from: start)
    voice.play()

    let wanted = Int(((timeline.duration - start) + 0.5) * rate)
    var output: [Float] = []
    output.reserveCapacity(wanted)
    let buffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: 4_096)!
    var stalls = 0
    while output.count < wanted {
        let chunk = min(4_096, wanted - output.count)
        let status = try! engine.renderOffline(AVAudioFrameCount(chunk), to: buffer)
        switch status {
        case .success:
            output.append(contentsOf: UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength)))
            stalls = 0
        case .insufficientDataFromInputNode, .cannotDoInCurrentContext:
            stalls += 1
            expect(stalls < 2_000, "render stalled")
            usleep(1_000)
        default:
            fatalError("render failed: \(status)")
        }
    }
    engine.stop()
    return output
}

func peak(_ samples: [Float], from: Double, to: Double) -> Float {
    let a = max(0, Int(from * rate)), b = min(samples.count, Int(to * rate))
    guard a < b else { return 0 }
    return samples[a..<b].map { abs($0) }.max() ?? 0
}
func level(_ samples: [Float], at time: Double) -> Float { abs(samples[min(samples.count - 1, Int(time * rate))]) }
func near(_ a: Float, _ b: Float, _ tolerance: Float = 0.03) -> Bool { abs(a - b) <= tolerance }

// --- Senaryo: A (1 s) | join 350 ms | B (1.5 s) | sessizlik 2 s | C (1 s)
let fileA = makeTone(seconds: 1.0, name: "a")
let fileB = makeTone(seconds: 1.5, name: "b")
let fileC = makeTone(seconds: 1.0, name: "c")
let manifest = SessionManifest(
    version: 1, stepID: id(999), pathKind: .prepared, locale: "en", voice: .feminine, question: nil,
    events: [
        speech(1, ms: 900),                              // beyan edilen süre yanlış: ölçüm ezer
        speech(2, ms: 1_500, leadIn: 350),
        .silence(.init(milliseconds: 2_000, breaths: 1)),
        speech(3, ms: 1_000),
    ]
)
let files: [UUID: AVAudioFile] = [id(1): fileA, id(2): fileB, id(3): fileC]
let measured = files.mapValues { TimeInterval($0.length) / $0.processingFormat.sampleRate }
let timeline = SessionTimeline(manifest: manifest, measured: measured)
expect(abs(timeline.duration - 5.85) < 0.001, "measured timeline is 5.85 s, got \(timeline.duration)")

let full = render(timeline, files: files, from: 0)
if CommandLine.arguments.contains("--dump") {
    for t in stride(from: 0.0, through: 6.0, by: 0.25) { print(String(format: "t=%.2f level=%.3f", t, level(full, at: t))) }
}

// A: orta bölüm seviyede, girişte kısa fade var.
expect(near(level(full, at: 0.5), bodyLevel), "A body at level")
expect(level(full, at: 0.001) < 0.1, "A eases in instead of a hard start")
// A -> B join: tam 350 ms sıfır, A'nın kuyruğu kesilmeden bitiyor (yalnızca declick).
expect(near(level(full, at: 0.98), bodyLevel, 0.1), "A tail is not swallowed by a fade (join only declicks)")
expect(peak(full, from: 1.005, to: 1.345) < 1e-5, "the join is exactly silent for its 350 ms")
expect(near(level(full, at: 1.5), bodyLevel), "B body at level")
// B'nin başı: declick 15 ms, sonra tam seviye. Bitişik cümle 250 ms şişmiyor.
expect(near(level(full, at: 1.35 + 0.05), bodyLevel), "B is at level 50 ms after its start (no long fade on a join)")
// B -> sessizlik: fade-out uçta, sonra 2 s tam sessizlik.
expect(level(full, at: 2.849) < 0.03, "B fades out before the silence")
expect(peak(full, from: 2.87, to: 4.83) < 1e-5, "the 2 s silence is exactly silent")
// C: uzun olmayan sessizlikten sonra kısa (250 ms) giriş.
expect(level(full, at: 4.86) < 0.1, "C eases in")
expect(near(level(full, at: 5.3), bodyLevel), "C body at level")
// Çakışma yok: hiçbir örnek iki dosyanın toplamına (2 x level) çıkmıyor.
expect(peak(full, from: 0, to: 5.85) <= bodyLevel + 0.01, "no two files ever overlap")
// Bitiş: son ses tam çizelgede bitiyor, sonrası sıfır.
expect(peak(full, from: 5.86, to: 6.3) < 1e-5, "nothing plays after the timeline ends")
expect(peak(full, from: 5.80, to: 5.85) > 0.01, "the last file plays right up to the end")

// --- Seek: B'nin ortasına (1.6 s) in. Cümle kaldığı yerden çalar, 600 ms şişme yok.
let seeked = render(timeline, files: files, from: 1.6)
expect(seeked[0] < 0.1, "seek eases in over the short declick")
expect(near(level(seeked, at: 0.2), bodyLevel), "after the 120 ms declick the sentence is at level (no 600 ms swell)")
let silenceStart = 2.85 - 1.6
expect(peak(seeked, from: silenceStart + 0.02, to: silenceStart + 1.98) < 1e-5, "silence keeps its full length after a seek")
expect(near(level(seeked, at: silenceStart + 2.0 + 0.4), bodyLevel), "C still plays after the seek")
expect(peak(seeked, from: 4.26, to: 4.7) < 1e-5, "nothing plays after the end (seek)")

// --- Sessizliğin ortasına seek: kalan sessizlik kadar bekler, sonra C girer.
let midSilence = render(timeline, files: files, from: 3.85)
expect(peak(midSilence, from: 0.01, to: 0.98) < 1e-5, "seek into a silence keeps only the remainder")
expect(level(midSilence, at: 1.01) < 0.1, "speech after the remainder eases in")

// --- Join içine seek: kalan boşluk kadar sessizlik, sonra B baştan.
let inJoin = render(timeline, files: files, from: 1.2)
expect(peak(inJoin, from: 0.01, to: 0.14) < 1e-5, "seek into a join keeps the remaining lead-in")
expect(near(level(inJoin, at: 0.15 + 0.05), bodyLevel), "B starts from its beginning after the remaining lead-in")

print("SessionSchedulerTests passed")
