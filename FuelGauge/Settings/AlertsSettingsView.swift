import SwiftUI

struct AlertsSettingsView: View {
    @AppStorage(Preferences.alertWhenShortKey) private var alertWhenShort = true
    @State private var thresholds = Set(Preferences.alertThresholds)

    var body: some View {
        Form {
            Section {
                Toggle("When a limit will run out before it resets", isOn: $alertWhenShort)
            } footer: {
                Text("Once per window, when the forecast says you'll run out at least 30 minutes early. "
                    + "Time to switch to a cheaper model or save the big job for after the reset.")
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
