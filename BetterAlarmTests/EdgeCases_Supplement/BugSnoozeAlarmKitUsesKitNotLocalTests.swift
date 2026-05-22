// ============================================================
// BugSnoozeAlarmKitUsesKitNotLocalTests.swift
// BetterAlarmTests · EdgeCases_Supplement · BugRegression
//
// 현상: AlarmKit 알람을 앱에서 스누즈하면 로컬 UNNotification만 예약되어
//       삭제 후에도 배너 알림 + alarms.mp3로 울림.
// ============================================================

import XCTest
@testable import BetterAlarm

final class BugSnoozeAlarmKitUsesKitNotLocalTests: XCTestCase {

    private var store: AlarmStore!
    private var mockNotif: MockLocalNotificationService!
    private var mockAlarmKit: MockAlarmKitService!

    override func setUp() async throws {
        try await super.setUp()
        mockNotif = MockLocalNotificationService()
        mockAlarmKit = MockAlarmKitService()
        store = AlarmStore(
            localNotificationService: mockNotif,
            alarmKitService: mockAlarmKit
        )
        UserDefaults.standard.removeObject(forKey: "savedAlarms_v2")
        AlarmIntentBridge.clearSnoozeBridge()
    }

    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: "savedAlarms_v2")
        AlarmIntentBridge.clearSnoozeBridge()
        store = nil
        mockNotif = nil
        mockAlarmKit = nil
        try await super.tearDown()
    }

    func test_snoozeAlarmKit_usesAlarmKit_notLocalScheduleSnooze() async {
        await store.createAlarm(
            hour: 7, minute: 0, title: "KitSnooze",
            schedule: .once, alarmMode: .alarmKit, isSilentAlarm: false
        )
        let alarm = await store.alarms[0]
        mockNotif.reset()
        mockAlarmKit.reset()

        await store.snoozeAlarm(alarm, minutes: AlarmDefaults.snoozeMinutes)

        XCTAssertEqual(mockAlarmKit.snoozeCallCount, 1)
        XCTAssertEqual(mockAlarmKit.snoozeCalledWithID.first, alarm.id.uuidString)
        XCTAssertTrue(mockNotif.scheduleSnoozeCalledWith.isEmpty,
                      "AlarmKit 스누즈는 scheduleSnooze(로컬)를 호출하면 안 된다")
        XCTAssertEqual(mockNotif.cancelAlarmCalledWith.count, 1)
    }
}
