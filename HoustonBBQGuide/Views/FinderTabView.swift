import SwiftUI

struct FinderTabView: View {
    @Environment(JointStore.self) private var store
    @Environment(PassportStore.self) private var passport
    @State private var mode: Mode = .list
    @State private var showFilters = false
    @State private var selected: Joint?

    enum Mode { case list, map }

    private let quickStyles = ["Central Texas", "East Texas", "Combination",
                               "Creative/Elevated", "Tex-Mex-Influenced",
                               "Asian-Influenced", "Old-School"]

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            VStack(spacing: 0) {
                header
                Picker("", selection: $mode) {
                    Text("List").tag(Mode.list)
                    Text("Map").tag(Mode.map)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)

                styleChips

                let results = store.sorted()
                Text("\(results.count) of \(store.joints.count) joints")
                    .font(.caption).foregroundStyle(Theme.muted2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal).padding(.vertical, 4)

                if mode == .list {
                    ScrollView {
                        LazyVStack(spacing: 13) {
                            ForEach(results) { joint in
                                JointRow(joint: joint)
                                    .onTapGesture { selected = joint }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                } else {
                    JointMapView(joints: results, onSelect: { selected = $0 })
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .searchable(text: $store.filter.searchText, prompt: "Search joints")
        .sheet(isPresented: $showFilters) { FilterSheet() }
        .sheet(item: $selected) { JointDetailView(joint: $0) }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            RoundedRectangle(cornerRadius: 9)
                .fill(LinearGradient(colors: [Theme.amber, Theme.ember],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 34, height: 34)
                .overlay(Image(systemName: "flame.fill").foregroundStyle(.white).font(.system(size: 16)))
            VStack(alignment: .leading, spacing: 2) {
                Text("HOUSTON BBQ")
                    .font(Theme.serif(15)).tracking(1.5).foregroundStyle(Theme.ink)
                Text("THE FIELD GUIDE")
                    .font(.system(size: 8.5, weight: .semibold)).tracking(3)
                    .foregroundStyle(Theme.muted)
            }
            Spacer()
        }
        .padding(.horizontal).padding(.top, 8).padding(.bottom, 12)
    }

    private var styleChips: some View {
        @Bindable var store = store
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                Button { showFilters = true } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "line.3.horizontal.decrease")
                        Text("Filters")
                        if store.filter.activeCount > 0 {
                            Text("\(store.filter.activeCount)")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6).padding(.vertical, 1)
                                .background(Theme.ember, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.amber)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .overlay(Capsule().stroke(Theme.amber.opacity(0.4)))
                }
                ForEach(quickStyles, id: \.self) { style in
                    let on = store.filter.styles.contains(style)
                    Button {
                        if on { store.filter.styles.remove(style) }
                        else { store.filter.styles.insert(style) }
                    } label: {
                        Text(style)
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundStyle(on ? Color(hex: 0x1A1008) : Theme.ink)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(on ? Theme.amber : Theme.surface, in: Capsule())
                            .overlay(Capsule().stroke(Theme.line))
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 4)
    }
}
