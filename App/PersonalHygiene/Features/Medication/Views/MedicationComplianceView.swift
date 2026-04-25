import SwiftUI

struct MedicationComplianceView: View {
    @Bindable var viewModel: MedicationComplianceViewModel

    var body: some View {
        NavigationStack {
            Group {
                if !viewModel.isAvailable {
                    ContentUnavailableView {
                        Label {
                            Text("medication.unavailable.title", bundle: .main)
                        } icon: {
                            Image(systemName: "pills")
                        }
                    } description: {
                        Text("medication.unavailable.description", bundle: .main)
                    }
                } else if viewModel.summaries.isEmpty {
                    ContentUnavailableView {
                        Label {
                            Text("medication.empty.title", bundle: .main)
                        } icon: {
                            Image(systemName: "pills")
                        }
                    } description: {
                        Text("medication.empty.description", bundle: .main)
                    }
                } else {
                    List {
                        Section {
                            HStack {
                                Text("medication.overall", bundle: .main)
                                Spacer()
                                Text(percentageString(viewModel.overall))
                                    .font(.headline)
                                    .foregroundStyle(adherenceColor(viewModel.overall))
                            }
                        }

                        Section {
                            ForEach(viewModel.summaries, id: \.day) { summary in
                                ComplianceRow(summary: summary)
                            }
                        } header: {
                            Text("medication.section.last7days", bundle: .main)
                        }
                    }
                }
            }
            .navigationTitle(Text("medication.title", bundle: .main))
            .task { await viewModel.reload() }
        }
    }

    private func percentageString(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private func adherenceColor(_ value: Double) -> Color {
        switch value {
        case 0.99...: return .green
        case 0.85..<0.99: return .yellow
        default: return .red
        }
    }
}

private struct ComplianceRow: View {
    let summary: DailyCompliance

    var body: some View {
        HStack {
            Text(summary.day, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                .font(.body)
            Spacer()
            Text("\(summary.takenCount)/\(summary.scheduledCount)")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}
