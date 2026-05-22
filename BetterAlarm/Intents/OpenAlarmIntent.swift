import AppIntents
import Foundation

// MARK: - AlarmIntentBridge

enum AlarmIntentBridge {
    /// AlarmKit 스케줄 시 연결된 앱 알람 ID (스누즈 재등록 시 Open 버튼용).
    static let activeAppAlarmIDKey = "activeAlarmKitAppAlarmID"
    /// OpenAlarmIntent → 앱 복귀 시 울림 화면 표시용.
    static let pendingOpenAlarmKey = "pendingOpenAlarmFromIntent"
    /// SnoozeAlarmIntent / in-app snooze → AlarmKit에 등록된 1회성 스누즈 ID.
    static let pendingSnoozeAlarmKitIDKey = "pendingSnoozeAlarmKitID"

    static let snoozeFromIntentFlagKey = "alarmSnoozedFromIntent"
    static let snoozedAppAlarmIDKey = "alarmSnoozedAlarmID"
    static let snoozeDateTimestampKey = "alarmSnoozeDateTimestamp"

    static func recordSnoozeBridge(appAlarmID: String, snoozeDate: Date, alarmKitID: UUID) {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: snoozeFromIntentFlagKey)
        defaults.set(appAlarmID, forKey: snoozedAppAlarmIDKey)
        defaults.set(snoozeDate.timeIntervalSince1970, forKey: snoozeDateTimestampKey)
        defaults.set(alarmKitID.uuidString, forKey: pendingSnoozeAlarmKitIDKey)
    }

    static func clearSnoozeBridge() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: snoozeFromIntentFlagKey)
        defaults.removeObject(forKey: snoozedAppAlarmIDKey)
        defaults.removeObject(forKey: snoozeDateTimestampKey)
        defaults.removeObject(forKey: pendingSnoozeAlarmKitIDKey)
    }

    /// 삭제·비활성화 시 해당 앱 알람과 연결된 Intent/UserDefaults 흔적을 제거한다.
    static func clearReferences(toAppAlarmID alarmID: UUID) {
        let idString = alarmID.uuidString
        let defaults = UserDefaults.standard
        if defaults.string(forKey: activeAppAlarmIDKey) == idString {
            defaults.removeObject(forKey: activeAppAlarmIDKey)
        }
        if defaults.string(forKey: pendingOpenAlarmKey) == idString {
            defaults.removeObject(forKey: pendingOpenAlarmKey)
        }
        if defaults.string(forKey: snoozedAppAlarmIDKey) == idString {
            clearSnoozeBridge()
        }
    }
}

// MARK: - OpenAlarmIntent (iOS 26+)

/// 잠금화면 AlarmKit 정지 버튼 대신 앱을 열어 수학 문제로 정지하도록 한다.
@available(iOS 26.0, *)
struct OpenAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "intent_open_title"
    static var description = IntentDescription("intent_open_description")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "intent_alarmid_param")
    var appAlarmID: String

    init() {
        self.appAlarmID = ""
    }

    init(appAlarmID: String) {
        self.appAlarmID = appAlarmID
    }

    func perform() async throws -> some IntentResult {
        let resolvedID = appAlarmID.isEmpty
            ? (UserDefaults.standard.string(forKey: AlarmIntentBridge.activeAppAlarmIDKey) ?? "")
            : appAlarmID
        AppLogger.info("OpenAlarmIntent performed for appAlarmID=\(resolvedID)", category: .alarm)
        guard !resolvedID.isEmpty else { return .result() }

        UserDefaults.standard.set(resolvedID, forKey: AlarmIntentBridge.pendingOpenAlarmKey)
        UserDefaults.standard.synchronize()
        return .result()
    }
}
