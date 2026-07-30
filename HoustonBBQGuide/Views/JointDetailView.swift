import SwiftUI

struct JointDetailView: View {
    @Environment(PassportStore.self) private var passport
    @Environment(\.dismiss) private var dismiss
    let joint: Joint

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                    VStack(alignment: .leading, spacing: 14) {
                        Text(joint.name).font(Theme.serif(26))
                            .foregroundStyle(Theme.ink)
                        if let address = joint.address {
                            Link(destination: mapsURL) {
                                Label(address, systemImage: "mappin.and.ellipse")
                                    .font(.system(size: 12.5))
                                    .foregroundStyle(Theme.amber)
                            }
                        }
                        if !joint.accolades.isEmpty {
                            FlowLayout(spacing: 6) {
                                ForEach(joint.accolades, id: \.self) { BadgeChip(text: $0) }
                            }
                        }
                        if !joint.description.isEmpty {
                            Text(joint.description)
                                .font(.system(size: 14)).lineSpacing(4)
                                .foregroundStyle(Color(hex: 0xD9CBB4))
                        }
                        facets
                        if !joint.features.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                facetLabel("GOOD TO KNOW")
                                FlowLayout(spacing: 6) {
                                    ForEach(joint.features, id: \.self) { TagChip(text: $0) }
                                }
                            }
                        }
                        links
                        eatButton
                    }
                    .padding(.horizontal, 18).padding(.top, 14).padding(.bottom, 30)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill") }
                        .foregroundStyle(Theme.muted)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var hero: some View {
        AsyncImage(url: joint.imageURL()) { phase in
            switch phase {
            case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
            default: Theme.surface2
            }
        }
        .frame(height: 210).frame(maxWidth: .infinity).clipped()
        .overlay(LinearGradient(colors: [.clear, Theme.bg],
                                startPoint: .center, endPoint: .bottom))
    }

    private var facets: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
            facet("Style", joint.styles)
            facet("Pit", joint.primaryPitType)
            facet("Wood", joint.primaryWood)
            facet("Meals", joint.mealsServed)
            facet("Catering", joint.catering)
            facet("Drinks", joint.drinks)
        }
    }

    @ViewBuilder private func facet(_ key: String, _ values: [String]) -> some View {
        if !values.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                facetLabel(key.uppercased())
                Text(values.joined(separator: ", "))
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.ink)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line))
        }
    }

    private func facetLabel(_ t: String) -> some View {
        Text(t).font(.system(size: 9, weight: .semibold)).tracking(1.6)
            .foregroundStyle(Theme.muted2)
    }

    private var links: some View {
        FlowLayout(spacing: 8) {
            if let w = joint.website ?? joint.links.website { linkButton("Website", w, "globe") }
            if let ig = joint.links.instagram { linkButton("Instagram", ig, "camera") }
            if let c = joint.links.chronicle { linkButton("Chronicle review", c, "newspaper", press: true) }
            if let tm = joint.links.texasmonthly { linkButton("Texas Monthly", tm, "star", press: true) }
            if let yt = joint.links.youtube { linkButton("Video", yt, "play.fill") }
        }
    }

    private func linkButton(_ title: String, _ urlStr: String, _ symbol: String, press: Bool = false) -> some View {
        Group {
            if let url = URL(string: urlStr) {
                Link(destination: url) {
                    Label(title, systemImage: symbol)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(press ? Theme.amber : Theme.ink)
                        .padding(.horizontal, 13).padding(.vertical, 8)
                        .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(press ? Theme.amber.opacity(0.3) : Theme.line))
                }
            }
        }
    }

    private var eatButton: some View {
        let done = passport.isVisited(joint.id)
        return Button {
            withAnimation { passport.toggle(joint.id) }
        } label: {
            Label(done ? "You've eaten here" : "Mark as eaten",
                  systemImage: done ? "checkmark.circle.fill" : "flame.fill")
                .font(.system(size: 15, weight: .bold))
                .frame(maxWidth: .infinity).padding(15)
                .background(done ? Theme.good : Theme.ember, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
        }
        .padding(.top, 4)
    }

    private var mapsURL: URL {
        let q = (joint.address ?? joint.name).addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "http://maps.apple.com/?q=\(q)")!
    }
}
