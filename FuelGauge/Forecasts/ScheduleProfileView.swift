import FuelGaugeCore
import SwiftUI

struct ScheduleProfileView: View {
    let profile: ScheduleProfile
    let isApplied: Bool
    @State private var selectedID: String?

    init(profile: ScheduleProfile, isApplied: Bool, selectedID: String? = nil) {
        self.profile = profile
        self.isApplied = isApplied
        _selectedID = State(initialValue: selectedID)
    }

    private var maximumRate: Double { max(0.1, profile.hours.compactMap(\.ratePerHour).max() ?? 0) }
    private var selected: ScheduleProfile.Hour? { profile.hours.first { $0.id == selectedID } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Typical usage by hour").font(.callout.weight(.medium))
                Spacer()
                Text("Both rows use the same scale").font(.caption).foregroundStyle(.secondary)
            }
            ForEach(ScheduleProfile.Day.allCases, id: \.self) { day in
                VStack(alignment: .leading, spacing: 5) {
                    Text(day == .weekday ? "Weekdays" : "Weekends").font(.caption.weight(.medium))
                    HStack(spacing: 3) {
                        ForEach(profile.hours.filter { $0.day == day }) { hour in
                            hourButton(hour)
                        }
                    }
                }
            }
            HStack(spacing: 3) {
                ForEach(0..<24) { hour in
                    Text(hour.isMultiple(of: 3) ? ScheduleProfileText.time(hour) : "")
                        .font(.system(size: 9).monospacedDigit()).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            legend
            VStack(alignment: .leading, spacing: 4) {
                if let selected {
                    Text(ScheduleProfileText.title(selected)).font(.callout.weight(.medium))
                    Text(ScheduleProfileText.detail(selected)).font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("Select an hour to inspect its estimate and evidence.").font(.callout)
                    Text("Bar height shows percentage points used per hour, before recent-activity adjustments.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            Text("Times in \(profile.timeZoneIdentifier.replacingOccurrences(of: "_", with: " ")).")
                .font(.caption).foregroundStyle(.secondary)
            ScheduleActivityView(activity: profile.recentActivity, isApplied: isApplied)
        }
    }

    private func hourButton(_ hour: ScheduleProfile.Hour) -> some View {
        Button { selectedID = hour.id } label: {
            VStack(spacing: 0) {
                if let rate = hour.ratePerHour {
                    Spacer(minLength: 0)
                    if rate == 0 {
                        Text("–").font(.system(size: 12, weight: .medium))
                            .foregroundStyle(hour.source == .pooled ? Color.secondary : Color.accentColor)
                    } else {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(hour.source == .pooled ? Color.secondary.opacity(0.65) : Color.accentColor)
                            .frame(height: max(1, CGFloat(rate / maximumRate) * 42))
                    }
                } else {
                    Text("?").font(.system(size: 10)).foregroundStyle(.secondary)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 42)
            .padding(.horizontal, 2).padding(.vertical, 3)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 3))
            .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(
                selectedID == hour.id ? Color.primary : .clear, lineWidth: 1.5
            ))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(ScheduleProfileText.title(hour) + "\n" + ScheduleProfileText.detail(hour))
        .accessibilityLabel(ScheduleProfileText.title(hour))
        .accessibilityValue(ScheduleProfileText.detail(hour))
        .accessibilityAddTraits(selectedID == hour.id ? .isSelected : [])
    }

    private var legend: some View {
        HStack(spacing: 16) {
            Label { Text("Observed pattern") } icon: { Rectangle().fill(Color.accentColor).frame(width: 8, height: 8) }
            Label { Text("Across all days") } icon: { Rectangle().fill(.secondary).frame(width: 8, height: 8) }
            Text("– Zero usage")
            Text("? Unknown")
        }
        .font(.caption).foregroundStyle(.secondary)
    }
}
