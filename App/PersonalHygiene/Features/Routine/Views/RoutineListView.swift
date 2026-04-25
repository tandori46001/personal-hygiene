import SwiftUI

struct RoutineListView: View {
    @Bindable var viewModel: RoutineListViewModel

    var body: some View {
        NavigationStack {
            List(viewModel.blocks) { block in
                BlockRow(block: block)
            }
            .navigationTitle(Text("routine.title", bundle: .main))
        }
    }
}

private struct BlockRow: View {
    let block: Block

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(block.title)
                    .font(.body)
                Text(block.category.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(formattedTime(minutes: block.startMinutesFromMidnight))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func formattedTime(minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        return String(format: "%02d:%02d", hour, minute)
    }
}

#Preview {
    RoutineListView(viewModel: RoutineListViewModel.preview)
}
