import Foundation
@testable import FuelGaugeCore
import Testing

@Suite struct AlertPlannerTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let planner = AlertPlanner(settings: .init(alertWhenShort: true, thresholds: [80, 95]))

    /// A Claude 5-hour forecast: `used` percent now, climbing `perHour`, resetting `resetsIn` hours from now.
    func forecast(used: Double, perHour: Double, resetsIn: Double = 3, resetOffset: TimeInterval = 0) -> Forecast {
        let resetsAt = now.addingTimeInterval(resetsIn * 3600 + resetOffset)
        let readings = [
            Reading(provider: .claude, limit: "five_hour", windowMinutes: 300, usedPercent: used - perHour,
                    resetsAt: resetsAt, at: now.addingTimeInterval(-3600)),
            Reading(provider: .claude, limit: "five_hour", windowMinutes: 300, usedPercent: used,
                    resetsAt: resetsAt, at: now)
        ]
        return ForecastEngine.forecast(for: readings, now: now)!
    }

    @Test func runOutNeedsTwoRefreshesInARow() {
        let short = forecast(used: 40, perHour: 30)
        let (first, state) = planner.plan([short], state: .init(), now: now)
        #expect(first.isEmpty)
        let (second, _) = planner.plan([short], state: state, now: now)
        #expect(second.map(\.id) == ["claude/five_hour|short"])
        #expect(second.first?.title.hasPrefix("Claude Code's 5-hour limit runs out around") == true)
    }

    @Test func oneBurstDoesNotAlert() {
        let (_, state) = planner.plan([forecast(used: 40, perHour: 30)], state: .init(), now: now)
        let (alerts, _) = planner.plan([forecast(used: 40, perHour: 5)], state: state, now: now)
        #expect(alerts.isEmpty)
    }

    @Test func firesOncePerWindowEvenWhenTheResetDrifts() {
        var state = AlertPlanner.State()
        var fired: [String] = []
        for offset: TimeInterval in [0, 0, 5 * 60, -4 * 60] {
            let short = forecast(used: 40, perHour: 30, resetOffset: offset)
            let (alerts, next) = planner.plan([short], state: state, now: now)
            fired += alerts.map(\.id)
            state = next
        }
        #expect(fired == ["claude/five_hour|short"])
    }

    @Test func aNewWindowCanAlertAgain() {
        let state = AlertPlanner.State(fired: ["claude/five_hour|short": now.timeIntervalSince1970 - 5 * 3600],
                                       shortLastTime: [LimitKey(provider: .claude, limit: "five_hour")])
        let (alerts, _) = planner.plan([forecast(used: 40, perHour: 30)], state: state, now: now)
        #expect(alerts.map(\.id) == ["claude/five_hour|short"])
    }

    @Test func thresholdsFireOnceAndOnlyTheHighestAtATime() {
        let (atEightyFive, state) = planner.plan([forecast(used: 85, perHour: 0)], state: .init(), now: now)
        #expect(atEightyFive.map(\.id) == ["claude/five_hour|80"])
        let (again, state2) = planner.plan([forecast(used: 86, perHour: 0)], state: state, now: now)
        #expect(again.isEmpty)
        let (atNinetySix, _) = planner.plan([forecast(used: 96, perHour: 0)], state: state2, now: now)
        #expect(atNinetySix.map(\.id) == ["claude/five_hour|95"])

        let (jump, _) = planner.plan([forecast(used: 97, perHour: 0)], state: .init(), now: now)
        #expect(jump.map(\.id) == ["claude/five_hour|95"])
    }

    @Test func respectsSettings() {
        let quiet = AlertPlanner(settings: .init(alertWhenShort: false, thresholds: []))
        let short = forecast(used: 90, perHour: 30)
        let (_, state) = quiet.plan([short], state: .init(), now: now)
        let (alerts, _) = quiet.plan([short], state: state, now: now)
        #expect(alerts.isEmpty)
    }

    @Test func runningOutJustBeforeTheResetIsNotWorthAnAlert() {
        // 40% at 20%/hr runs out in 3 h; the reset is 3 h 10 m away, inside the 30-minute margin.
        let close = forecast(used: 40, perHour: 20, resetsIn: 3 + 10.0 / 60)
        let (_, state) = planner.plan([close], state: .init(), now: now)
        let (alerts, _) = planner.plan([close], state: state, now: now)
        #expect(alerts.isEmpty)
    }
}
