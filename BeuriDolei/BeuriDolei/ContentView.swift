import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ChallengeStore

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.core.training")
                .imageScale(.large)
                .foregroundStyle(.orange)
            Text("BeuriDolei")
                .font(.largeTitle.bold())
            Text("Jour \(store.currentDayIndex + 1) · \(store.currentDay.series.map { "\($0)s" }.joined(separator: " - "))")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environmentObject(ChallengeStore())
}
