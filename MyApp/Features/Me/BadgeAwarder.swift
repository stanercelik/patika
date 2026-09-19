import Foundation

/// Rozet kazanımını kaydeder — "Ben" sayfası ve oturum sonu aynı yolu kullanır.
///
/// `BadgeCatalog.earned` saf hesaptır; bu tip onu cihazdaki ve sunucudaki kayıtla
/// birleştirir. Rozet geri alınmaz: hesaplanan küme küçülse bile bilinen rozetler
/// kalır.
///
/// Sunucuya yazma **ateşle-unut**: yazılamayan rozet bir sonraki hesaplamada
/// yeniden denenir (koşul hâlâ sağlanıyor ve sunucuda yok), kullanıcı bir hata
/// görmez. Yerel kayıt her zaman önce güncellenir — rozet ekranda görünmek için
/// ağı beklemez.
@MainActor
struct BadgeAwarder {
    let services: AppServices

    /// Yeni kazanılan rozetleri kayda işler ve döndürür (katalog sırasıyla).
    /// Kriz modunda hiçbir şey kazandırılmaz ve gösterilmez: kayıt akışı zaten
    /// durmuş olur, rozet o anda yanlış bir dil olurdu.
    @discardableResult
    func award(activePath: ActivePath?, now: Date = .now) -> [BadgeID] {
        guard let record = services.profile.record, record.crisisSignalAt == nil else { return [] }

        let computed = BadgeCatalog.earned(from: record, path: activePath)
        let fresh = BadgeCatalog.newlyEarned(computed: computed, known: record.earnedBadges)
        guard !fresh.isEmpty else { return [] }

        services.profile.recordEarnedBadges(fresh.map { EarnedBadge(badgeID: $0, earnedAt: now) })
        // Ağı beklemeden: çevrimdışı bir kullanıcı adım sonunda zaman aşımını
        // beklemesin. Yazılamayan rozet `syncUnsynced` ile bir sonraki sayfa
        // yüklemesinde yeniden gönderilir (yerel kayıtta var, sunucuda yok).
        Task { await upload(fresh) }
        return fresh
    }

    /// Cihazda kayıtlı ama sunucunun `me-profile` cevabında olmayan rozetleri
    /// yeniden yazar. Yerel kayıt rozeti bir kez tuttuktan sonra `award` onu yeni
    /// saymaz; bu olmadan başarısız bir yükleme hiçbir zaman tekrarlanmazdı.
    func syncUnsynced(serverBadges: [ProfileSnapshot.Badge]) {
        let serverIDs = Set(serverBadges.compactMap { BadgeID(rawValue: $0.id) })
        let pending = (services.profile.record?.earnedBadges ?? [])
            .map(\.badgeID)
            .filter { !serverIDs.contains($0) }
        guard !pending.isEmpty else { return }
        Task { await upload(pending) }
    }

    private func upload(_ badges: [BadgeID]) async {
        guard let session = services.auth.session,
              let token = try? await services.auth.validAccessToken()
        else { return }
        do {
            try await services.backend.recordBadges(badges, userID: session.userID, accessToken: token)
        } catch {
            services.observability.capture(.profileSync)
        }
    }
}
