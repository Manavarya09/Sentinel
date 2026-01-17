import SwiftUI

struct ActivitySummaryView: View {
    let summary: ActivitySummary?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sentinel Hybrid").font(.largeTitle).bold()
            if let s = summary {
                Text("Day: \(DateFormatter.localizedString(from: s.day, dateStyle: .medium, timeStyle: .none))")
                Text("Total Duration: \(String(format: "%.0f s", s.totalDuration))")
                Text("Sessions: \(s.sessionCount)")
                Divider()
                ForEach(Array(s.countsByType.keys.sorted()), id: \.self) { key in
                    Text("\(key): \(s.countsByType[key] ?? 0)")
                }
            } else {
                Text("No data yet.")
            }
            Spacer()
        }
        .padding()
    }
}
