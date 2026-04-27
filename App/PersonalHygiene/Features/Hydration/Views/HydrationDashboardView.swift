import Charts
import SwiftUI

struct HydrationDashboardView: View {
    @Bindable var viewModel: HydrationDashboardViewModel

    @AppStorage("hydration.goal.ml") private var goalMilliliters: Int = HydrationGoal.default.dailyMilliliters

    private static let quickAmounts = [150, 250, 330, 500]
    private static let goalPresets = [2000, 2500, 3000]

    var body: some View {
        NavigationStack {
            List {
                if let error = viewModel.errorMessage {
                    Section {
                        ErrorBanner(message: error, onDismiss: { viewModel.errorMessage = nil })
                    }
                }

                if let lastDeleted = viewModel.lastDeleted {
                    Section {
                        HStack {
                            Image(systemName: "arrow.uturn.backward.circle")
                                .foregroundStyle(.tint)
                                .accessibilityHidden(true)
                            Text(
                                "hydration.undo.deleted \(lastDeleted.milliliters)",
                                bundle: .main
                            )
                            Spacer()
                            Button {
                                viewModel.undoLastDelete()
                            } label: {
                                Text("common.undo", bundle: .main)
                            }
                            .buttonStyle(.bordered)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    .task(id: lastDeleted.id) {
                        try? await Task.sleep(nanoseconds: 5_000_000_000)
                        if viewModel.lastDeleted?.id == lastDeleted.id {
                            viewModel.clearLastDeleted()
                        }
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
                    .accessibilityElement(children: .combine)
                    ProgressView(value: viewModel.progress)
                        .tint(progressColor)
                        .accessibilityLabel(
                            Text(LocalizedStringResource(
                                "a11y.hydration.progress \(Int(viewModel.progress * 100))"
                            ))
                        )
                    HStack {
                        Text("hydration.today.goal", bundle: .main)
                        Spacer()
                        Text(verbatim: "\(viewModel.goal.dailyMilliliters) ml")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    let streak = viewModel.streakDays()
                    let best = viewModel.bestStreakDays()
                    if streak > 0 {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                                .accessibilityHidden(true)
                            Text("hydration.streak.\(streak)", bundle: .main)
                            Spacer()
                        }
                        .accessibilityElement(children: .combine)
                    }
                    if best > 0 && best > streak {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.yellow)
                                .accessibilityHidden(true)
                            Text("hydration.bestStreak.\(best)", bundle: .main)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .accessibilityElement(children: .combine)
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
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
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
                    HStack {
                        ForEach(Self.goalPresets, id: \.self) { preset in
                            presetButton(preset)
                        }
                    }
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
                    HydrationWeeklyChart(
                        totals: viewModel.weeklyTotals(),
                        goalMilliliters: viewModel.goal.dailyMilliliters
                    )
                } header: {
                    Text("hydration.section.weekly", bundle: .main)
                }

                Section {
                    if viewModel.todayLogs.isEmpty {
                        Text("hydration.history.empty", bundle: .main)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.todayLogs) { log in
                            HydrationLogRow(log: log)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        viewModel.deleteLog(log)
                                    } label: {
                                        Label {
                                            Text("hydration.action.deleteLog", bundle: .main)
                                        } icon: {
                                            Image(systemName: "trash")
                                        }
                                    }
                                }
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

    private func presetLabel(_ ml: Int) -> String {
        let liters = Double(ml) / 1000
        return String(format: "%.1fL", liters)
    }

    @ViewBuilder
    private func presetButton(_ preset: Int) -> some View {
        let label = Text(verbatim: presetLabel(preset))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity)
        let a11y = Text(LocalizedStringResource("hydration.goal.preset \(preset)"))
        if goalMilliliters == preset {
            Button {
                goalMilliliters = preset
            } label: { label }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(a11y)
        } else {
            Button {
                goalMilliliters = preset
            } label: { label }
                .buttonStyle(.bordered)
                .accessibilityLabel(a11y)
        }
    }
}

private struct HydrationWeeklyChart: View {
    let totals: [(date: Date, milliliters: Int)]
    let goalMilliliters: Int

    var body: some View {
        Chart {
            ForEach(totals, id: \.date) { entry in
                BarMark(
                    x: .value("hydration.weekly.dayAxis", entry.date, unit: .day),
                    y: .value("hydration.weekly.mlAxis", entry.milliliters)
                )
                .foregroundStyle(entry.milliliters >= goalMilliliters ? .green : .blue)
            }
            if goalMilliliters > 0 {
                RuleMark(y: .value("hydration.weekly.goal", goalMilliliters))
                    .foregroundStyle(.orange.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.narrow))
            }
        }
        .frame(height: 140)
        .accessibilityLabel(Text("a11y.hydration.weeklyChart", bundle: .main))
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
