import Charts
import FuelGaugeCore
import SwiftUI

struct UsageView: View {
    let model: UsageModel
    @State private var period: UsagePeriod = .week
    @State private var provider = "all"
    @State private var chartMetric = "Tokens"

    private var now: Date { model.usageUpdatedAt ?? Date() }
    private var interval: DateInterval { period.interval(now: now) }
    private var selectedProvider: Provider? { provider == "all" ? nil : Provider(rawValue: provider) }
    private var events: [UsageEvent] {
        UsageHistory.select(model.visibleUsage, interval: interval, provider: selectedProvider)
    }
    private var summary: UsageSummary { UsageSummary(events) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                controls
                if let updated = model.usageUpdatedAt {
                    Text("Updated \(updated.formatted(date: .omitted, time: .shortened)) · Times are local")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if model.scanningUsage {
                    HStack { ProgressView().controlSize(.small); Text("Reading local usage history…") }
                }
                ForEach(model.usageWarnings, id: \.self) { warning in
                    Label(warning, systemImage: "exclamationmark.triangle").font(.callout)
                }
                if events.isEmpty {
                    ContentUnavailableView("No recorded usage", systemImage: "chart.bar",
                                           description: Text("Use Claude Code or Codex on this Mac. "
                                            + "Usage appears independently of your reset forecasts."))
                } else {
                    metrics
                    chart
                    tokenBreakdown
                    UsageBreakdownView(events: events)
                }
                pricingNote
            }
            .padding(28)
        }
        .frame(minWidth: 720, minHeight: 540)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Usage").font(.largeTitle.weight(.semibold))
                Text("This Mac · Claude Code & Codex").foregroundStyle(.secondary)
            }
            Spacer()
            Button { model.refresh() } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                .disabled(model.scanningUsage)
        }
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Picker("Period", selection: $period) {
                ForEach(UsagePeriod.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented).frame(width: 260)
            Spacer()
            Picker("Tool", selection: $provider) {
                Text("All tools").tag("all")
                Text("Claude Code").tag(Provider.claude.rawValue)
                Text("Codex").tag(Provider.codex.rawValue)
            }
            .frame(width: 220)
        }
    }

    private var metrics: some View {
        HStack(spacing: 12) {
            metric("Tokens", value: summary.tokens.total.formatted(.number.notation(.compactName)), detail: comparison)
            metric("Estimated API cost", value: summary.costLabel, detail: "USD · Standard rates")
            metric("Cache hit rate",
                   value: summary.tokens.cacheHitRate?.formatted(.percent.precision(.fractionLength(0)))
                   ?? "—", detail: "Share of input read from cache")
            metric("Sessions", value: summary.sessions.formatted(), detail: "With recorded usage")
        }
    }

    private func metric(_ title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title2.weight(.semibold)).monospacedDigit().textSelection(.enabled)
            Text(detail).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
    }

    private var comparison: String {
        let previous = UsageSummary(UsageHistory.select(model.visibleUsage,
            interval: period.previousInterval(now: now), provider: selectedProvider))
        guard previous.tokens.total > 0 else { return "No prior-period usage recorded" }
        let change = Double(summary.tokens.total) / Double(previous.tokens.total) - 1
        let percent = abs(change).formatted(.percent.precision(.fractionLength(0)))
        return "\(percent) \(change >= 0 ? "more" : "less") vs. prior period to this time"
    }

    private var chart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily usage").font(.headline)
                Spacer()
                Picker("Measure", selection: $chartMetric) {
                    Text("Tokens").tag("Tokens")
                    Text("Cost (USD)").tag("Cost")
                }.pickerStyle(.segmented).labelsHidden().frame(width: 200)
            }
            Chart(days, id: \.date) { day in
                BarMark(x: .value("Day", day.date, unit: .day),
                        y: .value(chartMetric, chartMetric == "Tokens"
                                  ? Double(day.summary.tokens.total) : day.summary.estimatedCost))
                .foregroundStyle(Color.accentColor.gradient)
            }
            .chartXAxis { AxisMarks(values: .stride(by: .day, count: period == .month ? 5 : 1)) }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(amount.formatted(.number.notation(.compactName)))
                        }
                    }
                }
            }
            .frame(height: 160)
            if chartMetric == "Cost" && summary.unpricedEvents > 0 {
                Text("Cost chart includes priced usage only. Some models have no verified rate.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var days: [(date: Date, summary: UsageSummary)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: events) { calendar.startOfDay(for: $0.at) }
        return (0..<period.rawValue).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: interval.start) else { return nil }
            return (date, UsageSummary(grouped[date] ?? []))
        }
    }

    private var tokenBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Token breakdown").font(.headline)
            HStack(spacing: 24) {
                token("Input", summary.tokens.input)
                token("Output", summary.tokens.output)
                token("Cache read", summary.tokens.cacheRead)
                token("Cache write", summary.tokens.cacheWrite)
            }
            Text("Input excludes cache reads and writes. Reasoning, where recorded, is included in output "
                 + "(\(summary.tokens.reasoning.formatted()) reasoning tokens).")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func token(_ name: String, _ count: Int64) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name).font(.caption).foregroundStyle(.secondary)
            Text(count.formatted()).font(.body.monospacedDigit()).textSelection(.enabled)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pricingNote: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("About these numbers").font(.headline)
            Text("Local logs only; remote work and other devices may be missing. API cost estimates use standard "
                 + "short-context rates, not your subscription bill. Tier, long-context, regional and tool fees "
                 + "are excluded. Unknown models stay unpriced; cache writes without a duration use the short rate.")
            HStack {
                Text("Rates checked October 30, 2026.")
                Link("OpenAI", destination: URL(string: "https://developers.openai.com/api/docs/pricing")!)
                Link("Anthropic", destination: URL(string: "https://platform.claude.com/docs/en/about-claude/pricing")!)
            }
        }.font(.caption).foregroundStyle(.secondary)
    }
}
