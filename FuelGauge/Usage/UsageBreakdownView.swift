import FuelGaugeCore
import SwiftUI

struct UsageBreakdownView: View {
    let events: [UsageEvent]
    @State private var grouping = "Model"

    private struct Row: Identifiable {
        let id: String
        let title: String
        let detail: String
        let summary: UsageSummary
    }

    private var rows: [Row] {
        Dictionary(grouping: events) { event in
            switch grouping {
            case "Tool": event.provider.name
            case "Project": event.project
            case "Session": "\(event.provider.name)/\(event.session)"
            default: event.model
            }
        }.map { key, events in
            let title = grouping == "Project" && key != "Unknown project" ? URL(filePath: key).lastPathComponent : key
            return Row(id: key, title: title, detail: key, summary: UsageSummary(events))
        }.sorted { $0.summary.tokens.total == $1.summary.tokens.total
            ? $0.id < $1.id : $0.summary.tokens.total > $1.summary.tokens.total }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Breakdown").font(.headline)
                Spacer()
                Picker("Group by", selection: $grouping) {
                    ForEach(["Tool", "Model", "Project", "Session"], id: \.self) { Text($0).tag($0) }
                }.pickerStyle(.segmented).labelsHidden().frame(width: 320)
            }
            HStack {
                Text(grouping)
                Spacer()
                Text("Tokens").frame(width: 110, alignment: .trailing)
                Text("Est. API cost").frame(width: 160, alignment: .trailing)
            }.font(.caption).foregroundStyle(.secondary)
            ForEach(rows) { row in
                Divider()
                HStack(alignment: .firstTextBaseline) {
                    Text(row.title).lineLimit(1).truncationMode(.middle).help(row.detail)
                    Spacer(minLength: 16)
                    Text(row.summary.tokens.total.formatted()).monospacedDigit()
                        .frame(width: 110, alignment: .trailing)
                    Text(row.summary.costLabel).monospacedDigit().frame(width: 160, alignment: .trailing)
                }.textSelection(.enabled)
            }
        }
    }
}
