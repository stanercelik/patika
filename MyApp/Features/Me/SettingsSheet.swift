import SwiftUI

/// Ayarlar ve gizlilik (`docs/profile-v2-plan.md` Aşama 6).
///
/// Profil "sen kimsin", ayarlar "uygulama nasıl davransın" — ikisi ayrı yüzey.
/// Koyu orman zemini ve adaçayı kart grupları; `List` yok. Bölüm sırası:
/// Hesap → Sana göre ayarlananlar → Gizlilik → Veri → Hakkında → Geri alınamaz,
/// en altta ortada soluk sürüm yazısı. Yıkıcı işlem saklanmaz, ayrı bir başlık
/// altında durur.
///
/// Kullanıcının sonradan değiştirebildiği tercih olarak yalnızca hatırlatma
/// görünür; path kurulurken kullanılan anlatım tercihi ayarlarda tekrarlanmaz.
struct SettingsSheet: View {
    let viewModel: MeViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var confirmsJournalDeletion = false
    @State private var confirmsAccountDeletion = false
    @State private var confirmsSignOut = false
    @State private var isShowingSupport = false
    #if DEBUG
    @State private var isShowingDebugPage = false
    #endif

    var body: some View {
        NavigationStack {
            ZStack {
                WoodlandStyle.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: PatikaSurfaceMetrics.sectionSpacing) {
                        if viewModel.record != nil { accountGroup }
                        if !viewModel.preferenceItems.isEmpty { preferencesGroup }
                        privacyGroup
                        if viewModel.record != nil { dataGroup }
                        aboutGroup
                        irreversibleGroup
                        #if DEBUG
                        debugGroup
                        #endif

                        // Sürüm bilgisi çıkış eyleminden önce, sakin bir meta satırı.
                        Text(verbatim: viewModel.versionText)
                            .font(Theme.TypeFace.rowCaption)
                            .foregroundStyle(Theme.textSecondary.color.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)

                        if viewModel.isAccountLinked {
                            Button { confirmsSignOut = true } label: {
                                SettingsRow(
                                    title: Copy.Me.Settings.signOut,
                                    symbol: "rectangle.portrait.and.arrow.right"
                                )
                            }
                            .buttonStyle(.calm)
                            .disabled(viewModel.isWorking)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.screenMargin)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(Text(Copy.Me.Settings.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) { dismiss() }
                }
            }
            #if DEBUG
            // `-patika-debug-settings-page reminder|name|method` — alt sayfa doğrudan açılır.
            .task { isShowingDebugPage = MeDebugSeed.settingsPage != nil }
            .navigationDestination(isPresented: $isShowingDebugPage) {
                switch MeDebugSeed.settingsPage {
                case "reminder": ReminderEditor(viewModel: viewModel)
                case "name": NameEditor(viewModel: viewModel)
                default: MeasurementMethodView()
                }
            }
            #endif
            .fullScreenCover(isPresented: $isShowingSupport) {
                SupportView()
            }
            .alert(Text(Copy.Me.Settings.deleteJournalTitle), isPresented: $confirmsJournalDeletion) {
                Button(role: .destructive) {
                    Task { await viewModel.deleteJournal() }
                } label: {
                    Text(Copy.Me.journalDelete)
                }
                Button(role: .cancel) {} label: { Text(Copy.Button.cancel) }
            } message: {
                Text(Copy.Me.Settings.deleteJournalBody)
            }
            .alert(Text(Copy.Me.Settings.deleteAccountTitle), isPresented: $confirmsAccountDeletion) {
                Button(role: .destructive) {
                    Task { await deleteAccount() }
                } label: {
                    Text(Copy.Me.journalDelete)
                }
                Button(role: .cancel) {} label: { Text(Copy.Button.cancel) }
            } message: {
                Text(Copy.Me.Settings.deleteAccountBody)
            }
            .alert(Text(Copy.Me.Settings.signOutTitle), isPresented: $confirmsSignOut) {
                Button(role: .destructive) {
                    Task { await signOut() }
                } label: {
                    Text(Copy.Me.Settings.signOut)
                }
                Button(role: .cancel) {} label: { Text(Copy.Button.cancel) }
            } message: {
                Text(Copy.Me.Settings.signOutBody)
            }
            .alert(
                Text(viewModel.actionError ?? ""),
                isPresented: Binding(
                    get: { viewModel.actionError != nil },
                    set: { if !$0 { viewModel.actionError = nil } }
                )
            ) {
                Button(role: .cancel) {} label: { Text(Copy.Button.understood) }
            }
        }
    }

    // MARK: Gruplar

