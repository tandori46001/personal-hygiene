import SwiftData
import SwiftUI
import UIKit

/// Round-22 SettingsView wires for round-21 helpers that landed without UI:
/// - T2.8 `giftIdeasCSVRow`: copy `BirthdayGiftIdeaCSVExporter.render()` to
///   pasteboard.
/// - T2.9 `birthdayLeadDefaultSection`: stepper bound to
///   `BirthdayLeadDefaultStore.effectiveDefault(...)`.
/// - T2.13 `moodWeekStripSection`: 7-day mood emoji strip mirrored from
///   Today so the user can see the same data inside Settings without
///   leaving the disclosure.
/// - T3.17 wrapper `footprintSummarySection`: pulls trips out of the
///   environment ModelContext and feeds `SettingsFootprintSummaryView`.
extension SettingsView {

    /// Round-22 wrapper combining every round-21 + round-22 settings
    /// section so the host body keeps a single call-site (lint cap on
    /// SettingsView body length).
    @ViewBuilder
    var round22Sections: some View {
        moodTrendSection
        moodWeeklyGoalSection
        moodWeekStripSection
        localizedMoodCSVCopyRow
        footprintSummarySection
        birthdayLeadDefaultSection
        giftIdeasCSVRow
    }

    @ViewBuilder
    var giftIdeasCSVRow: some View {
        let dictionary = BirthdayIdeaStore.dictionary()
        if !dictionary.isEmpty {
            Section {
                Button {
                    UIPasteboard.general.string = BirthdayGiftIdeaCSVExporter.render(
                        dictionary: dictionary
                    )
                } label: {
                    Label {
                        Text("settings.birthdays.giftIdeas.copyCSV \(dictionary.count)", bundle: .main)
                    } icon: {
                        Image(systemName: "gift")
                    }
                }
            } footer: {
                Text("settings.birthdays.giftIdeas.copyCSV.footer", bundle: .main)
            }
        }
    }

    @ViewBuilder
    var birthdayLeadDefaultSection: some View {
        Section {
            let leadBinding = Binding<Int>(
                get: { BirthdayLeadDefaultStore.effectiveDefault() },
                set: { BirthdayLeadDefaultStore.setDefault($0) }
            )
            Stepper(value: leadBinding, in: BirthdayLeadDefaultStore.allowedRange) {
                Text("settings.birthdays.leadDefault.value \(leadBinding.wrappedValue)", bundle: .main)
            }
        } header: {
            Text("settings.birthdays.leadDefault.title", bundle: .main)
        } footer: {
            Text("settings.birthdays.leadDefault.footer", bundle: .main)
        }
    }

    @ViewBuilder
    var moodWeekStripSection: some View {
        let strip = TodayView.moodWeekStrip()
        let active = strip.contains { $0.symbol != "·" }
        if active {
            Section {
                HStack(spacing: 6) {
                    ForEach(strip, id: \.day) { cell in
                        VStack(spacing: 2) {
                            Text(verbatim: cell.symbol).font(.callout)
                            Text(verbatim: TodayView.weekdayInitial(for: cell.day))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text("settings.moodLog.weekStrip.a11y", bundle: .main))
            } header: {
                Text("settings.moodLog.weekStrip.title", bundle: .main)
            }
        }
    }

    @ViewBuilder
    var footprintSummarySection: some View {
        // Pulls trips through the same `Environment(\.modelContext)` the
        // host uses; falls back to an empty array when no container is
        // bound (preview / detached usage).
        TripFootprintInjector { trips, home in
            SettingsFootprintSummaryView(trips: trips, homeLocation: home)
        }
    }
}

/// Round-22 slice T3.17: thin wrapper around the SwiftData fetch that the
/// `SettingsFootprintSummaryView` needs. Keeps the SettingsView body free
/// of explicit `@Query` boilerplate.
struct TripFootprintInjector<Content: View>: View {
    @Query private var trips: [Trip]
    @AppStorage(HomeLocationStore.latitudeKey) private var lat: Double = .nan
    @AppStorage(HomeLocationStore.longitudeKey) private var lon: Double = .nan
    @AppStorage(HomeLocationStore.nameKey) private var name: String = ""

    let content: ([Trip], BlockLocation?) -> Content

    init(@ViewBuilder content: @escaping ([Trip], BlockLocation?) -> Content) {
        self.content = content
    }

    private var homeLocation: BlockLocation? {
        guard !lat.isNaN, !lon.isNaN else { return nil }
        return BlockLocation(latitude: lat, longitude: lon, displayName: name.isEmpty ? nil : name)
    }

    var body: some View {
        content(trips, homeLocation)
    }
}
