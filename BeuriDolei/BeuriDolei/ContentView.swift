import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "figure.core.training")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("BeuriDolei")
                .font(.largeTitle.bold())
            Text("Défi planche 30 jours")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
