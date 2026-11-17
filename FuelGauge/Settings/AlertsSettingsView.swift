import SwiftUI

struct AlertsSettingsView: View {
    @AppStorage(Preferences.alertWhenShortKey) private var alertWhenShort = true
    @State private var thresholds = Set(Preferences.alertThresholds)

    var body: some View {
        Form {
            Section {
                Toggle("When a limit will run out before it resets", isOn: $alertWhenShort)
            } footer: {
                Text("Once per window, after two fresh readings confirm you'll run out at least 30 minutes early. "
                    + "Both readings must be from the last 15 minutes.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section {
                ForEach([50, 80, 95], id: \.self) { threshold in
                    Toggle("At \(threshold)% used", isOn: Binding(
                        get: { thresholds.contains(threshold) },
                        set: { on in
                            if on { thresholds.insert(threshold) } else { thresholds.remove(threshold) }
                            UserDefaults.standard.set(thresholds.sorted(), forKey: Preferences.alertThresholdsKey)
                        }
                    ))
                }
            } header: {
                Text("Also alert")
            }
        }
        .formStyle(.grouped)
        .frame(height: 300)
    }
}
