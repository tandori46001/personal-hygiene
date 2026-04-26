import SwiftUI

struct HydrationDashboardView: View {
    @Bindable var viewModel: HydrationDashboardViewModel

    @AppStorage("hydration.goal.ml") private var goalMilliliters: Int = HydrationGoal.default.dailyMilliliters

    private static let quickAmounts = [150, 250, 330, 500]

    var body: some View {
        NavigationStack {
            List {
                if let error = viewModel.errorMessage {
                    Section {
                        ErrorBanner(message: error, onDismiss: { viewModel.errorMessage = nil })
                    }
                }

                Section {
                    HStack(alignment: .firstTextBaseline) {
                        Text("hydration.today.total", bundle: .main)
                        Spacer()
                        Text(verbatim: "\(viewModel.totalMilliliters) ml")
                            .font(.system(.title2, design: .monospaced))
                            .foregroundStyle(.tint)
                    }
                    ProgressView(value: viewModel.progress)
                        .tint(progressColor)
                    HStack {
                        Text("hydration.today.goal", bundle: .main)
                        Spacer()
                        Text(verbatim: "\(viewModel.goal.dailyMilliliters) ml")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("hydration.section.today", bundle: .main)
                }

                Section {
                    HStack {
                        ForEach(Self.quickAmounts, id: \.self) { amount in
                            Button {
                                viewModel.log(milliliters: amount)
                            } label: {
                                Text(verbatim: "+\(amount)")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityLabel(
                                Text(LocalizedStringResource("hydration.action.add \(amount)"))
                            )
                        }
                    }
                } header: {
                    Text("hydration.section.quickLog", bundle: .main)
                }

                Section {
                    Stepper(
                        value: $goalMilliliters,
                        in: 500...5000,
                        step: 100
                    ) {
                        HStack {
                            Text("hydration.goal.field", bundle: .main)
                            Spacer()
                            Text(verbatim: "\(goalMilliliters) ml")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onChange(of: goalMilliliters) { _, new in
                        viewModel.goal = HydrationGoal(dailyMilliliters: new)
                    }
                } header: {
                    Text("hydration.section.goal", bundle: .main)
                }

                Section {
                    if viewModel.todayLogs.isEmpty {
                        Text("hydration.history.empty", bundle: .main)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.todayLogs) { log in
                            HydrationLogRow(log: log)
                        }
                    }
                } header: {
                    Text("hydration.section.history", bundle: .main)
                }
            }
            .navigationTitle(Text("hydration.title", bundle: .main))
            .onAppear {
                viewModel.goal = HydrationGoal(dailyMilliliters: goalMilliliters)
                viewModel.reload()
            }
        }
    }

    private var progressColor: Color {
        switch viewModel.progress {
        case 0.99...: return .green
        case 0.5..<0.99: return .blue
        default: return .orange
        }
    }
}

private struct HydrationLogRow: View {
    let log: HydrationLog

    var body: some View {
        HStack {
            Text(log.drankAt, format: .dateTime.hour().minute())
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .leading)
            Text(verbatim: "\(log.milliliters) ml")
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}
