import SwiftUI

/// The festival module — the app's differentiator. Ticket CTA + the featured
/// pitmaster lineup (joints with festival or Michelin accolades).
struct FestivalTabView: View {
    @Environment(JointStore.self) private var store
    @State private var selected: Joint?

    private let ticketURL = URL(string: "https://houbbqthrowdown2026.eventbrite.com/?aff=guide")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    heroCard
                    aboutCard
                    Text("Featured pitmasters").font(Theme.serif(16))
                        .foregroundStyle(Theme.ink).padding(.top, 4)
                    ForEach(lineup) { j in
                        JointRow(joint: j).onTapGesture { selected = j }
                    }
                }
                .padding()
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: $selected) { JointDetailView(joint: $0) }
    }

    private var lineup: [Joint] {
        store.joints.filter { j in
            j.accolades.contains { $0.contains("HOUBBQ Festival") } || j.michelinAccolade != nil
        }
    }

    private var heroCard: some View {
        VStack(spacing: 8) {
            Text("HOUSTON BBQ THROWDOWN")
                .font(.system(size: 10, weight: .bold)).tracking(3).foregroundStyle(Theme.amber)
            Text("2026 Throwdown").font(Theme.serif(30)).foregroundStyle(Theme.ink)
            Text("The pitmasters. The smoke. One afternoon.\nPresented by the Houston BBQ Guide.")
                .font(.system(size: 12.5)).foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
            Link(destination: ticketURL) {
                Text("Get tickets").font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 26).padding(.vertical, 13)
                    .background(Theme.ember, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity).padding(20)
        .background(LinearGradient(colors: [Color(hex: 0x3A1E10), Color(hex: 0x20130A)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.amber.opacity(0.25)))
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("What is it?", systemImage: "ticket.fill")
                .font(Theme.serif(17)).foregroundStyle(Theme.ink)
            Text("The Houston BBQ Festival & Throwdown gathers the city's best joints for a day of live-fire cooking and tasting. This app is your companion — find participating pitmasters, plan your route, and check them off your passport.")
                .font(.system(size: 13)).lineSpacing(3).foregroundStyle(Color(hex: 0xCDBFA8))
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line))
    }
}