    private var accountGroup: some View {
        SettingsGroup(title: Copy.Me.Settings.accountHeader) {
            NavigationLink {
                NameEditor(viewModel: viewModel)
            } label: {
                SettingsRow(
                    title: Copy.Me.Settings.nameRow,
                    value: viewModel.displayName ?? String(localized: Copy.Me.Settings.nameNone),
                    showsChevron: true
                )
            }
            .buttonStyle(.calm)

        }
    }

    /// Hatırlatma ayarlardaki tek kişiselleştirme satırıdır.
    private var preferencesGroup: some View {
        SettingsGroup(title: Copy.Me.preferencesTitle) {
            ForEach(viewModel.preferenceItems) { item in
                if item.isEditable {
                    NavigationLink {
                        ReminderEditor(viewModel: viewModel)
                    } label: {
                        SettingsRow(
                            title: Self.label(for: item.kind),
                            value: item.value,
                            caption: item.caption,
                            showsChevron: true
                        )
                    }
                    .buttonStyle(.calm)
                } else {
                    SettingsRow(title: Self.label(for: item.kind), value: item.value, caption: item.caption)
                }
            }
        }
    }

    private static func label(for kind: MeViewModel.PreferenceItem.Kind) -> LocalizedStringResource {
        switch kind {
        case .reminder: Copy.Me.reminderLabel
        }
    }

    private var privacyGroup: some View {
        SettingsGroup(title: Copy.Me.Settings.privacyHeader) {
            if viewModel.record != nil {
                SettingsToggleRow(
                    title: Copy.Me.Settings.appLock,
                    isOn: Binding(
                        get: { viewModel.appLockEnabled },
                        set: { enabled in Task { await viewModel.setAppLock(enabled) } }
                    ),
                    isEnabled: AppLockController.isAvailable || viewModel.appLockEnabled
                )

                if viewModel.hasJournal {
                    SettingsToggleRow(
                        title: Copy.Me.Settings.hideJournal,
                        isOn: Binding(
                            get: { viewModel.hidesJournal },
                            set: { viewModel.setHidesJournal($0) }
                        )
                    )
                }
            }
        }
    }

    private var dataGroup: some View {
        SettingsGroup(title: Copy.Me.Settings.dataHeader) {
            if let export = viewModel.exportPayload {
                ShareLink(
                    item: export,
                    preview: SharePreview(String(localized: Copy.Me.Settings.exportPreview))
                ) {
                    SettingsRow(title: Copy.Me.Settings.export, symbol: "square.and.arrow.up", showsChevron: true)
                }
                .buttonStyle(.calm)
            }
            if viewModel.hasJournal {
                Button { confirmsJournalDeletion = true } label: {
                    SettingsDestructiveRow(title: Copy.Me.Settings.deleteJournal)
                }
                .buttonStyle(.calm)
                .disabled(viewModel.isWorking)
            }
        }
    }

    /// "Destek al" burada da durur: hiçbir zaman ödeme duvarının ya da uygulama
    /// kilidinin arkasında değil.
    private var aboutGroup: some View {
        SettingsGroup(title: Copy.Me.Settings.aboutHeader) {
            NavigationLink {
                MeasurementMethodView()
            } label: {
                SettingsRow(title: Copy.Me.howWeMeasure, symbol: "chart.line.uptrend.xyaxis", showsChevron: true)
            }
            .buttonStyle(.calm)

            Button { isShowingSupport = true } label: {
                SettingsRow(title: Copy.Me.supportTitle, symbol: "hand.raised", showsChevron: true)
            }
            .buttonStyle(.calm)
        }
    }

    private var irreversibleGroup: some View {
        SettingsGroup(title: Copy.Me.Settings.irreversibleHeader) {
            Button { confirmsAccountDeletion = true } label: {
                SettingsDestructiveRow(title: Copy.Me.Settings.deleteAccount, isWorking: viewModel.isWorking)
            }
            .buttonStyle(.calm)
            .disabled(viewModel.isWorking)
        }
    }

    /// Silme tamamlanınca uygulama en başa döner: kayıt ve oturum sıfır.
    private func deleteAccount() async {
        guard await viewModel.deleteAccount() else { return }
        dismiss()
        appState.hasCompletedOnboarding = false
    }

    /// Çıkış da aynı şekilde en başa döner — hesap sunucuda kalır, yalnızca
    /// cihaz sıfırlanır (bkz. `MeViewModel.signOut`).
    private func signOut() async {
        await viewModel.signOut()
        dismiss()
        appState.hasCompletedOnboarding = false
    }

