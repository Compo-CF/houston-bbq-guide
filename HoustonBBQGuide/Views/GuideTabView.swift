import SwiftUI

/// The editorial layer — HOUBBQ 101. Styles, pits, woods, and the essentials,
/// all with live counts derived from the current dataset.
struct GuideTabView: View {
    @Environment(JointStore.self) private var store
    @State private var selected: Joint?

    private let styleBlurbs: [(String, String)] = [
        ("Central Texas", "Salt-and-pepper rubs, oak-fired offset pits, brisket as the star. The Franklin lineage."),
        ("East Texas", "Tender and saucy, often chopped. Beef and pork, hickory smoke, sweet tomato-based sauce."),
        ("Combination", "Joints that refuse to pick a lane — blending Central and East Texas traditions."),
        ("Creative/Elevated", "Chef-driven barbecue: house sausages, global spices, seasonal sides."),
        ("Tex-Mex-Influenced", "Barbacoa, brisket tacos, and border flavors on the smoker."),
        ("Asian-Influenced", "Houston's diversity on a plate — Vietnamese, Korean, and Chinese notes in the smoke."),
        ("Old-School", "Decades-old pitrooms doing it the way they always have. Direct heat, no fuss."),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    header
                    styleCard
                    countCard(title: "Pit Types", symbol: "hammer.fill",
                              taxonomy: "primary-pit-type", field: \.primaryPitType)
                    countCard(title: "The Woods", symbol: "tree.fill",
                              taxonomy: "primary-wood", field: \.primaryWood)
                    essentialCard
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
            Text("HOUBBQ 101").font(.system(size: 10, weight: .bold)).tracking(2.4)
                .foregroundStyle(Theme.ember)
            Text("The Field Guide").font(Theme.serif(25)).foregroundStyle(Theme.ink)
            Text("Learn the styles, pits, and woods behind Houston's barbecue — then go taste the difference.")
                .font(.system(size: 12.5)).foregroundStyle(Theme.muted)
        }
        .padding(.bottom, 4)
    }

    private var styleCard: some View {
        GuideCard(title: "The Styles", symbol: "flame.fill") {
            ForEach(styleBlurbs, id: \.0) { style, blurb in
                let n = store.joints.filter { $0.styles.contains(style) }.count
                DefRow(term: style, detail: "\(blurb) (\(n) joints)")
            }
        }
    }

    private func countCard(title: String, symbol: String, taxonomy: String,
                           field: KeyPath<Joint, [String]>) -> some View {
        GuideCard(title: title, symbol: symbol) {
            ForEach(store.taxonomies[taxonomy] ?? [], id: \.self) { opt in
                let n = store.joints.filter { $0[keyPath: field].contains(opt) }.count
                DefRow(term: opt, detail: "\(n) joints")
            }
        }
    }

    private var essentialCard: some View {
        let essentials = store.joints.filter { $0.isEssential }
        return GuideCard(title: "Essential Houston", symbol: "star.fill") {
            Text("If you only hit a few, make it these \(essentials.count).")
                .font(.system(size: 13)).foregroundStyle(Color(hex: 0xCDBFA8))
                .padding(.bottom, 4)
            ForEach(essentials) { j in
                Button { selected = j } label: {
                    DefRow(term: j.name, detail: j.styles.joined(separator: ", "))
                }
            }
        }
    }
}

private struct GuideCard<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(Theme.serif(17)).foregroundStyle(Theme.ink)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line))
    }
}

private struct DefRow: View {
    let term: String
    let detail: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(term).font(Theme.serif(13)).foregroundStyle(Theme.amber)
                .frame(width: 118, alignment: .leading)
            Text(detail).font(.system(size: 12.5)).foregroundStyle(Color(hex: 0xCDBFA8))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(Theme.line), alignment: .top)
    }
}
