import SwiftUI
import PersonalColorDesignSystem

// MARK: - SettingsView

/// 설정 화면. 커스텀 헤더 + Form 기반 UI.
struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @State private var liveActivityToggle: Bool = true
    @Environment(\.pThemeColors) private var theme

    init(
        liveActivityManager: LiveActivityManager?,
        alarmStore: AlarmStore,
        localNotificationService: LocalNotificationService,
        alarmKitService: (any AlarmKitServiceProtocol)? = nil,
        themeManager: AppThemeManager? = nil
    ) {
        _viewModel = State(initialValue: SettingsViewModel(
            liveActivityManager: liveActivityManager,
            alarmStore: alarmStore,
            localNotificationService: localNotificationService,
            alarmKitService: alarmKitService,
            themeManager: themeManager
        ))
    }

    var body: some View {
        ZStack {
            PGradientBackground()

            VStack(spacing: 0) {
                // 고정 헤더
                HStack {
                    Text("settings_title")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color.pTextPrimary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Form {
                    // MARK: 알림 권한 섹션
                    Section {
                        permissionRow(
                            titleKey: "settings_notification_permission",
                            status: viewModel.notificationAuthStatus,
                            isAuthorized: viewModel.notificationPermissionState == .authorized,
                            action: viewModel.notificationPermissionAction
                        ) {
                            await viewModel.handleNotificationPermissionAction()
                        }
                        .accessibilityLabel(Text("settings_notification_permission_a11y_format \(viewModel.notificationAuthStatus)"))

                        permissionRow(
                            titleKey: "settings_alarmkit_permission",
                            status: viewModel.alarmKitAuthStatus,
                            isAuthorized: viewModel.alarmKitPermissionState == .authorized,
                            action: viewModel.alarmKitPermissionAction
                        ) {
                            await viewModel.handleAlarmKitPermissionAction()
                        }
                        .accessibilityLabel(Text("settings_alarmkit_permission_a11y_format \(viewModel.alarmKitAuthStatus)"))
                    } header: {
                        Text("settings_section_permission")
                            .font(.caption)
                            .foregroundStyle(Color.pTextTertiary)
                    }
                    .listRowBackground(Color.pGlassFill)

                    // MARK: 잠금화면 위젯 섹션 (토글 + 권한 통합)
                    Section {
                        PToggle(String(localized: "settings_lock_widget_label"), isOn: $liveActivityToggle, icon: "lock.iphone")
                            .accessibilityLabel(Text("settings_lock_widget_label"))
                            .accessibilityHint(Text("settings_lock_widget_a11y_hint"))
                            .frame(minHeight: 44)
                            .onChange(of: liveActivityToggle) { _, newValue in
                                Task {
                                    await viewModel.setLiveActivityEnabled(newValue)
                                }
                            }

                        // 잠금화면 위젯 권한 행 — VStack 분리 (영어 라벨 잘림 방지, SPEC §7.2D)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("settings_lock_widget_permission")
                                .font(.body)
                                .foregroundStyle(Color.pTextPrimary)
                            HStack {
                                Text(viewModel.lockScreenWidgetStatus)
                                    .font(.caption)
                                    .foregroundStyle(viewModel.lockScreenWidgetStatus == String(localized: "settings_permission_authorized") ? Color.pSuccess : Color.pTextSecondary)
                                Spacer()
                                if viewModel.lockScreenWidgetStatus != String(localized: "settings_requires_ios17") {
                                    Button("settings_open_app_settings") {
                                        viewModel.openSystemSettings()
                                    }
                                    .font(.caption)
                                    .foregroundStyle(theme.accentPrimary)
                                }
                            }
                        }
                        .frame(minHeight: 44)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(Text("settings_lock_widget_permission_a11y_format \(viewModel.lockScreenWidgetStatus)"))
                    } header: {
                        Text("settings_section_lock_widget")
                            .font(.caption)
                            .foregroundStyle(Color.pTextTertiary)
                    }
                    .listRowBackground(Color.pGlassFill)

                    // MARK: 피드백/문의 섹션
                    Section {
                        let subject = String(localized: "settings_feedback_email_subject")
                            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "BetterAlarm%20Feedback"
                        Link(destination: URL(string: "mailto:olzhaszairov@gmail.com?subject=\(subject)")!) {
                            HStack {
                                Text("settings_feedback_button")
                                    .font(.body)
                                    .foregroundStyle(Color.pTextPrimary)
                                Spacer()
                                Image(systemName: "envelope")
                                    .foregroundStyle(theme.accentPrimary)
                            }
                        }
                        .frame(minHeight: 44)
                        .accessibilityLabel(Text("settings_feedback_button"))
                        .accessibilityHint(Text("settings_feedback_a11y_hint"))
                    } header: {
                        Text("settings_section_feedback")
                            .font(.caption)
                            .foregroundStyle(Color.pTextTertiary)
                    }
                    .listRowBackground(Color.pGlassFill)

                    // MARK: 앱 정보 섹션
                    Section {
                        HStack {
                            Text("settings_version_label")
                                .font(.body)
                                .foregroundStyle(Color.pTextPrimary)
                            Spacer()
                            Text("\(viewModel.appVersion) (\(viewModel.buildNumber))")
                                .font(.body)
                                .foregroundStyle(Color.pTextSecondary)
                        }
                        .frame(minHeight: 44)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(Text("settings_version_a11y_format \(viewModel.appVersion) \(viewModel.buildNumber)"))
                    } header: {
                        Text("settings_section_app_info")
                            .font(.caption)
                            .foregroundStyle(Color.pTextTertiary)
                    }
                    .listRowBackground(Color.pGlassFill)
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
        }
        // toolbarBackground 제거: SwiftUI 기본 탭바 렌더링에 위임
        .task {
            await viewModel.loadSettings()
            liveActivityToggle = viewModel.isLiveActivityEnabled
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task { await viewModel.refreshPermissions() }
        }
        .pLoadingOverlay(
            isLoading: Binding(get: { viewModel.isLoading }, set: { _ in }),
            message: String(localized: "settings_loading_message")
        )
    }

    @ViewBuilder
    private func permissionRow(
        titleKey: LocalizedStringKey,
        status: String,
        isAuthorized: Bool,
        action: SettingsPermissionAction,
        onAction: @escaping () async -> Void
    ) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text(titleKey)
                .font(.body)
                .foregroundStyle(Color.pTextPrimary)
            Spacer(minLength: 8)
            Text(status)
                .font(.body)
                .foregroundStyle(isAuthorized ? Color.pSuccess : Color.pWarning)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            if action != .none {
                Button(action == .request ? "settings_permission_allow_button" : "settings_open_app_settings") {
                    Task { await onAction() }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.accentPrimary)
            }
        }
        .frame(minHeight: 44)
    }
}
