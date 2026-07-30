import SwiftUI

/// The Events tab — a calendar of the guide's events (the annual festival, the
/// BBQ Throwdown, and whatever else). Driven by `events` in Joints.json, so the
/// list changes without an app release. Each event opens its own detail screen.
struct EventsTabView: View {
    @Environment(JointStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    if store.events.isEmpty {
                        emptyState
                    } else {
                        ForEach(store.events) { event in
                            NavigationLink { EventDetailView(event: event) } label: {
                                EventCard(event: event)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("WHAT'S ON").font(.system(size: 10, weight: .bold)).tracking(2.4)
                .foregroundStyle(Theme.ember)
            Text("Events").font(Theme.serif(25)).foregroundStyle(Theme.ink)
            Text("Festivals, throwdowns, and gatherings from the Houston BBQ Guide.")
                .font(.system(size: 12.5)).foregroundStyle(Theme.muted)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar").font(.system(size: 34)).foregroundStyle(Theme.muted2)
            Text("No events scheduled right now.\nCheck back soon.")
                .font(.system(size: 12.5)).foregroundStyle(Theme.muted2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 40)
    }
}

/// A tappable summary card for one event in the list.
private struct EventCard: View {
    let event: Event
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let kind = event.kind {
                    Text(kind.uppercased()).font(.system(size: 9.5, weight: .bold)).tracking(1.5)
                        .foregroundStyle(Theme.amber)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .overlay(Capsule().stroke(Theme.amber.opacity(0.4)))
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.muted2)
            }
            Text(event.name).font(Theme.serif(22)).foregroundStyle(Theme.ink)
            if !event.whenLine.isEmpty {
                Label(event.whenLine, systemImage: "calendar")
                    .font(.system(size: 12.5, weight: .semibold)).foregroundStyle(Theme.ink)
            }
            if let venue = event.venue {
                Label(venue, systemImage: "mappin.and.ellipse")
                    .font(.system(size: 12)).foregroundStyle(Theme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(LinearGradient(colors: [Color(hex: 0x3A1E10), Color(hex: 0x20130A)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.amber.opacity(0.22)))
    }
}

/// Full detail for one event: hero, about, competing lineup, and judges.
struct EventDetailView: View {
    @Environment(JointStore.self) private var store
    let event: Event
    @State private var selected: Joint?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                hero
                aboutCard
                if !event.lineup.isEmpty {
                    Text(lineupTitle).font(Theme.serif(16)).foregroundStyle(Theme.ink).padding(.top, 4)
                    ForEach(event.lineup) { p in participantRow(p) }
                }
                if !event.panel.isEmpty {
                    Text("Judges").font(Theme.serif(16)).foregroundStyle(Theme.ink).padding(.top, 8)
                    judgesCard
                }
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(event.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selected) { JointDetailView(joint: $0) }
    }

    private var lineupTitle: String {
        event.panel.isEmpty ? "Who's pouring smoke" : "Competing pitmasters"
    }

    private func joint(for name: String) -> Joint? {
        store.joints.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    @ViewBuilder
    private func participantRow(_ p: Event.Participant) -> some View {
        if let j = joint(for: p.name) {
            JointRow(joint: j).onTapGesture { selected = j }
        } else {
            HStack(spacing: 10) {
                Image(systemName: "flame.fill").font(.system(size: 13)).foregroundStyle(Theme.ember)
                VStack(alignment: .leading, spacing: 2) {
                    Text(p.name).font(Theme.serif(15)).foregroundStyle(Theme.ink)
                    if let note = p.note {
                        Text(note).font(.system(size: 10.5, weight: .semibold)).foregroundStyle(Theme.amber)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 13)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line))
        }
    }

    private var judgesCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(event.panel.enumerated()), id: \.element.id) { i, judge in
                HStack(spacing: 10) {
                    Image(systemName: "star.circle.fill").font(.system(size: 15)).foregroundStyle(Theme.amber)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(judge.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.ink)
                        if let aff = judge.affiliation {
                            Text(aff).font(.system(size: 11)).foregroundStyle(Theme.muted)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 10)
                if i < event.panel.count - 1 {
                    Rectangle().frame(height: 1).foregroundStyle(Theme.line)
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 4)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line))
    }

    private var hero: some View {
        let ticket = event.ticketURL.flatMap(URL.init(string:))
        return VStack(spacing: 8) {
            if let tagline = event.tagline {
                Text(tagline.uppercased()).font(.system(size: 10, weight: .bold)).tracking(3)
                    .foregroundStyle(Theme.amber)
            }
            Text(event.name).font(Theme.serif(30)).foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            if !event.whenLine.isEmpty {
                Text(event.whenLine).font(.system(size: 12.5, weight: .semibold)).foregroundStyle(Theme.ink)
            }
            if let venue = event.venue {
                Text([venue, event.address].compactMap { $0 }.joined(separator: "\n"))
                    .font(.system(size: 12)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
            }
            if let ticket {
                Link(destination: ticket) {
                    Text("Get tickets").font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                        .padding(.horizontal, 26).padding(.vertical, 13)
                        .background(Theme.ember, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity).padding(20)
        .background(LinearGradient(colors: [Color(hex: 0x3A1E10), Color(hex: 0x20130A)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.amber.opacity(0.25)))
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("About", systemImage: "info.circle.fill")
                .font(Theme.serif(17)).foregroundStyle(Theme.ink)
            Text(event.about ?? "An event from the Houston BBQ Guide. This app is your companion — see who's taking part, plan your visit, and check the joints you've tried off your passport.")
                .font(.system(size: 13)).lineSpacing(3).foregroundStyle(Color(hex: 0xCDBFA8))
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line))
    }
}
