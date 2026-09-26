import Foundation

enum ProgramPathKind: String, Codable, Sendable {
    case personalized
    case prepared
}

enum SessionVoice: String, Codable, Sendable {
    case feminine
    case masculine
}

struct SessionManifest: Codable, Equatable, Sendable {
    let version: Int
    let stepID: UUID
    let pathKind: ProgramPathKind
    let locale: String
    let voice: SessionVoice
    let question: String?
    /// Varsayılan nefes periyodu (ms). Yoksa `SessionPacing.defaultBreathMilliseconds`.
    let breathMilliseconds: Int?
    let events: [SessionEvent]

    /// Sessizliklerin ve nefes sayımının çözüldüğü periyot.
    var resolvedBreathMilliseconds: Int {
        breathMilliseconds ?? SessionPacing.defaultBreathMilliseconds
    }

    init(
        version: Int,
        stepID: UUID,
        pathKind: ProgramPathKind,
        locale: String,
        voice: SessionVoice,
        question: String?,
        breathMilliseconds: Int? = nil,
        events: [SessionEvent]
    ) {
        self.version = version
        self.stepID = stepID
        self.pathKind = pathKind
        self.locale = locale
        self.voice = voice
        self.question = pathKind == .prepared ? nil : question
        self.breathMilliseconds = breathMilliseconds
        self.events = events
    }

    private enum CodingKeys: String, CodingKey {
        case version, locale, voice, question, events
        case breathMilliseconds = "breathMs"
        case stepID = "stepId"
        case pathKind
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        guard version == 1 else {
            throw DecodingError.dataCorruptedError(forKey: .version, in: container, debugDescription: "Unsupported session manifest version")
        }
        stepID = try container.decode(UUID.self, forKey: .stepID)
        pathKind = try container.decode(ProgramPathKind.self, forKey: .pathKind)
        locale = try container.decode(String.self, forKey: .locale)
        voice = try container.decode(SessionVoice.self, forKey: .voice)
        question = try container.decodeIfPresent(String.self, forKey: .question)
        breathMilliseconds = try container.decodeIfPresent(Int.self, forKey: .breathMilliseconds)
        events = try container.decode([SessionEvent].self, forKey: .events)
        if pathKind == .prepared, question != nil {
            throw DecodingError.dataCorruptedError(forKey: .question, in: container, debugDescription: "Prepared paths do not ask adaptive questions")
        }
    }
}

enum SessionEvent: Codable, Equatable, Sendable {
    case speech(SessionSpeech)
    case gap(milliseconds: Int)
    case silence(SessionSilence)

    private enum CodingKeys: String, CodingKey {
        case type, source, assetID = "assetId", storagePath, text
        case durationMilliseconds = "durationMs"
        case milliseconds, breaths, landOn, displayText
        case leadInMilliseconds = "leadInMs"
        case silenceMilliseconds = "ms"
        case breathMilliseconds = "breathMs"
    }

    private enum Kind: String, Codable { case speech, gap, silence }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .type) {
        case .speech:
            self = .speech(SessionSpeech(
                source: try container.decode(SessionSpeech.Source.self, forKey: .source),
                assetID: try container.decode(UUID.self, forKey: .assetID),
                storagePath: try container.decode(String.self, forKey: .storagePath),
                text: try container.decode(String.self, forKey: .text),
                durationMilliseconds: try container.decode(Int.self, forKey: .durationMilliseconds),
                leadInMilliseconds: try container.decodeIfPresent(Int.self, forKey: .leadInMilliseconds) ?? 0
            ))
        case .gap:
            self = .gap(milliseconds: try container.decode(Int.self, forKey: .milliseconds))
        case .silence:
            // `ms` yetkili (v2); yalnızca `breaths` taşıyan eski manifestler de okunur.
            let milliseconds = try container.decodeIfPresent(Int.self, forKey: .silenceMilliseconds)
            let breaths = try container.decodeIfPresent(Int.self, forKey: .breaths)
            guard milliseconds != nil || breaths != nil else {
                throw DecodingError.dataCorruptedError(forKey: .silenceMilliseconds, in: container, debugDescription: "Silence needs ms or breaths")
            }
            self = .silence(SessionSilence(
                milliseconds: milliseconds,
                breaths: breaths,
                breathMilliseconds: try container.decodeIfPresent(Int.self, forKey: .breathMilliseconds),
                landOn: try container.decodeIfPresent(SessionSilence.Landing.self, forKey: .landOn),
                displayText: try container.decodeIfPresent(String.self, forKey: .displayText)
            ))
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .speech(let speech):
            try container.encode(Kind.speech, forKey: .type)
            try container.encode(speech.source, forKey: .source)
            try container.encode(speech.assetID, forKey: .assetID)
            try container.encode(speech.storagePath, forKey: .storagePath)
            try container.encode(speech.text, forKey: .text)
            try container.encode(speech.durationMilliseconds, forKey: .durationMilliseconds)
            if speech.leadInMilliseconds > 0 {
                try container.encode(speech.leadInMilliseconds, forKey: .leadInMilliseconds)
            }
        case .gap(let milliseconds):
            try container.encode(Kind.gap, forKey: .type)
            try container.encode(milliseconds, forKey: .milliseconds)
        case .silence(let silence):
            try container.encode(Kind.silence, forKey: .type)
            try container.encodeIfPresent(silence.milliseconds, forKey: .silenceMilliseconds)
            try container.encodeIfPresent(silence.breaths, forKey: .breaths)
            try container.encodeIfPresent(silence.breathMilliseconds, forKey: .breathMilliseconds)
            try container.encodeIfPresent(silence.landOn, forKey: .landOn)
            try container.encodeIfPresent(silence.displayText, forKey: .displayText)
        }
    }
}

struct SessionSpeech: Equatable, Sendable {
    enum Source: String, Codable, Sendable { case personal, block }
    let source: Source
    let assetID: UUID
    let storagePath: String
    let text: String
    /// Planlama değeri. Oynatıcı zamanlamayı yüklediği dosyanın **ölçtüğü**
    /// süreye göre yapar (`SessionTimeline.init(manifest:measured:)`).
    let durationMilliseconds: Int
    /// Bu konuşmadan önceki bağlantı boşluğu. Bir olay değil, konuşmanın özelliği:
    /// ekranda ayrı sahne üretmez.
    var leadInMilliseconds: Int = 0
}

struct SessionSilence: Equatable, Sendable {
    enum Landing: String, Codable, Sendable { case inhale, exhale }
    /// Yetkili süre (vuruş ya da pratik). Eski manifestlerde yok.
    var milliseconds: Int?
    /// `ms` yoksa nefes sayısı; varsa eski istemciler için ayna.
    var breaths: Int?
    /// Sessizliğin hizalandığı nefes periyodu. Yoksa manifestinki.
    var breathMilliseconds: Int?
    var landOn: Landing?
    var displayText: String?

    /// Süre, ms. `breaths` blok periyodunun katı; kutu nefesi 16 sn sayar.
    func duration(defaultBreathMilliseconds: Int) -> Int {
        if let milliseconds { return milliseconds }
        return (breaths ?? 1) * (breathMilliseconds ?? defaultBreathMilliseconds)
    }
}

