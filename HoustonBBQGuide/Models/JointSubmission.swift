import Foundation

/// A joint someone has suggested for the guide.
///
/// Deliberately a fraction of `Joint`. The guide's entries carry pitmaster
/// names, wood, pit type, accolades and a written history - editorial work
/// nobody filling in a form on their phone can supply, and work that has to be
/// verified anyway. So the form asks only for what a stranger genuinely knows:
/// where it is, and why it belongs. Everything else is research done after
/// approval.
struct JointSubmission: Codable, Equatable {
    var name: String = ""
    var area: String = ""
    var address: String = ""
    var link: String = ""
    var note: String = ""
    var submitterName: String = ""
    var submitterEmail: String = ""

    /// Caps mirrored in the Firestore rules. Anything unbounded that an
    /// unauthenticated client can write is a bill waiting to happen.
    enum Limit {
        static let name = 80
        static let area = 60
        static let address = 160
        static let link = 300
        static let note = 600
        static let submitter = 120
    }

    var trimmed: JointSubmission {
        var copy = self
        copy.name = name.trimmed(to: Limit.name)
        copy.area = area.trimmed(to: Limit.area)
        copy.address = address.trimmed(to: Limit.address)
        copy.link = link.trimmed(to: Limit.link)
        copy.note = note.trimmed(to: Limit.note)
        copy.submitterName = submitterName.trimmed(to: Limit.submitter)
        copy.submitterEmail = submitterEmail.trimmed(to: Limit.submitter)
        return copy
    }

    /// What has to be there before Send does anything. The bar is low on
    /// purpose - a tip with a name and a reason is still useful; a tip with a
    /// blank name is not.
    var validationProblem: String? {
        let t = trimmed
        if t.name.count < 2 { return "Give the joint a name." }
        if t.area.isEmpty && t.address.isEmpty {
            return "Say roughly where it is - a neighborhood is enough."
        }
        if t.note.count < 10 {
            return "Add a line on why it belongs in the guide."
        }
        if !t.submitterEmail.isEmpty && !t.submitterEmail.contains("@") {
            return "That email address does not look right."
        }
        return nil
    }

    var isValid: Bool { validationProblem == nil }

    /// The payload written to Firestore. `status` is set here rather than by
    /// the caller so a client cannot submit something pre-approved; the rules
    /// reject any other value.
    func firestorePayload(appVersion: String) -> [String: Any] {
        let t = trimmed
        return [
            "name": t.name,
            "area": t.area,
            "address": t.address,
            "link": t.link,
            "note": t.note,
            "submitterName": t.submitterName,
            "submitterEmail": t.submitterEmail,
            "status": "pending",
            "appVersion": appVersion,
            "submittedAt": Date().timeIntervalSince1970,
        ]
    }
}

// MARK: - Already in the guide?

extension JointSubmission {
    /// A joint already in the guide whose name matches what is being typed.
    ///
    /// Checked before sending, because the commonest suggestion for a curated
    /// directory is something already in it - and telling someone that up
    /// front is better manners than silently queuing a duplicate for Reid to
    /// reject.
    func existingMatch(in joints: [Joint]) -> Joint? {
        let needle = Self.normalize(name)
        guard needle.count >= 3 else { return nil }
        return joints.first { joint in
            let hay = Self.normalize(joint.name)
            return hay == needle || hay.contains(needle) || needle.contains(hay)
        }
    }

    /// Lowercase, strip punctuation, and drop the words that appear in half
    /// the names in Houston - otherwise "Truth BBQ" and "Truth Barbeque" look
    /// like different places.
    static func normalize(_ raw: String) -> String {
        let noise: Set<String> = [
            "bbq", "barbecue", "barbeque", "bar-b-que", "bar", "b", "que",
            "smokehouse", "smoke", "house", "co", "company", "the", "and",
            "pit", "kitchen", "s",
        ]
        let cleaned = raw.lowercased().map { ch -> Character in
            ch.isLetter || ch.isNumber ? ch : " "
        }
        return String(cleaned)
            .split(separator: " ")
            .map(String.init)
            .filter { !noise.contains($0) }
            .joined()
    }
}

private extension String {
    func trimmed(to limit: Int) -> String {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.count <= limit ? t : String(t.prefix(limit))
    }
}
