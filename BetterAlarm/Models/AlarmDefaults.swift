import Foundation

// MARK: - AlarmDefaults

enum AlarmDefaults {
    static let snoozeMinutes = 1
    static let defaultAlarmMode: AlarmMode = .alarmKit
    /// Полный звук в приложении: Resources/alarms.mp3
    static let defaultSoundName = "alarms"
    /// Экран блокировки / уведомления (≤30 с): Resources/alarms_lock.caf
    static let lockScreenSoundName = "alarms_lock"
}
