import Foundation

/// One event on the guide's calendar — the annual festival (April), the BBQ
/// Throwdown (September), or anything else. Lives in the remote Joints.json under
/// "events", so the calendar changes without an app release. Every field beyond
/// `name` is optional, so a bare "save the date" and a full competition lineup
/// both render from the same shape.
struct Event: Codable, Hashable, Identifiable {
    let name: String
    let tagline: String?        // short kicker, e.g. "Houston BBQ Throwdown"
    let kind: String?           // small label, e.g. "Competition", "Festival"
    let date: String?
    let time: String?
    let venue: String?
    let address: String?
    let ticketURL: String?
    let about: String?          // event-specific blurb; falls back to a generic line
    let participants: [Participant]?
    let judges: [Judge]?

    var id: String { name }

    // Non-optional accessors so a name-only event (no lineup/judges in the JSON)
    // decodes and renders cleanly.
    var lineup: [Participant] { participants ?? [] }
    var panel: [Judge] { judges ?? [] }

    struct Participant: Codable, Hashable, Identifiable {
        let name: String
        let note: String?        // e.g. "Defending People's Choice"
        var id: String { name }
    }

    struct Judge: Codable, Hashable, Identifiable {
        let name: String
        let affiliation: String?
        var id: String { name }
    }

    /// "Sunday, September 20, 2026 · 1–4 PM" from whatever parts exist.
    var whenLine: String {
        [date, time].compactMap { $0 }.joined(separator: " · ")
    }
}
