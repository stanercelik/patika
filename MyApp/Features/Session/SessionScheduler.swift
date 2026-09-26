import AVFoundation
import Foundation

/// Çizelgeyi bir `AVAudioPlayerNode`'a **sıralı** kuran, oturumdan bağımsız parça.
///
/// `AVAudioSession` ve `MediaPlayer`a bağlı değil: bu yüzden çevrimdışı işleme
/// kipindeki bir `AVAudioEngine` ile örnek doğrulukla test edilebiliyor
/// (`Tests/SessionSchedulerTests`). Oynatıcının en riskli kısmı burası ve tempo
/// duyulur; simülatörde ses yakalanamadığı için dalga formu üstünden doğrulanıyor.
struct SessionScheduler {
    let voice: AVAudioPlayerNode

    /// Çizelgeyi `start` anından itibaren, **sıralı** kurar.
    ///
    /// `start` bir konuşmanın **ortasına** düşerse o parça baştan değil kaldığı
    /// yerden çalar: yarısı dinlenmiş bir cümleyi baştan duymak kullanıcıya
    /// kesintiyi ikinci kez hatırlatıyordu. Orada 600 ms'lik şişme arıza gibi
    /// duyulurdu; yalnızca tıklama önleyici uygulanır (`declickOnSeek`).
    func schedule(
        timeline: SessionTimeline,
        files: [UUID: AVAudioFile],
        format: AVAudioFormat,
        from start: TimeInterval
    ) {
        for entry in timeline.entries where entry.end > start {
            switch entry.event {
            case .speech(let speech):
                // Bağlantı boşluğu: konuşmanın özelliği, ayrı bir olay değil.
                let leadRemaining = entry.contentStart - max(entry.start, start)
                if leadRemaining > 0 { scheduleSilence(seconds: leadRemaining, format: format) }

                guard let file = files[speech.assetID] else {
                    // Dosyası indirilemeyen parça saati bozmasın: yerini sessizlik tutar.
                    scheduleSilence(seconds: entry.end - max(entry.contentStart, start), format: format)
                    continue
                }
                let skippedSeconds = max(0, start - entry.contentStart)
                let skipped = AVAudioFramePosition((skippedSeconds * format.sampleRate).rounded())
                scheduleSpeech(
                    file,
                    from: skipped,
                    fadeIn: skipped > 0 ? SessionPacing.declickOnSeek : entry.fadeIn,
                    fadeOut: entry.fadeOut,
                    format: format
                )
            case .gap, .silence:
                scheduleSilence(seconds: entry.end - max(entry.start, start), format: format)
            }
        }
    }

    /// Bir konuşmayı üç parçada sıralar: giriş tamponu (fade-in uygulanmış), dosyadan
    /// doğrudan çalan orta segment, çıkış tamponu (fade-out uygulanmış).
    private func scheduleSpeech(
        _ file: AVAudioFile,
        from skipped: AVAudioFramePosition,
        fadeIn: TimeInterval,
        fadeOut: TimeInterval,
        format: AVAudioFormat
    ) {
        let remaining = file.length - skipped
        guard remaining > 0 else { return }
        let rate = format.sampleRate

        // Kısa dosyada iki fade birbirine binmesin: her biri en çok yarısını alır.
        let headFrames = min(AVAudioFramePosition((fadeIn * rate).rounded()), remaining / 2)
        let tailFrames = min(AVAudioFramePosition((fadeOut * rate).rounded()), remaining - headFrames)

        // Uç tamponlar **ayrı bir okuyucudan** okunur: oynatıcı düğümü `file`ı kendi
        // iş parçacığında tüketirken aynı nesnenin konumunu oynatmak yarışırdı.
        let head = headFrames > 0 ? rampBuffer(file, at: skipped, frames: headFrames, fadingIn: true) : nil
        let tail = tailFrames > 0 ? rampBuffer(file, at: file.length - tailFrames, frames: tailFrames, fadingIn: false) : nil
        // Tampon okunamazsa uç fade'siz dosyadan çalar; oturum susmaz.
        let headHandled = headFrames == 0 || head != nil
        let tailHandled = tailFrames == 0 || tail != nil
        let segmentStart = headHandled ? skipped + headFrames : skipped
        let segmentEnd = tailHandled ? file.length - tailFrames : file.length
        if let head, headHandled { voice.scheduleBuffer(head, at: nil, options: [], completionHandler: nil) }
        if segmentEnd > segmentStart {
            voice.scheduleSegment(
                file,
                startingFrame: segmentStart,
                frameCount: AVAudioFrameCount(segmentEnd - segmentStart),
                at: nil,
                completionCallbackType: .dataConsumed
            ) { _ in }
        }
        if let tail, tailHandled { voice.scheduleBuffer(tail, at: nil, options: [], completionHandler: nil) }
    }

