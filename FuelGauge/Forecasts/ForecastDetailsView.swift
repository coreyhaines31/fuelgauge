import FuelGaugeCore
import SwiftUI

struct ForecastDetailsView: View {
    let model: UsageModel
    @State private var selected = ""

    init(model: UsageModel, selectedKey: String = "") {
        self.model = model
        _selected = State(initialValue: selectedKey)
    }

    private var forecast: Forecast? {
        model.forecasts.first(where: { $0.key.id == selected }) ?? model.forecasts.first
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if let warning = model.forecastHistory.warning {
                        Label(warning, systemImage: "exclamationmark.triangle").font(.callout)
                    }
                    if let forecast {
                        picker
                        current(forecast, now: context.date)
                        ForecastLearningView(forecast: forecast)
                        ForecastAccuracyView(results: model.forecastHistory.accuracy[forecast.key]
                            ?? [1, 6, 24].map { ForecastAccuracy(hours: $0) })
                        recording(forecast)
                    } else {
                        ContentUnavailableView("Waiting for usage readings", systemImage: "clock",
                            description: Text("Use a tracked tool on this Mac. Forecast details appear automatically."))
                    }
                }
                .padding(28)
            }
        }
        .frame(minWidth: 660, minHeight: 540)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Forecast details").font(.largeTitle.weight(.semibold))
                Text("This Mac · Learning and recording are automatic").foregroundStyle(.secondary)
            }
            Spacer()
            Button { model.refresh() } label: { Image(systemName: "arrow.clockwise") }
                .help("Refresh forecasts").accessibilityLabel("Refresh forecasts")
        }
    }

    private var picker: some View {
        Picker("Limit", selection: Binding(get: { forecast?.key.id ?? "" }, set: { selected = $0 })) {
            ForEach(model.forecasts, id: \.key) { forecast in
                Text("\(forecast.key.provider.name) · \(forecast.windowName)").tag(forecast.key.id)
            }
        }
        .frame(maxWidth: 320)
    }

    private func current(_ forecast: Forecast, now: Date) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Current forecast").font(.headline)
            Text(ForecastText.headline(forecast, now: now)).font(.title3.weight(.medium))
            LabeledContent("Method", value: method(forecast))
            LabeledContent("Latest reading") {
                Text(forecast.lastReadingAt.formatted(date: .abbreviated, time: .shortened))
                Text(age(forecast.lastReadingAt, now: now)).foregroundStyle(.secondary)
            }
            if let explanation = ForecastText.pace(forecast, now: now) {
                Text(explanation).font(.callout).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private func method(_ forecast: Forecast) -> String {
        switch forecast.verdict {
        case .stale: "Waiting for a reliable reading"
        case .learning: "Learning recent pace"
        case .reset: "Waiting for the new window"
        case .limitReached: "Observed limit reached"
        case .makesIt, .runsOut: forecast.basis == .schedule ? "Learned hours + recent activity" : "Recent pace"
        }
    }

    private func age(_ date: Date, now: Date) -> String {
        let elapsed = max(0, now.timeIntervalSince(date))
        return elapsed < 60 ? "just now" : "\(ForecastText.duration(elapsed)) ago"
    }

    private func recording(_ forecast: Forecast) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            if let first = model.forecastHistory.firstRecordedAt[forecast.key] {
                Text("Local history since \(first.formatted(date: .abbreviated, time: .shortened))")
            } else {
                Text("Recording starts with the next eligible forecast.")
            }
            Text("One prediction per hour while Fuel Gauge runs. Up to 60 days stay on this Mac. "
                 + "No prompts or responses are recorded.")
        }
        .font(.caption).foregroundStyle(.secondary)
    }
}
