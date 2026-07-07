import XCTest
@testable import BeuriDolei

@MainActor
final class ChallengeStoreTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "BeuriDoleiTests-\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testIncompleteSessionDoesNotIncrementStreakOrAdvanceCurrentDay() {
        let store = makeStore()
        let session = makeSession(
            dayIndex: 0,
            endedAt: Date(),
            seriesCompleted: [20, 20, 19],
            targetSeries: [20, 20, 20]
        )

        store.completeSession(session)

        XCTAssertFalse(session.isCompleted)
        XCTAssertEqual(store.streak, 0)
        XCTAssertEqual(store.currentDayIndex, 0)
        XCTAssertEqual(store.completionPercentage, 0)
    }

    func testCompletedSessionIncrementsStreakAndRecordsProgress() {
        let store = makeStore()
        let session = makeSession(
            dayIndex: 0,
            endedAt: Date(),
            seriesCompleted: [20, 20, 20],
            targetSeries: [20, 20, 20]
        )

        store.completeSession(session)

        XCTAssertTrue(session.isCompleted)
        XCTAssertEqual(store.streak, 1)
        XCTAssertEqual(store.currentDayIndex, 0)
        XCTAssertEqual(store.reminderDayIndex, 1)
        XCTAssertEqual(store.completionPercentage, 1.0 / Double(ChallengeDay.totalDays))
        XCTAssertEqual(store.totalTimeCompleted, 60)
    }

    func testCompletingSameDayTwiceDoesNotDoubleCountChallengeProgress() {
        let store = makeStore()

        store.completeSession(makeSession(dayIndex: 0, endedAt: Date()))
        store.completeSession(makeSession(dayIndex: 0, endedAt: Date()))

        XCTAssertEqual(store.streak, 1)
        XCTAssertEqual(store.currentDayIndex, 0)
        XCTAssertEqual(store.completionPercentage, 1.0 / Double(ChallengeDay.totalDays))
    }

    func testConsecutiveCompletedCalendarDaysRecalculateStreak() {
        let store = makeStore()
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        store.completeSession(makeSession(dayIndex: 0, endedAt: twoDaysAgo))
        store.completeSession(makeSession(dayIndex: 1, endedAt: yesterday))
        store.completeSession(makeSession(dayIndex: 2, endedAt: today))

        XCTAssertEqual(store.streak, 3)
        XCTAssertEqual(store.bestStreak, 3)
    }

    func testSessionsAndPreferencesPersistAcrossStoreInstances() {
        let firstStore = makeStore()
        firstStore.preferences.notificationsEnabled = false
        firstStore.preferences.hapticsEnabled = false
        firstStore.preferences.healthKitEnabled = false
        firstStore.savePreferences()
        firstStore.completeSession(makeSession(dayIndex: 0, endedAt: Date()))

        let reloadedStore = ChallengeStore(userDefaults: userDefaults)

        XCTAssertEqual(reloadedStore.sessions.count, 1)
        XCTAssertEqual(reloadedStore.streak, 1)
        XCTAssertFalse(reloadedStore.preferences.notificationsEnabled)
        XCTAssertFalse(reloadedStore.preferences.hapticsEnabled)
        XCTAssertFalse(reloadedStore.preferences.healthKitEnabled)
    }

    func testPersistedIncompleteSessionDoesNotAffectReloadedStreak() {
        let firstStore = makeStore()

        firstStore.completeSession(makeSession(
            dayIndex: 0,
            endedAt: Date(),
            seriesCompleted: [20, 20, 19],
            targetSeries: [20, 20, 20]
        ))

        let reloadedStore = ChallengeStore(userDefaults: userDefaults)

        XCTAssertEqual(reloadedStore.sessions.count, 1)
        XCTAssertEqual(reloadedStore.streak, 0)
        XCTAssertEqual(reloadedStore.currentDayIndex, 0)
        XCTAssertEqual(reloadedStore.completionPercentage, 0)
    }

    func testResetChallengeClearsPersistedHistory() {
        let firstStore = makeStore()
        firstStore.completeSession(makeSession(dayIndex: 0, endedAt: Date()))

        firstStore.resetChallenge()

        let reloadedStore = ChallengeStore(userDefaults: userDefaults)

        XCTAssertTrue(reloadedStore.sessions.isEmpty)
        XCTAssertEqual(reloadedStore.streak, 0)
        XCTAssertEqual(reloadedStore.currentDayIndex, 0)
        XCTAssertEqual(reloadedStore.completionPercentage, 0)
    }

    func testMissingYesterdayBreaksStreakWhenGraceDayIsDisabled() {
        let store = makeStore()
        store.preferences.graceDayEnabled = false
        store.savePreferences()
        let calendar = Calendar.current
        let today = Date()
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        store.completeSession(makeSession(dayIndex: 0, endedAt: twoDaysAgo))
        store.completeSession(makeSession(dayIndex: 1, endedAt: today))

        XCTAssertEqual(store.streak, 1)
        XCTAssertTrue(store.streakBroken(since: twoDaysAgo))
        XCTAssertEqual(store.bestStreak, 1)
    }

    func testSingleMissedDayCanUseGraceDayWithoutCountingAsCompleted() {
        let store = makeStore()
        store.preferences.graceDayEnabled = true
        store.savePreferences()
        let calendar = Calendar.current
        let today = Date()
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        store.completeSession(makeSession(dayIndex: 0, endedAt: twoDaysAgo))
        store.completeSession(makeSession(dayIndex: 1, endedAt: today))

        XCTAssertEqual(store.streak, 2)
        XCTAssertFalse(store.streakBroken(since: twoDaysAgo))
        XCTAssertEqual(store.completionPercentage, 2.0 / Double(ChallengeDay.totalDays))
    }

    func testChallengeProgrammeHasThirtyIndexedDaysWithValidSeries() {
        XCTAssertEqual(ChallengeDay.totalDays, 30)
        XCTAssertEqual(ChallengeDay.programme.count, 30)
        XCTAssertEqual(ChallengeDay.programme.map(\.dayIndex), Array(0..<30))

        for day in ChallengeDay.programme {
            XCTAssertEqual(day.seriesCount, 3)
            XCTAssertTrue(day.series.allSatisfy { $0 > 0 })
            XCTAssertGreaterThan(day.totalDuration, 0)
        }
    }

    func testChallengeProgrammeTotalDurationDoesNotDecrease() {
        let durations = ChallengeDay.programme.map(\.totalDuration)

        for index in 1..<durations.count {
            XCTAssertGreaterThanOrEqual(
                durations[index],
                durations[index - 1],
                "Day \(index) should not be shorter than the previous day"
            )
        }
    }

    func testCurrentDayMovesToFirstUncompletedDayAfterPastCompletion() {
        let store = makeStore()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        store.completeSession(makeSession(dayIndex: 0, endedAt: yesterday))

        XCTAssertFalse(store.isTodayCompleted)
        XCTAssertEqual(store.currentDayIndex, 1)
        XCTAssertEqual(store.currentDay.dayIndex, 1)
        XCTAssertEqual(store.reminderDayIndex, 1)
    }

    func testChallengeDoneAfterThirtyUniqueCompletedDays() {
        let store = makeStore()
        let calendar = Calendar.current
        let today = Date()

        for dayIndex in 0..<ChallengeDay.totalDays {
            let endedAt = calendar.date(
                byAdding: .day,
                value: dayIndex - (ChallengeDay.totalDays - 1),
                to: today
            )!
            store.completeSession(makeSession(dayIndex: dayIndex, endedAt: endedAt))
        }

        XCTAssertTrue(store.isChallengeDone)
        XCTAssertEqual(store.currentDayIndex, ChallengeDay.totalDays - 1)
        XCTAssertNil(store.nextDay)
        XCTAssertEqual(store.completionPercentage, 1)
    }

    func testValidateDayMarksDayCompletedAndUpdatesStreak() {
        let store = makeStore()

        store.validateDay(0)

        XCTAssertTrue(store.isTodayCompleted)
        XCTAssertEqual(store.streak, 1)
        XCTAssertEqual(store.completionPercentage, 1.0 / Double(ChallengeDay.totalDays))
    }

    func testValidateDayIsNoOpWhenDayAlreadyCompleted() {
        let store = makeStore()
        store.validateDay(0)

        store.validateDay(0)

        XCTAssertEqual(store.sessions.filter { $0.dayIndex == 0 }.count, 1)
    }

    func testValidateDayIgnoresOutOfRangeIndex() {
        let store = makeStore()

        store.validateDay(ChallengeDay.totalDays)

        XCTAssertTrue(store.sessions.isEmpty)
    }

    func testInvalidateDayRemovesSessionAndRecalculatesStreak() {
        let store = makeStore()
        store.completeSession(makeSession(dayIndex: 0, endedAt: Date()))
        XCTAssertEqual(store.streak, 1)

        store.invalidateDay(0)

        XCTAssertFalse(store.isTodayCompleted)
        XCTAssertEqual(store.streak, 0)
        XCTAssertEqual(store.completionPercentage, 0)
    }

    func testInvalidateDayIsNoOpWhenDayNotCompleted() {
        let store = makeStore()

        store.invalidateDay(0)

        XCTAssertTrue(store.sessions.isEmpty)
    }

    func testProgressCellStateResolverPrioritizesCompletedDays() {
        let state = DayCellStateResolver.state(
            for: 2,
            currentDayIndex: 2,
            completedDayIndexes: [2]
        )

        XCTAssertEqual(state, .completed)
    }

    func testProgressCellStateResolverDistinguishesCurrentSkippedAndFutureDays() {
        let completed: Set<Int> = [0, 1]

        XCTAssertEqual(
            DayCellStateResolver.state(
                for: 2,
                currentDayIndex: 3,
                completedDayIndexes: completed
            ),
            .skipped
        )
        XCTAssertEqual(
            DayCellStateResolver.state(
                for: 3,
                currentDayIndex: 3,
                completedDayIndexes: completed
            ),
            .current
        )
        XCTAssertEqual(
            DayCellStateResolver.state(
                for: 4,
                currentDayIndex: 3,
                completedDayIndexes: completed
            ),
            .future
        )
    }

    func testTimerSessionStateStartPauseAndResume() {
        var state = TimerSessionState(targetSeries: [2, 2])

        XCTAssertTrue(state.shouldStartNewSession)

        state.start()
        XCTAssertTrue(state.isRunning)
        XCTAssertFalse(state.isPaused)

        state.pause()
        XCTAssertFalse(state.isRunning)
        XCTAssertTrue(state.isPaused)

        state.resume()
        XCTAssertTrue(state.isRunning)
        XCTAssertFalse(state.isPaused)
    }

    func testTimerSessionStateAdvancesAfterCompletedSerie() {
        var state = TimerSessionState(targetSeries: [2, 3])
        state.start()

        XCTAssertEqual(state.tick(), .inProgress)
        XCTAssertEqual(state.tick(), .serieCompleted)

        XCTAssertFalse(state.isRunning)
        XCTAssertEqual(state.currentSerieIndex, 1)
        XCTAssertEqual(state.elapsed, 0)
        XCTAssertEqual(state.seriesCompleted, [2])
        XCTAssertFalse(state.isComplete)
        XCTAssertEqual(state.completedSeriesForSession(), [2, 0])
    }

    func testTimerSessionStateCompletesLastSerie() {
        var state = TimerSessionState(targetSeries: [1, 1])
        state.start()
        XCTAssertEqual(state.tick(), .serieCompleted)
        state.start()
        XCTAssertEqual(state.tick(), .serieCompleted)

        XCTAssertTrue(state.isComplete)
        XCTAssertFalse(state.isRunning)
        XCTAssertFalse(state.isPaused)
        XCTAssertEqual(state.currentSerieIndex, 1)
        XCTAssertEqual(state.seriesCompleted, [1, 1])
        XCTAssertEqual(state.completedSeriesForSession(), [1, 1])
    }

    func testTimerSessionStateAbandonStopsWithoutMarkingComplete() {
        var state = TimerSessionState(targetSeries: [2, 2])
        state.start()
        _ = state.tick()

        state.abandon()

        XCTAssertTrue(state.isAbandoned)
        XCTAssertFalse(state.isRunning)
        XCTAssertFalse(state.isPaused)
        XCTAssertFalse(state.isComplete)
        XCTAssertEqual(state.completedSeriesForSession(), [0, 0])
    }

    func testApplyNotificationPreferencesSchedulesDailyReminderWhenEnabled() {
        let scheduler = FakeNotificationScheduler()
        let store = makeStore(notificationScheduler: scheduler)
        let reminderTime = makeTime(hour: 7, minute: 30)
        store.preferences.notificationsEnabled = true
        store.preferences.reminderTime = reminderTime

        store.applyNotificationPreferences()

        XCTAssertEqual(scheduler.dailyReminders.count, 1)
        XCTAssertEqual(scheduler.dailyReminders.last?.dayIndex, 0)
        XCTAssertEqual(scheduler.dailyReminders.last?.time, reminderTime)
        XCTAssertEqual(scheduler.cancelDailyReminderCallCount, 0)
    }

    func testApplyNotificationPreferencesCancelsDailyReminderWhenDisabled() {
        let scheduler = FakeNotificationScheduler()
        let store = makeStore(notificationScheduler: scheduler)
        store.preferences.notificationsEnabled = false

        store.applyNotificationPreferences()

        XCTAssertTrue(scheduler.dailyReminders.isEmpty)
        XCTAssertEqual(scheduler.cancelDailyReminderCallCount, 1)
    }

    func testUpdatedReminderTimeSchedulesLatestTime() {
        let scheduler = FakeNotificationScheduler()
        let store = makeStore(notificationScheduler: scheduler)
        store.preferences.notificationsEnabled = true

        store.preferences.reminderTime = makeTime(hour: 7, minute: 0)
        store.applyNotificationPreferences()
        store.preferences.reminderTime = makeTime(hour: 21, minute: 15)
        store.applyNotificationPreferences()

        XCTAssertEqual(scheduler.dailyReminders.count, 2)
        XCTAssertEqual(scheduler.dailyReminders.last?.time, makeTime(hour: 21, minute: 15))
    }

    func testCompletedSessionSchedulesCongratsAndNextDailyReminder() {
        let scheduler = FakeNotificationScheduler()
        let store = makeStore(notificationScheduler: scheduler)
        store.preferences.notificationsEnabled = true
        store.preferences.reminderTime = makeTime(hour: 8, minute: 45)

        store.completeSession(makeSession(dayIndex: 0, endedAt: Date()))

        XCTAssertEqual(scheduler.congratsNotifications.count, 1)
        XCTAssertEqual(scheduler.congratsNotifications.last?.dayIndex, 0)
        XCTAssertEqual(scheduler.congratsNotifications.last?.streak, 1)
        XCTAssertEqual(scheduler.dailyReminders.count, 1)
        XCTAssertEqual(scheduler.dailyReminders.last?.dayIndex, 1)
        XCTAssertEqual(scheduler.dailyReminders.last?.time, makeTime(hour: 8, minute: 45))
    }

    private func makeStore(
        notificationScheduler: any NotificationScheduling = FakeNotificationScheduler()
    ) -> ChallengeStore {
        let store = ChallengeStore(
            userDefaults: userDefaults,
            notificationScheduler: notificationScheduler
        )
        store.preferences.notificationsEnabled = false
        store.preferences.healthKitEnabled = false
        store.savePreferences()
        return store
    }

    private func makeTime(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)!
    }

    private func makeSession(
        dayIndex: Int,
        endedAt: Date,
        seriesCompleted: [Int] = [20, 20, 20],
        targetSeries: [Int] = [20, 20, 20]
    ) -> PlankSession {
        PlankSession(
            id: UUID(),
            dayIndex: dayIndex,
            variant: .classic,
            startedAt: endedAt.addingTimeInterval(-TimeInterval(seriesCompleted.reduce(0, +))),
            endedAt: endedAt,
            seriesCompleted: seriesCompleted,
            targetSeries: targetSeries
        )
    }
}

private final class FakeNotificationScheduler: NotificationScheduling {
    private(set) var permissionRequests = 0
    private(set) var dailyReminders: [(time: Date, dayIndex: Int)] = []
    private(set) var cancelDailyReminderCallCount = 0
    private(set) var congratsNotifications: [(dayIndex: Int, streak: Int)] = []

    func requestPermission(completion: ((Bool) -> Void)?) {
        permissionRequests += 1
        completion?(true)
    }

    func scheduleDailyReminder(at time: Date, dayIndex: Int) {
        dailyReminders.append((time: time, dayIndex: dayIndex))
    }

    func cancelDailyReminder() {
        cancelDailyReminderCallCount += 1
    }

    func scheduleCongratsNotification(dayIndex: Int, streak: Int) {
        congratsNotifications.append((dayIndex: dayIndex, streak: streak))
    }
}
