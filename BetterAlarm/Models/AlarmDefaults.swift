import Foundation

// MARK: - AlarmDefaults

enum AlarmDefaults {
    static let snoozeMinutes = 1
    static let defaultAlarmMode: AlarmMode = .alarmKit
    /// Полный звук в приложении: Resources/alarms.mp3
    static let defaultSoundName = "alarms"
    /// Экран блокировки / уведомления (≤30 с): Resources/alarms_lock.caf
    /// AlarmKit: `AlertSound.named` требует имя с расширением, иначе системный звук.
    static let lockScreenSoundFileName = "alarms_lock.caf"

    static func lockScreenSoundURLInBundle() -> URL? {
        Bundle.main.url(
            forResource: (lockScreenSoundFileName as NSString).deletingPathExtension,
            withExtension: (lockScreenSoundFileName as NSString).pathExtension
        )
    }
}
