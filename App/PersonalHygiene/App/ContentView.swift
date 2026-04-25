import SwiftUI

struct ContentView: View {
    var body: some View {
        RoutineListView(viewModel: RoutineListViewModel.preview)
    }
}

#Preview {
    ContentView()
}
