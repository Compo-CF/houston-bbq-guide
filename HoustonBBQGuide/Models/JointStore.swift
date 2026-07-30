import Foundation
import CoreLocation
import Observation

@Observable
final class JointStore {
    var joints: [Joint] = []
    var taxonomies: [String: [String]] = [:]
    var filter = JointFilter()
    var userLocation: CLLocation?

    /// Remote source of truth. Edit `docs/Joints.json` in the repo, push to main,
    /// and GitHub Pages serves it — every app picks it up on next launch. No app
    /// release is needed for data-only changes (new joints, updated hours).
    /// Until the Pages site is live this silently no-ops and the bundled seed is used.
    private let remoteURL = URL(string: "https://compo-cf.github.io/houston-bbq-guide/Joints.json")!

    private var cacheURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("Joints.cache.json")
    }

    init() {
        loadLocalFirst()
        Task { await refreshFromRemote() }
    }

    /// Load the best local data we have so the UI is never empty: prefer the
    /// cached remote copy from a previous launch, else the bundled seed.
    private func loadLocalFirst() {
        if let cached = try? Data(contentsOf: cacheURL), let file = Self.decode(cached) {
            apply(file)
            return
        }
        loadBundled()
    }

    private func loadBundled() {
        guard let url = Bundle.main.url(forResource: "Joints", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = Self.decode(data) else {
            print("Bundled Joints.json missing or invalid")
            return
        }
        apply(file)
    }

    @MainActor
    func refreshFromRemote() async {
        var request = URLRequest(url: remoteURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let file = Self.decode(data), !file.joints.isEmpty
            else { return }
            apply(file)
            try? data.write(to: cacheURL, options: .atomic)
        } catch {
            // Offline or fetch failed — keep the local data from loadLocalFirst().
        }
    }

    private func apply(_ file: JointsFile) {
        joints = file.joints
        taxonomies = file.taxonomies
    }

    private static func decode(_ data: Data) -> JointsFile? {
        try? JSONDecoder().decode(JointsFile.self, from: data)
    }

    // MARK: Filtering

    func filtered() -> [Joint] {
        joints.filter { j in
            filter.styles.isSubset(of: Set(j.styles))
                && filter.pitTypes.isSubset(of: Set(j.primaryPitType))
                && filter.woods.isSubset(of: Set(j.primaryWood))
                && filter.areas.isSubset(of: Set(j.neighborhood))
                && filter.meals.isSubset(of: Set(j.mealsServed))
                && filter.features.isSubset(of: Set(j.features))
                && (filter.searchText.isEmpty
                    || j.name.localizedCaseInsensitiveContains(filter.searchText))
        }
    }

    /// Filtered joints, sorted by distance when the user's location is known.
    func sorted() -> [Joint] {
        let list = filtered()
        guard let userLocation else { return list }
        return list.sorted { $0.distance(from: userLocation) < $1.distance(from: userLocation) }
    }
}

/// Faceted filter state. Each set is AND-ed: a joint must carry every selected
/// value within a facet to survive (mirrors the website's filter behavior).
struct JointFilter {
    var styles: Set<String> = []
    var pitTypes: Set<String> = []
    var woods: Set<String> = []
    var areas: Set<String> = []
    var meals: Set<String> = []
    var features: Set<String> = []
    var searchText: String = ""

    var activeCount: Int {
        styles.count + pitTypes.count + woods.count + areas.count + meals.count + features.count
    }

    mutating func clear() { self = JointFilter() }

    /// Facet identifiers match the taxonomy keys in Joints.json.
    func isSelected(_ facet: String, _ value: String) -> Bool {
        set(for: facet).contains(value)
    }

    mutating func toggle(_ facet: String, _ value: String) {
        switch facet {
        case "styles":            Self.flip(&styles, value)
        case "primary-pit-type":  Self.flip(&pitTypes, value)
        case "primary-wood":      Self.flip(&woods, value)
        case "neighborhood":      Self.flip(&areas, value)
        case "meals-served":      Self.flip(&meals, value)
        case "features":          Self.flip(&features, value)
        default: break
        }
    }

    private func set(for facet: String) -> Set<String> {
        switch facet {
        case "styles": return styles
        case "primary-pit-type": return pitTypes
        case "primary-wood": return woods
        case "neighborhood": return areas
        case "meals-served": return meals
        case "features": return features
        default: return []
        }
    }

    /// Static so it borrows only the passed-in set, not `self` — otherwise the
    /// call and the `&self.<facet>` argument would be overlapping accesses to self.
    private static func flip(_ s: inout Set<String>, _ v: String) {
        if s.contains(v) { s.remove(v) } else { s.insert(v) }
    }
}
