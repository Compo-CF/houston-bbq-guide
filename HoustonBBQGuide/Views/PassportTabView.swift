import SwiftUI

struct PassportTabView: View {
    @Environment(JointStore.self) private var store
    @Environment(PassportStore.self) private var passport
    @State private var selected: Joint?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    progressCard
                    badgeGrid
                    Text("Your visits").font(Theme.serif(16)).foregroundStyle(Theme.ink)
                        .padding(.top, 6)
                    let visited = store.joints.filter { passport.isVisited($0.id) }
                    if visited.isEmpty {
                        Text("No visits logged yet.\nOpen any joint and tap “Mark as eaten.”")
                            .font(.system(size: 12.5)).foregroundStyle(Theme.muted2)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity).padding(.vertical, 24)
                    } else {
                        ForEach(visited) { j in
                            JointRow(joint: j).onTapGesture { selected = j }
                        }
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("YOUR JOURNEY").font(.system(size: 10, weight: .bold)).tracking(2.4)
                .foregroundStyle(Theme.ember)
            Text("BBQ Passport").font(Theme.serif(25)).foregroundStyle(Theme.ink)
            Text("Check off every joint you've eaten at. Earn badges. Never lose track of a great brisket.")
                .font(.system(size: 12.5)).foregroundStyle(Theme.muted)
        }
    }

    private var progressCard: some View {
        let total = store.joints.count
        let pct = Int(passport.progress(of: total) * 100)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(passport.count)").font(Theme.serif(44))
                Text("/\(total)").font(.system(size: 18)).foregroundStyle(Theme.muted)
            }
            .foregroundStyle(Theme.ink)
            Text("joints conquered").font(.system(size: 12)).foregroundStyle(Theme.muted)
            ProgressView(value: passport.progress(of: total))
                .tint(Theme.amber).padding(.vertical, 4)
            Text("\(pct)% of the guide").font(.system(size: 11)).foregroundStyle(Theme.muted2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(LinearGradient(colors: [Theme.surface2, Theme.surface],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.amber.opacity(0.22)))
    }

    private var badgeGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
            ForEach(passport.badges(all: store.joints)) { badge in
                VStack(spacing: 5) {
                    Image(systemName: badge.symbol).font(.system(size: 24))
                        .foregroundStyle(badge.earned ? Theme.amber : Theme.muted2)
                    Text(badge.title).font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.ink).multilineTextAlignment(.center)
                    Text(badge.requirement).font(.system(size: 9)).foregroundStyle(Theme.muted2)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 12).padding(.horizontal, 6)
                .background(badge.earned ? Theme.surface2 : Theme.surface,
                            in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(badge.earned ? Theme.amber.opacity(0.4) : Theme.line))
                .opacity(badge.earned ? 1 : 0.5)
            }
        }
    }
}
