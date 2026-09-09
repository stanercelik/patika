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
    let events: [SessionEvent]

    init(
        version: Int,
        stepID: UUID,
        pathKind: ProgramPathKind,
        locale: String,
        voice: SessionVoice,
        question: String?,
        events: [SessionEvent]
    ) {
        self.version = version
        self.stepID = stepID
        self.pathKind = pathKind
        self.locale = locale
        self.voice = voice
        self.question = pathKind == .prepared ? nil : question
        self.events = events
    }

    private enum CodingKeys: String, CodingKey {
        case version, locale, voice, question, events
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
                durationMilliseconds: try container.decode(Int.self, forKey: .durationMilliseconds)
            ))
        case .gap:
            self = .gap(milliseconds: try container.decode(Int.self, forKey: .milliseconds))
        case .silence:
            self = .silence(SessionSilence(
                breaths: try container.decode(Int.self, forKey: .breaths),
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
        case .gap(let milliseconds):
            try container.encode(Kind.gap, forKey: .type)
            try container.encode(milliseconds, forKey: .milliseconds)
        case .silence(let silence):
            try container.encode(Kind.silence, forKey: .type)
            try container.encode(silence.breaths, forKey: .breaths)
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
    let durationMilliseconds: Int
}

struct SessionSilence: Equatable, Sendable {
    enum Landing: String, Codable, Sendable { case inhale, exhale }
    let breaths: Int
    let landOn: Landing?
    let displayText: String?
}

