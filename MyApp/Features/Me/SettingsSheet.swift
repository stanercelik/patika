import SwiftUI

/// Ayarlar ve gizlilik.
///
/// Profil "sen kimsin", ayarlar "uygulama nasıl davransın" — ikisi ayrı yüzey.
/// Yıkıcı işlem saklanmaz, ayrı bir başlık altında durur.
struct SettingsSheet: View {
    let viewModel: MeViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(PaletteController.self) private var palette
    @State private var analyticsConsent: Bool
    @State private var confirmsJournalDeletion = false
    @State private var confirmsAccountDeletion = false

    init(viewModel: MeViewModel) {
        self.viewModel = viewModel
        _analyticsConsent = State(initialValue: viewModel.analyticsConsent)
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.record != nil {
                    Section {
                        NavigationLink {
                            ReminderEditor(viewModel: viewModel)
                        } label: {
                            LabeledContent {
                                Text(verbatim: viewModel.reminderSummary)
                            } label: {
                                Text(Copy.Me.reminderLabel)
                            }
                        }
                    } header: {
                        Text(Copy.Me.Settings.reminderHeader)
                    }
                }

                Section {
                    if viewModel.record != nil {
                        Toggle(isOn: Binding(
                            get: { viewModel.appLockEnabled },
                            set: { enabled in Task { await viewModel.setAppLock(enabled) } }
                        )) {
                            Text(Copy.Me.Settings.appLock)
                        }
                        .disabled(!AppLockController.isAvailable && !viewModel.appLockEnabled)

                        if viewModel.hasJournal {
                            Toggle(isOn: Binding(
                                get: { viewModel.hidesJournal },
                                set: { viewModel.setHidesJournal($0) }
                            )) {
                                Text(Copy.Me.Settings.hideJournal)
                            }
                        }
                    }

                    Toggle(isOn: $analyticsConsent) {
                        Text(Copy.Me.Settings.analytics)
                    }
                    .onChange(of: analyticsConsent) { _, consent in
                        viewModel.setAnalyticsConsent(consent)
                    }
                } header: {
                    Text(Copy.Me.Settings.privacyHeader)
                } footer: {
                    // İzin bilgilendirilmiş olmalı: neyin paylaşılmadığını söyler.
                    Text(Copy.Me.Settings.analyticsFooter)
                }

                if viewModel.record != nil {
                    Section {
                        if let export = viewModel.exportPayload {
                            ShareLink(
                                item: export,
                                preview: SharePreview(String(localized: Copy.Me.Settings.exportPreview))
                            ) {
                                Text(Copy.Me.Settings.export)
                            }
                        }
                        if viewModel.hasJournal {
                            Button(role: .destructive) {
                                confirmsJournalDeletion = true
                            } label: {
                                Text(Copy.Me.Settings.deleteJournal)
                            }
                            .disabled(viewModel.isWorking)
                        }
                    } header: {
                        Text(Copy.Me.Settings.dataHeader)
                    }

                    Section {
                        NavigationLink {
                            NameEditor(viewModel: viewModel)
                        } label: {
                            LabeledContent {
                                if let name = viewModel.displayName {
                                    Text(verbatim: name)
                                }
                            } label: {
                                Text(Copy.Me.Settings.nameRow)
                            }
                        }

                        LabeledContent {
                            Text(viewModel.isAccountLinked ? Copy.Me.Settings.linkedYes : Copy.Me.Settings.linkedNo)
                        } label: {
                            Text(Copy.Me.Settings.linkedRow)
                        }
                    } header: {
                        Text(Copy.Me.Settings.accountHeader)
                    }
                }

                Section {
                    NavigationLink {
                        MeasurementMethodView()
                    } label: {
                        Text(Copy.Me.howWeMeasure)
                    }
                    LabeledContent {
                        Text(verbatim: viewModel.versionText)
                    } label: {
                        Text(Copy.Me.Settings.versionRow)
                    }
                } header: {
                    Text(Copy.Me.Settings.aboutHeader)
                }

                Section {
                    Button(role: .destructive) {
                        confirmsAccountDeletion = true
                    } label: {
                        if viewModel.isWorking {
                            ProgressView()
                        } else {
                            Text(Copy.Me.Settings.deleteAccount)
                        }
                    }
                    .disabled(viewModel.isWorking)
                } header: {
                    Text(Copy.Me.Settings.irreversibleHeader)
                }
            }
            .navigationTitle(Text(Copy.Me.Settings.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) { dismiss() }
                }
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

    /// Silme tamamlanınca uygulama en başa döner: kayıt, oturum ve palet sıfır.
    private func deleteAccount() async {
        guard await viewModel.deleteAccount() else { return }
        dismiss()
        palette.select([])
        palette.setMood(nil)
        appState.hasCompletedOnboarding = false
    }
}

/// "Ben"deki hatırlatma satırından açılan yaprak.
struct ReminderSheet: View {
    let viewModel: MeViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ReminderEditor(viewModel: viewModel)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(role: .close) { dismiss() }
                    }
                }
        }
        .presentationDetents([.medium, .large])
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
                if isEnabled {
                    DatePicker(selection: $time, displayedComponents: .hourAndMinute) {
                        Text(Copy.Me.reminderTimeLabel)
                    }
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
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
                    Button {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            openURL(url)
                        }
                    } label: {
                        Text(Copy.Me.openSettings)
                    }
                }
            }
        }
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
            }
        }
        .navigationTitle(Text(Copy.Me.Settings.nameRow))
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
