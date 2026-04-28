import Foundation

/// Round-25 slice T5.38: pure helper that turns an array of emergency
/// contacts into a vCard 3.0 string the user can share / save to the
/// system Contacts app. Caller is responsible for IO.
public enum EmergencyContactsExporter {

    public static func vCard(for contacts: [TripEmergencyContact]) -> String {
        contacts.map(vCard(for:)).joined(separator: "\n")
    }

    public static func vCard(for contact: TripEmergencyContact) -> String {
        var lines = ["BEGIN:VCARD", "VERSION:3.0"]
        lines.append("FN:\(escape(contact.label))")
        if !contact.phone.isEmpty {
            lines.append("TEL;TYPE=CELL:\(contact.phone)")
        }
        if let notes = contact.notes, !notes.isEmpty {
            lines.append("NOTE:\(escape(notes))")
        }
        lines.append("END:VCARD")
        return lines.joined(separator: "\n")
    }

    private static func escape(_ field: String) -> String {
        field
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}
