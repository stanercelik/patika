import PhotosUI
import SwiftUI

/// Ayarlar ve gizlilik (`docs/profile-v2-plan.md` Aşama 6).
///
/// Profil "sen kimsin", ayarlar "uygulama nasıl davransın" — ikisi ayrı yüzey.
/// Koyu orman zemini ve adaçayı kart grupları; `List` yok. Bölüm sırası:
/// Hesap → Sana göre ayarlananlar → Gizlilik → Veri → Hakkında → Geri alınamaz,
/// en altta ortada soluk sürüm yazısı. Yıkıcı işlem saklanmaz, ayrı bir başlık
/// altında durur.
///
/// Adım uzunluğu, anlatım ve ses **salt okunur**: yol kurulurken seçildi ve
/// sunucuda bunları güncelleyen bir uç nokta yok. Değişiyormuş gibi davranan bir
/// düğme koymak yerine bunu söylüyoruz (`preferencesFootnote`).
struct SettingsSheet: View {
    let viewModel: MeViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var analyticsConsent: Bool
    @State private var confirmsJournalDeletion = false
    @State private var confirmsAccountDeletion = false
    @State private var isShowingSupport = false
    @State private var isShowingLinkSheet = false
    @State private var pickedPhoto: PhotosPickerItem?
    #if DEBUG
    @State private var isShowingDebugPage = false
    #endif

    init(viewModel: MeViewModel) {
        self.viewModel = viewModel
        _analyticsConsent = State(initialValue: viewModel.analyticsConsent)
    }

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

                        // Sürüm ayarların en altında, ortada ve soluk: profilden
                        // buraya taşındı.
                        Text(verbatim: viewModel.versionText)
                            .font(Theme.TypeFace.rowCaption)
                            .foregroundStyle(Theme.textSecondary.color.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
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
            .onChange(of: pickedPhoto) { _, item in
                guard let item else { return }
                Task {
                    defer { pickedPhoto = nil }
                    guard let data = try? await item.loadTransferable(type: Data.self) else {
                        viewModel.actionError = Copy.Me.photoFailed
                        return
                    }
                    await viewModel.setPhoto(data)
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
            .sheet(isPresented: $isShowingLinkSheet) {
                AccountLinkSheet(viewModel: viewModel)
            }
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
            PhotosPicker(selection: $pickedPhoto, matching: .images) {
                SettingsRow(title: Copy.Me.photoChoose, symbol: "photo", showsChevron: true)
            }
            .buttonStyle(.calm)

            if viewModel.services.avatar.hasImage {
                Button {
                    Task { await viewModel.removePhoto() }
                } label: {
                    SettingsRow(title: Copy.Me.photoRemove, symbol: "trash")
                }
                .buttonStyle(.calm)
                .disabled(viewModel.isWorking)
            }

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

            if viewModel.isAccountLinked {
                SettingsRow(title: Copy.Me.Settings.linkedRow, value: String(localized: Copy.Me.Settings.linkedYes))
            } else {
                Button { isShowingLinkSheet = true } label: {
                    SettingsRow(
                        title: Copy.Me.Settings.linkedRow,
                        value: String(localized: Copy.Me.Settings.linkedNo),
                        showsChevron: true
                    )
                }
                .buttonStyle(.calm)
            }
        }
    }

    /// Hatırlatma düzenlenebilir; uzunluk, anlatım ve ses salt okunur.
    private var preferencesGroup: some View {
        SettingsGroup(
            title: Copy.Me.preferencesTitle,
            footer: viewModel.preferenceItems.contains { !$0.isEditable } ? Copy.Me.preferencesFootnote : nil
        ) {
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
        case .tone: Copy.Me.toneLabel
        }
    }

    private var privacyGroup: some View {
        // İzin bilgilendirilmiş olmalı: altbilgi neyin paylaşılmadığını söyler.
        SettingsGroup(title: Copy.Me.Settings.privacyHeader, footer: Copy.Me.Settings.analyticsFooter) {
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

            SettingsToggleRow(title: Copy.Me.Settings.analytics, isOn: $analyticsConsent)
                .onChange(of: analyticsConsent) { _, consent in
                    viewModel.setAnalyticsConsent(consent)
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
