import Foundation
import UserNotifications

/// Günlük hatırlatma — **cihazda** `UNCalendarNotificationTrigger` ile planlanır,
/// sunucudan gönderilmez (CLAUDE.md gizlilik kuralları).
///
/// - Metin path adını ya da derdi içermez: kilit ekranına bakan biri kullanıcının
///   neyle uğraştığını öğrenmemeli.
/// - `interruptionLevel` her zaman `.active`; `.timeSensitive`, `.critical` ve
///   `.provisional` izin kullanılmaz.
/// - Ses yok: beklenmedik bir "ding" tam olarak istemediğimiz tepkiyi üretir.
/// - İzin **bağlamında** istenir — kullanıcı hatırlatmayı açtığı anda, açılışta
///   değil (HIG 9.1).
enum ReminderScheduler {
    enum Outcome: Equatable, Sendable {
        case scheduled
        case cancelled
        /// İzin yok. Hatırlatma kapalı kaydedilir; ekran ayarlara yol gösterir.
        case denied
    }

    static let identifier = "patika.daily-step"

    static func apply(_ reminder: ReminderSetting) async -> Outcome {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard reminder.isEnabled else { return .cancelled }
        guard await isAuthorized(center) else { return .denied }

        let content = UNMutableNotificationContent()
        content.body = String(localized: Copy.Notification.dailyStep)
        content.interruptionLevel = .active

        var components = DateComponents()
        components.hour = reminder.hour
        components.minute = reminder.minute

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        )
        do {
            try await center.add(request)
            return .scheduled
        } catch {
            return .denied
        }
    }

    static func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    private static func isAuthorized(_ center: UNUserNotificationCenter) async -> Bool {
        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert])) ?? false
        case .denied, .provisional:
            return false
        @unknown default:
            return false
        }
    }
}
