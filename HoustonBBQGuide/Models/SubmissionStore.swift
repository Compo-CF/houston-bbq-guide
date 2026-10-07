import Foundation
import FirebaseCore
import FirebaseFirestore

/// Sends suggested joints to Firestore for Reid to approve.
///
/// Firebase is configured only when `GoogleService-Info.plist` is actually in
/// the bundle. That is deliberate: the app shipped its first builds with no
/// backend at all, and a missing plist makes `FirebaseApp.configure()` crash on
/// launch. With this guard the app still builds, runs and ships for anyone who
/// has not set Firebase up - the suggestion form simply reports itself
/// unavailable instead of taking the whole app down.
@Observable
final class SubmissionStore {
    enum State: Equatable {
        case idle
        case sending
        case sent
        case failed(String)
    }

    private(set) var state: State = .idle

    /// Whether a suggestion can be sent at all on this build.
    static let isAvailable: Bool = {
        Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil
    }()

    /// Call once at launch, before anything touches Firestore.
    static func configureIfPossible() {
        guard isAvailable, FirebaseApp.app() == nil else { return }
        FirebaseApp.configure()
    }

    private var appVersion: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(short) (\(build))"
    }

    @MainActor
    func send(_ submission: JointSubmission) async {
        guard Self.isAvailable else {
            state = .failed("Suggestions are not available in this build.")
            return
        }
        if let problem = submission.validationProblem {
            state = .failed(problem)
            return
        }

        state = .sending
        do {
            try await Firestore.firestore()
                .collection("submissions")
                .addDocument(data: submission.firestorePayload(appVersion: appVersion))
            state = .sent
        } catch {
            // The message a user sees is deliberately not the raw Firestore
            // error - "Missing or insufficient permissions" helps nobody
            // standing in a parking lot.
            state = .failed("Could not send that. Check your connection and try again.")
        }
    }

    func reset() {
        state = .idle
    }
}
