import SwiftUI

/// Full faceted filter, driven entirely by the taxonomies in Joints.json.
struct FilterSheet: View {
    @Environment(JointStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// (display label, taxonomy key in Joints.json)
    private let groups: [(String, String)] = [
        ("Style", "styles"),
        ("Pit type", "primary-pit-type"),
        ("Wood", "primary-wood"),
        ("Area", "neighborhood"),
        ("Meals", "meals-served"),
        ("Features", "features"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(groups, id: \.1) { group in
                        FilterGroup(label: group.0, facet: group.1,
                                    options: store.taxonomies[group.1] ?? [])
                    }
                }
                .padding()
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Filter joints")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear all") { store.filter.clear() }
                        .foregroundStyle(Theme.ember)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Show \(store.filtered().count)") { dismiss() }
                        .fontWeight(.bold).foregroundStyle(Theme.amber)
                }
            }
        }
        .presentationDetents([.large])
    }
}

private struct FilterGroup: View {
    @Environment(JointStore.self) private var store
    let label: String
    let facet: String
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold)).tracking(1.8)
                .foregroundStyle(Theme.muted2)
            FlowLayout(spacing: 7) {
                ForEach(options, id: \.self) { opt in
                    let on = store.filter.isSelected(facet, opt)
                    Button { store.filter.toggle(facet, opt) } label: {
                        Text(opt)
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundStyle(on ? Color(hex: 0x1A1008) : Theme.ink)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(on ? Theme.amber : Theme.surface, in: Capsule())
                            .overlay(Capsule().stroke(Theme.line))
                    }
                }
            }
        }
    }
}

/// Simple wrapping layout for chips (avoids a fixed grid).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
