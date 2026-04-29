import SwiftUI

/// Round-28: per-page section builders for the round-27 IA collapse,
/// extracted from `SettingsView.swift` so that file fits SwiftLint's
/// type_body_length + file_length limits. Each builder still relies on
/// the section view-builders defined in `SettingsViewBackup.swift`,
/// `SettingsViewRound12.swift`, etc.
extension SettingsView {

    @ViewBuilder
    var rootMenu: some View {
        Section {
            ForEach(Self.Page.entries, id: \.self) { entry in
                NavigationLink {
                    SettingsView(
                        viewModel: viewModel,
                        focusScheduleStore: focusScheduleStore,
                        diagnosticsActions: diagnosticsActions,
                        routineRepository: routineRepository,
                        page: entry
                    )
                } label: {
                    Label {
                        Text(entry.titleKey, bundle: .main)
                            .font(.body)
                    } icon: {
                        Image(systemName: entry.iconName)
                            .foregroundStyle(entry.tint)
                    }
                }
            }
        }
    }

    @ViewBuilder
    var notificationsPage: some View {
        notificationsSection
        schedulingSection
        categoryMuteSection
        pauseSection
        quietHoursSection
    }

    @ViewBuilder
    var appearancePage: some View {
        themeSection
    }

    @ViewBuilder
    var daysPage: some View {
        importantDaysEntrySection
        birthdayLeadDefaultSection
        giftIdeasCSVRow
        advisorySourcesEntrySection
        focusEntrySection
    }

    @ViewBuilder
    var homePage: some View {
        HomeLocationSection()
        footprintSummarySection
    }

    @ViewBuilder
    var moodPage: some View {
        moodLogSection
        moodTrendSection
        moodWeeklyGoalSection
        moodWeekStripSection
        localizedMoodCSVCopyRow
        moodSectionedDisclosure
        moodHistogramSection
        moodHeatmapSection
        streakShareSection
    }

    @ViewBuilder
    var dataPage: some View {
        backupSection
        backupAutoFrequencySection
        backupArchiveCountCaption
        everythingBundleRow
        resetAllCachesRow
        resetOnboardingTipsRow
        round26ResetAllDataRow
    }

    @ViewBuilder
    var aboutPage: some View {
        aboutSection
        aboutFooterSection
    }

    // MARK: - Days-page sub-sections (so daysPage stays compact)

    @ViewBuilder
    private var importantDaysEntrySection: some View {
        Section {
            NavigationLink {
                ImportantDaysSettingsView()
            } label: {
                Label {
                    Text("settings.importantDays.entry", bundle: .main)
                } icon: {
                    Image(systemName: "calendar.badge.exclamationmark")
                }
            }
        } header: {
            Text("settings.section.importantDays", bundle: .main)
        }
    }

    @ViewBuilder
    private var advisorySourcesEntrySection: some View {
        Section {
            NavigationLink {
                AdvisorySourcesSettingsView()
            } label: {
                Label {
                    Text("settings.advisory.sources.entry", bundle: .main)
                } icon: {
                    Image(systemName: "globe")
                }
            }
        } header: {
            Text("settings.advisory.sources.header", bundle: .main)
        }
    }

    @ViewBuilder
    private var focusEntrySection: some View {
        if let focusScheduleStore {
            Section {
                NavigationLink {
                    FocusScheduleView(
                        store: focusScheduleStore,
                        blocksProvider: {
                            guard let repository = routineRepository else { return [] }
                            return (try? repository.allTemplates().flatMap(\.blocks)) ?? []
                        }
                    )
                } label: {
                    Label {
                        Text("settings.focus.entry", bundle: .main)
                    } icon: {
                        Image(systemName: "moon.zzz")
                    }
                }
            } header: {
                Text("settings.section.focus", bundle: .main)
            }
        }
    }
}