    #if DEBUG
    /// Yalnızca geliştirme: hesabı/veriyi silmeden onboarding'i tekrar izlemek
    /// için. `PatikaApp.body` `appState.hasCompletedOnboarding`i canlı okuyor,
    /// bu yüzden bayrağı çevirmek yeniden başlatmadan onboarding'e döner —
    /// sunucudaki path ve kayıt olduğu gibi kalır (bu bilerek `deleteAccount`
    /// çağırmıyor). Uygulama kapanıp açılırsa `adoptExistingPathIfAny` sunucuda
    /// zaten bir path bulup bayrağı hemen geri `true` yapar; bu yüzden akışı
    /// tek oturumda, uygulamayı arka plana atmadan izlemek gerekir.
    private var debugGroup: some View {
        SettingsGroup(title: "Debug") {
            Button {
                dismiss()
                appState.hasCompletedOnboarding = false
            } label: {
                SettingsRow(title: "Restart onboarding", symbol: "arrow.counterclockwise")
            }
            .buttonStyle(.calm)
        }
    }
    #endif
}

/// Hatırlatma saati ve anahtarı. İzin, kullanıcı anahtarı açıp kaydettiği anda
/// istenir — bağlamında (HIG 9.1).
struct ReminderEditor: View {
    let viewModel: MeViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var isEnabled: Bool
    @State private var time: Date
    @State private var outcome: ReminderScheduler.Outcome?
    @State private var isSaving = false

    init(viewModel: MeViewModel) {
        self.viewModel = viewModel
        let reminder = viewModel.record?.reminder
        _isEnabled = State(initialValue: reminder?.isEnabled ?? false)
        _time = State(initialValue: Calendar.current.date(
            bySettingHour: reminder?.hour ?? 22,
            minute: reminder?.minute ?? 30,
            second: 0,
            of: .now
        ) ?? .now)
    }

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $isEnabled) {
                    Text(Copy.Me.reminderToggle)
                }
                .settingsFormRow()
                if isEnabled {
                    DatePicker(selection: $time, displayedComponents: .hourAndMinute) {
                        Text(Copy.Me.reminderTimeLabel)
                    }
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .settingsFormRow()
                }
            } footer: {
                if let caption = viewModel.reminderSourceCaption {
                    Text(verbatim: caption)
                }
            }

            if outcome == .denied {
                Section {
                    Text(Copy.Me.reminderDenied)
                        .fixedSize(horizontal: false, vertical: true)
                        .settingsFormRow()
                    Button {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            openURL(url)
                        }
                    } label: {
                        Text(Copy.Me.openSettings)
                    }
                    .settingsFormRow()
                }
            }
        }
        .settingsFormStyle()
        .navigationTitle(Text(Copy.Me.reminderLabel))
        .navigationBarTitleDisplayMode(.inline)
        .animation(Theme.Motion.crossFade, value: isEnabled)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    save()
                } label: {
                    Text(Copy.Button.save)
                }
                .disabled(isSaving)
            }
        }
    }

    private func save() {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
        isSaving = true
        Task {
            let result = await viewModel.saveReminder(
                isEnabled: isEnabled,
                hour: parts.hour ?? 22,
                minute: parts.minute ?? 30
            )
            outcome = result
            isSaving = false
            if result == .denied {
                isEnabled = false
            } else {
                dismiss()
            }
        }
    }
}

/// "Sana nasıl hitap edelim". Ad isteğe bağlı; boş bırakmak akışın hiçbir yerini
/// kapatmaz. Sunucuya şifreli yazılır.
struct NameEditor: View {
    let viewModel: MeViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var name: String

    init(viewModel: MeViewModel) {
        self.viewModel = viewModel
        _name = State(initialValue: viewModel.displayName ?? "")
    }

    var body: some View {
        Form {
            Section {
                TextField(text: $name, prompt: Text(Copy.Me.Settings.namePlaceholder)) {
                    Text(Copy.Me.Settings.nameRow)
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .onSubmit(save)
                .settingsFormRow()
            }
        }
        .settingsFormStyle()
        // Kısa başlık: uzun etiket "Bende kalsın" düğmesinin yanında kırpılıyordu.
        .navigationTitle(Text(Copy.Me.Settings.nameTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if viewModel.isWorking {
                    ProgressView()
                } else {
                    Button(action: save) { Text(Copy.Button.save) }
                }
            }
        }
    }

    private func save() {
        Task {
            if await viewModel.saveName(name) { dismiss() }
        }
    }
}

extension View {
    /// Alt sayfaların `Form`u koyu orman zeminine geçer; sistem grisi ayarların
    /// geri kalanından kopuk duruyordu. Satırlar ayrıca `settingsFormRow()` alır:
    /// `listRowBackground` `Form`a verilince satırlara geçmiyor.
    func settingsFormStyle() -> some View {
        scrollContentBackground(.hidden)
            .background(WoodlandStyle.background.ignoresSafeArea())
            .tint(WoodlandStyle.sage)
    }

    /// `Form` satırı için adaçayı yüzey.
    func settingsFormRow() -> some View {
        listRowBackground(WoodlandStyle.surface)
    }
}
