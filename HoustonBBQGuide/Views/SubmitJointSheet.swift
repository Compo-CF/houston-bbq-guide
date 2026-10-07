import SwiftUI

/// Lets anyone suggest a joint for the guide. Submissions land in Firestore
/// as `pending` and reach the guide only after Reid approves one - this is a
/// curated editorial directory, not a crowd-sourced list, and the form says so
/// rather than implying the tip goes live.
struct SubmitJointSheet: View {
    @Environment(JointStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var submission = JointSubmission()
    @State private var submissions = SubmissionStore()
    @State private var showDuplicateAnyway = false

    private var duplicate: Joint? {
        submission.existingMatch(in: store.joints)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                if submissions.state == .sent {
                    sentConfirmation
                } else {
                    form
                }
            }
            .navigationTitle("Suggest a joint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Theme.muted)
                }
            }
        }
    }

    // MARK: Form

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Tell us where it is and why it belongs. Every suggestion "
                     + "is read and checked before anything joins the guide.")
                    .font(.system(size: 14, design: .serif))
                    .foregroundStyle(Theme.muted)

                field("Name", text: $submission.name,
                      placeholder: "Pinkerton's Barbecue")

                if let duplicate, !showDuplicateAnyway {
                    duplicateNotice(duplicate)
                }

                field("Neighborhood or area", text: $submission.area,
                      placeholder: "Heights")
                field("Address", text: $submission.address,
                      placeholder: "Optional", optional: true)
                field("Website or Instagram", text: $submission.link,
                      placeholder: "Optional", optional: true)

                labelled("Why it belongs") {
                    TextEditor(text: $submission.note)
                        .frame(minHeight: 96)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(Theme.ink)
                }

                Divider().overlay(Theme.line)

                Text("So we can come back to you if we need more. Optional.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted2)
                field("Your name", text: $submission.submitterName,
                      placeholder: "Optional", optional: true)
                field("Your email", text: $submission.submitterEmail,
                      placeholder: "Optional", optional: true,
                      keyboard: .emailAddress)

                if case .failed(let message) = submissions.state {
                    Text(message)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.ember)
                }

                sendButton

                if !SubmissionStore.isAvailable {
                    Text("Suggestions are not enabled in this build yet.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.muted2)
                }
            }
            .padding(20)
        }
    }

    private var sendButton: some View {
        Button {
            Task { await submissions.send(submission) }
        } label: {
            HStack(spacing: 8) {
                if submissions.state == .sending {
                    ProgressView().tint(Theme.bg)
                } else {
                    Image(systemName: "paperplane.fill")
                }
                Text(submissions.state == .sending ? "Sending" : "Send suggestion")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(canSend ? Theme.ember : Theme.surface2,
                        in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(canSend ? Theme.bg : Theme.muted2)
        }
        .disabled(!canSend)
    }

    private var canSend: Bool {
        guard SubmissionStore.isAvailable, submission.isValid else { return false }
        guard submissions.state != .sending else { return false }
        return duplicate == nil || showDuplicateAnyway
    }
}

// MARK: - Pieces

private extension SubmitJointSheet {
    /// The commonest suggestion for a curated guide is something already in
    /// it. Saying so here is better manners than queuing a duplicate for Reid
    /// to reject - but it is a nudge, not a wall, because the matcher is
    /// fuzzy and two joints really can share a name.
    func duplicateNotice(_ joint: Joint) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Already in the guide", systemImage: "checkmark.seal.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.amber)
            Text("\(joint.name) is listed under \(joint.primaryArea).")
                .font(.system(size: 13))
                .foregroundStyle(Theme.ink)
            Button("Suggest it anyway") { showDuplicateAnyway = true }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.ember)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 10))
    }

    var sentConfirmation: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.ember)
            Text("Thanks - that's in the queue")
                .font(Theme.serif(22, .bold))
                .foregroundStyle(Theme.ink)
            Text("Reid reads every suggestion. If it makes the guide you'll "
                 + "see it turn up in the app - no app update needed.")
                .font(.system(size: 14, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.muted)
            Button("Done") { dismiss() }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.bg)
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(Theme.ember, in: Capsule())
                .padding(.top, 8)
        }
        .padding(32)
    }

    func labelled<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.muted2)
            content()
        }
    }

    func field(
        _ title: String,
        text: Binding<String>,
        placeholder: String,
        optional: Bool = false,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        labelled(title) {
            TextField("", text: text, prompt:
                Text(placeholder).foregroundStyle(Theme.muted2))
                .keyboardType(keyboard)
                .textInputAutocapitalization(optional && keyboard == .emailAddress
                                             ? .never : .words)
                .autocorrectionDisabled(keyboard == .emailAddress)
                .padding(12)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(Theme.ink)
        }
    }
}

#Preview("Suggest a joint") {
    SubmitJointSheet()
        .environment(JointStore())
        .preferredColorScheme(.dark)
}
