import Foundation
import Observation

/// Tracks which joints the user has eaten at. Persisted in UserDefaults — the
/// passport is a personal, on-device journal (no account, no sync in v1).
@Observable
final class PassportStore {
    private(set) var visited: Set<Int> = []
    private let key = "houbbq_visited"

    init() {
        if let saved = UserDefaults.standard.array(forKey: key) as? [Int] {
            visited = Set(saved)
        }
    }

    func isVisited(_ id: Int) -> Bool { visited.contains(id) }

    func toggle(_ id: Int) {
        if visited.contains(id) { visited.remove(id) } else { visited.insert(id) }
        UserDefaults.standard.set(Array(visited), forKey: key)
    }

    var count: Int { visited.count }

    func progress(of total: Int) -> Double {
        total == 0 ? 0 : Double(count) / Double(total)
    }

    /// Compute earned badges against the full joint list.
    func badges(all: [Joint]) -> [Badge] {
        func allVisited(_ subset: [Joint]) -> Bool {
            !subset.isEmpty && subset.allSatisfy { visited.contains($0.id) }
        }
        let michelin = all.filter { $0.michelinAccolade != nil }
        let centralTX = all.filter { $0.styles.contains("Central Texas") }
        return [
            Badge("First Bite", "Visit 1 joint", "leaf.fill", count >= 1),
            Badge("Fiver", "Visit 5 joints", "flame", count >= 5),
            Badge("Pitmaster", "Visit 15 joints", "flame.fill", count >= 15),
            Badge("Completionist", "Visit all \(all.count)", "trophy.fill", !all.isEmpty && count >= all.count),
            Badge("Central TX Tour", "All Central Texas", "map.fill", allVisited(centralTX)),
            Badge("Michelin Run", "All Recognized Joints", "star.fill", allVisited(michelin)),
        ]
    }
}

struct Badge: Identifiable {
    let id = UUID()
    let title: String
    let requirement: String
    let symbol: String
    let earned: Bool

    init(_ title: String, _ requirement: String, _ symbol: String, _ earned: Bool) {
        self.title = title
        self.requirement = requirement
        self.symbol = symbol
        self.earned = earned
    }
}
