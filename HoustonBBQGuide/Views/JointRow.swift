import SwiftUI

/// A joint card for the Finder list and the Passport / Events lists.
struct JointRow: View {
    @Environment(PassportStore.self) private var passport
    let joint: Joint

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                photo
                HStack(spacing: 5) { ForEach(accolades, id: \.self) { BadgeChip(text: $0) } }
                    .padding(10)
                if passport.isVisited(joint.id) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(Theme.good, in: Circle())
                        .frame(maxWidth: .infinity, alignment: .topTrailing)
                        .padding(10)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(joint.name).font(Theme.serif(18))
                    .foregroundStyle(Theme.ink).lineLimit(1)
                HStack(spacing: 6) {
                    Label(joint.primaryArea, systemImage: "mappin.circle.fill")
                    if let pit = joint.primaryPitType.first {
                        Text("•"); Text(pit)
                    }
                    if let wood = joint.primaryWood.first {
                        Text("•"); Text("\(wood) wood")
                    }
                }
                .font(.system(size: 11.5)).foregroundStyle(Theme.muted).lineLimit(1)

                if !joint.styles.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 5) {
                            ForEach(joint.styles, id: \.self) { TagChip(text: $0) }
                        }
                    }
                }
            }
            .padding(.horizontal, 13).padding(.top, 10).padding(.bottom, 13)
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line))
    }

    private var accolades: [String] {
        var out: [String] = []
        if let m = joint.michelinAccolade { out.append("⭐︎ " + m.replacingOccurrences(of: "2024 ", with: "")) }
        if joint.accolades.contains(where: { $0.contains("Texas Monthly") }) { out.append("Texas Monthly") }
        else if joint.accolades.contains(where: { $0.contains("Top 100") }) { out.append("Chronicle 100") }
        if joint.isEssential && out.count < 2 { out.append("Essential") }
        return Array(out.prefix(2))
    }

    private var photo: some View {
        AsyncImage(url: joint.imageURL()) { phase in
            switch phase {
            case .success(let img):
                img.resizable().aspectRatio(contentMode: .fill)
            default:
                Theme.surface2.overlay(
                    Image(systemName: "flame")
                        .font(.system(size: 30)).foregroundStyle(Theme.muted2))
            }
        }
        .frame(height: 150).frame(maxWidth: .infinity).clipped()
        .overlay(LinearGradient(colors: [.clear, Theme.bg.opacity(0.55)],
                                startPoint: .center, endPoint: .bottom))
    }
}

struct BadgeChip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 9.5, weight: .bold))
            .foregroundStyle(Theme.amber)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Theme.bg.opacity(0.72), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.amber.opacity(0.35)))
    }
}

struct TagChip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Theme.surface2, in: Capsule())
            .overlay(Capsule().stroke(Theme.line))
    }
}
