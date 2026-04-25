import SwiftUI

struct SleepDashboardView: View {
    @Bindable var viewModel: SleepDashboardViewModel

    var body: some View {
        NavigationStack {
            Form {
                if let error = viewModel.errorMessage {
                    Section {
                        ErrorBanner(message: error, onDismiss: { viewModel.errorMessage = nil })
                    }
                }
                Section {
                    Stepper(value: $viewModel.wakeUpHour, in: 0...23) {
                        HStack {
                            Text("sleep.wakeUp.hour", bundle: .main)
                            Spacer()
                            Text(String(format: "%02d", viewModel.wakeUpHour))
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                    Stepper(value: $viewModel.wakeUpMinute, in: 0...59, step: 5) {
                        HStack {
                            Text("sleep.wakeUp.minute", bundle: .main)
                            Spacer()
                            Text(String(format: "%02d", viewModel.wakeUpMinute))
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                } header: {
                    Text("sleep.section.wakeUp", bundle: .main)
                }

                Section {
                    HStack {
                        Text("sleep.bedtime.target", bundle: .main)
                        Spacer()
                        Text(formattedTime(minutes: viewModel.bedtimeMinutes))
                            .font(.system(.title2, design: .monospaced))
                            .foregroundStyle(.tint)
                    }
                    Text("sleep.target.note", bundle: .main)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("sleep.section.bedtime", bundle: .main)
                }

                if viewModel.isAvailable {
                    Section {
                        if let night = viewModel.lastNight {
                            HStack {
                                Text("sleep.lastNight.actual", bundle: .main)
                                Spacer()
                                Text(formattedDuration(minutes: night.durationMinutes))
                                    .font(.system(.body, design: .monospaced))
                            }
                            if let deficit = viewModel.lastNightDeficitMinutes, deficit > 0 {
                                Label {
                                    Text(LocalizedStringResource("sleep.deficit \(deficit)"))
                                } icon: {
                                    Image(systemName: "exclamationmark.triangle")
                                }
                                .foregroundStyle(.orange)
                            }
                        } else {
                            Text("sleep.lastNight.empty", bundle: .main)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("sleep.section.lastNight", bundle: .main)
                    }
                } else {
                    Section {
                        Text("sleep.unavailable", bundle: .main)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Link(destination: URL(string: "App-prefs:com.apple.donotdisturb")!) {
                        Label {
                            Text("sleep.action.openFocus", bundle: .main)
                        } icon: {
                            Image(systemName: "moon.fill")
                        }
                    }
                    Text("sleep.action.openFocus.note", bundle: .main)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("sleep.section.focus", bundle: .main)
                }
            }
            .navigationTitle(Text("sleep.title", bundle: .main))
            .task { await viewModel.reload() }
        }
    }

    private func formattedTime(minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        return String(format: "%02d:%02d", hour, minute)
    }

    private func formattedDuration(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return String(format: "%dh %02dm", hours, mins)
    }
}
