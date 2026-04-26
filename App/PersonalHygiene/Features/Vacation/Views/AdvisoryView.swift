import SwiftUI

struct AdvisoryView: View {

    let link: TravelAdvisoryLink

    var body: some View {
        Form {
            Section {
                LabeledContent {
                    Text(verbatim: link.displayName)
                } label: {
                    Text("trip.advisory.label.destination", bundle: .main)
                }
                LabeledContent {
                    Text(verbatim: link.source)
                } label: {
                    Text("trip.advisory.label.source", bundle: .main)
                }
            }

            Section {
                Link(destination: link.url) {
                    Label {
                        Text("trip.advisory.action.open", bundle: .main)
                    } icon: {
                        Image(systemName: "arrow.up.right.square")
                    }
                }
            } footer: {
                Text("trip.advisory.footer", bundle: .main)
            }
        }
        .navigationTitle(Text("trip.advisory.title", bundle: .main))
        .navigationBarTitleDisplayMode(.inline)
    }
}