    /// Gerçek sessizlik: node biçiminde sıfır örnekler. Sessizlik TTS'e hiç gitmiyor
    /// (marjın tamamı buna bağlı); ayrıca RMS tap'in duraklamada gerçek sıfır
    /// okumasını sağlıyor, yani `audioEnergy` 450 ms'lik release ile sönümleniyor.
    ///
    /// Bir saniyelik tek tampon `floor(saniye)` kez sıralanır, artık ayrı tampon.
    private func scheduleSilence(seconds: TimeInterval, format: AVAudioFormat) {
        guard seconds > 0 else { return }
        let rate = format.sampleRate
        let totalFrames = AVAudioFramePosition((seconds * rate).rounded())
        guard totalFrames > 0 else { return }
        let second = AVAudioFramePosition(rate)
        if totalFrames >= second, let whole = silentBuffer(format: format, frames: AVAudioFrameCount(second)) {
            for _ in 0..<Int(totalFrames / second) {
                voice.scheduleBuffer(whole, at: nil, options: [], completionHandler: nil)
            }
        }
        let remainder = totalFrames % second
        if remainder > 0, let tail = silentBuffer(format: format, frames: AVAudioFrameCount(remainder)) {
            voice.scheduleBuffer(tail, at: nil, options: [], completionHandler: nil)
        }
    }

    private func silentBuffer(format: AVAudioFormat, frames: AVAudioFrameCount) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let channels = buffer.floatChannelData
        else { return nil }
        buffer.frameLength = frames
        for channel in 0..<Int(format.channelCount) {
            channels[channel].update(repeating: 0, count: Int(frames))
        }
        return buffer
    }

    /// Dosyanın bir aralığını okuyup eşit güçlü fade uygular (doğrusal değil:
    /// doğrusal eğri ortada sesi çukurlaştırıyordu).
    private func rampBuffer(
        _ file: AVAudioFile,
        at position: AVAudioFramePosition,
        frames: AVAudioFramePosition,
        fadingIn: Bool
    ) -> AVAudioPCMBuffer? {
        guard frames > 0,
              let reader = try? AVAudioFile(forReading: file.url, commonFormat: .pcmFormatFloat32, interleaved: false),
              let buffer = AVAudioPCMBuffer(pcmFormat: reader.processingFormat, frameCapacity: AVAudioFrameCount(frames))
        else { return nil }
        reader.framePosition = position
        guard (try? reader.read(into: buffer, frameCount: AVAudioFrameCount(frames))) != nil,
              buffer.frameLength > 0,
              let channels = buffer.floatChannelData
        else { return nil }
        let count = Int(buffer.frameLength)
        let last = Float(max(1, count - 1))
        for channel in 0..<Int(buffer.format.channelCount) {
            for index in 0..<count {
                let position = Float(index) / last
                let gain = fadingIn ? sin(position * .pi / 2) : cos(position * .pi / 2)
                channels[channel][index] *= gain
            }
        }
        return buffer
    }
}
