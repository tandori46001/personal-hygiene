import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("personal-hygiene")
                .font(.headline)
            Text("Watch app coming in Phase 2")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
