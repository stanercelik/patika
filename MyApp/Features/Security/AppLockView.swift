import SwiftUI

/// Uygulama kilitliyken bütün sekmelerin üstünde durur. SOS bu katmanın da
/// üstünde (`RootView`): kilit bir duvar ve destek hiçbir duvarın arkasında değil.
struct AppLockView: View {
    let controller: AppLockController

    var body: some View {
        ZStack {
            // Düz nötr zemin: kategori rengi ya da görseli bile kişinin neyle
            // uğraştığına dair bir ipucu sayılır.
            WoodlandStyle.background.ignoresSafeArea()

            VStack(spacing: 14) {
                Spacer()
                Image(systemName: AppLockController.symbolName)
                    .font(.largeTitle.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textPrimary.color)
                    .accessibilityHidden(true)
                Text(Copy.AppLock.title)
                    .font(.title2.weight(Theme.Weight.title))
                    .foregroundStyle(Theme.textPrimary.color)
                Text(Copy.AppLock.body)
                    .font(.body.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textSecondary.color)
                    .multilineTextAlignment(.center)
                Spacer()
                PrimaryButton(title: Copy.AppLock.unlock, isEnabled: !controller.isAuthenticating) {
                    Task { await controller.unlock() }
                }
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
            .padding(.bottom, 32)
        }
        .task { await controller.unlock() }
    }
}

/// Uygulama arka plana geçerken içeriği örter (profile-design İ7).
///
/// Uygulama değiştiricideki anlık görüntüde path adı ya da kullanıcının cümlesi
/// görünmemeli: "Zihni akşam yavaşlatma" bile kişinin neyle uğraştığını söyler.
struct PrivacyShieldView: View {
    var body: some View {
        WoodlandStyle.background
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}
