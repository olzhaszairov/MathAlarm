import Foundation
import UIKit
import UserNotifications
#if canImport(ActivityKit)
import ActivityKit
#endif

// MARK: - SettingsPermissionAction

enum SettingsPermissionAction: Equatable {
    case none
    case request
    case openSettings
}

// MARK: - SettingsViewModel

/// 설정 화면의 상태를 관리하는 ViewModel.
/// Swift 6: @MainActor + @Observable. SwiftUI import 금지.
@MainActor
@Observable
final class SettingsViewModel {
    // MARK: - State

    private(set) var isLiveActivityEnabled: Bool = true

    private(set) var alarmKitAuthStatus: String = String(localized: "settings_permission_loading")
    private(set) var notificationAuthStatus: String = String(localized: "settings_permission_loading")
    private(set) var lockScreenWidgetStatus: String = String(localized: "settings_permission_loading")
    private(set) var notificationPermissionState: PermissionAuthState = .notDetermined
    private(set) var alarmKitPermissionState: PermissionAuthState = .unavailable
    private(set) var appVersion: String = ""
    private(set) var buildNumber: String = ""
    private(set) var isLoading: Bool = false

    // MARK: - Dependencies

    private let liveActivityManager: LiveActivityManager?
    private let alarmStore: AlarmStore
    private let localNotificationService: LocalNotificationService
    private let alarmKitService: (any AlarmKitServiceProtocol)?
    var themeManager: AppThemeManager?

    init(
        liveActivityManager: LiveActivityManager? = nil,
        alarmStore: AlarmStore,
        localNotificationService: LocalNotificationService,
        alarmKitService: (any AlarmKitServiceProtocol)? = nil,
        themeManager: AppThemeManager? = nil
    ) {
        self.liveActivityManager = liveActivityManager
        self.alarmStore = alarmStore
        self.localNotificationService = localNotificationService
        self.alarmKitService = alarmKitService
        self.themeManager = themeManager
        loadAppInfo()
    }

    var notificationPermissionAction: SettingsPermissionAction {
        action(for: notificationPermissionState)
    }

    var alarmKitPermissionAction: SettingsPermissionAction {
        action(for: alarmKitPermissionState)
    }

    // MARK: - Load

    func loadSettings() async {
        isLoading = true
        defer { isLoading = false }

        AppLogger.info("Loading settings", category: .settings)

        if #available(iOS 17.0, *), let manager = liveActivityManager {
            isLiveActivityEnabled = await manager.isLiveActivityEnabled
        }

        await refreshPermissions()
    }

    func setLiveActivityEnabled(_ enabled: Bool) async {
        AppLogger.info("Live Activity setting changed: \(enabled)", category: .settings)
        isLiveActivityEnabled = enabled
        await syncLiveActivitySetting(enabled)
    }

    // MARK: - Permission Actions

    func handleNotificationPermissionAction() async {
        switch notificationPermissionState {
        case .notDetermined:
            _ = await localNotificationService.requestPermission()
            await refreshPermissions()
            await alarmStore.scheduleNextAlarm(force: true)
        case .denied:
            openSystemSettings()
        case .authorized, .unavailable:
            break
        }
    }

    func handleAlarmKitPermissionAction() async {
        switch alarmKitPermissionState {
        case .notDetermined:
            guard let service = alarmKitService else { return }
            _ = await service.requestPermission()
            await refreshPermissions()
            await alarmStore.scheduleNextAlarm(force: true)
        case .denied:
            openSystemSettings()
        case .authorized, .unavailable:
            break
        }
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Refresh Permissions

    func refreshPermissions() async {
        notificationPermissionState = await localNotificationService.permissionState()
        notificationAuthStatus = statusText(for: notificationPermissionState)

        await loadAlarmKitAuthStatus()

        if #available(iOS 17.0, *) {
            let info = ActivityAuthorizationInfo()
            lockScreenWidgetStatus = info.areActivitiesEnabled
                ? String(localized: "settings_permission_authorized")
                : String(localized: "settings_permission_denied")
        } else {
            lockScreenWidgetStatus = String(localized: "settings_requires_ios17")
        }
    }

    // MARK: - Private

    private func action(for state: PermissionAuthState) -> SettingsPermissionAction {
        switch state {
        case .notDetermined:
            return .request
        case .denied:
            return .openSettings
        case .authorized, .unavailable:
            return .none
        }
    }

    private func statusText(for state: PermissionAuthState) -> String {
        switch state {
        case .authorized:
            return String(localized: "settings_permission_authorized")
        case .denied:
            return String(localized: "settings_permission_denied")
        case .notDetermined:
            return String(localized: "settings_permission_not_determined")
        case .unavailable:
            return String(localized: "settings_permission_unknown")
        }
    }

    private func syncLiveActivitySetting(_ enabled: Bool) async {
        if #available(iOS 17.0, *), let manager = liveActivityManager {
            await manager.setLiveActivityEnabled(enabled)
            if enabled {
                await alarmStore.syncLiveActivity()
            } else {
                await manager.endActivity()
            }
        }
    }

    private func loadAlarmKitAuthStatus() async {
        guard let service = alarmKitService else {
            alarmKitPermissionState = .unavailable
            alarmKitAuthStatus = String(localized: "settings_requires_ios26")
            return
        }

        alarmKitPermissionState = await service.permissionState()
        alarmKitAuthStatus = statusText(for: alarmKitPermissionState)
    }

    private func loadAppInfo() {
        appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
