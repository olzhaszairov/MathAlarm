import AppIntents
import Foundation

// MARK: - AlarmIntentBridge

enum AlarmIntentBridge {
    /// AlarmKit 스케줄 시 연결된 앱 알람 ID (스누즈 재등록 시 Open 버튼용).
    static let activeAppAlarmIDKey = "activeAlarmKitAppAlarmID"
    /// OpenAlarmIntent → 앱 복귀 시 울림 화면 표시용.
    static let pendingOpenAlarmKey = "pendingOpenAlarmFromIntent"
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
