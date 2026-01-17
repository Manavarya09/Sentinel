import SwiftUI

struct RootView: View {
    @StateObject private var vm = AnalyticsViewModel()
    var body: some View {
        ActivitySummaryView(summary: vm.summary)
            .onAppear { vm.refreshDaily() }
    }
}
