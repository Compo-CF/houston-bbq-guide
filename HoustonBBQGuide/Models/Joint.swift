import Foundation
import CoreLocation

/// One barbecue joint, decoded straight from Joints.json (produced by the
/// pipeline that pulls houbbqguide.com's WordPress API). Field names match the
/// JSON exactly so decoding needs no custom keys.
struct Joint: Codable, Identifiable, Hashable {
    let id: Int
    let slug: String
    let name: String
    let url: String
    let description: String
    let excerpt: String
    let image: String?
    let address: String?
    let lat: Double?
    let lng: Double?
    let phone: String?
    let website: String?
    let links: Links

    let styles: [String]
    let neighborhood: [String]
    let daysOpen: [String]
    let buildingType: [String]
    let accolades: [String]
    let catering: [String]
    let primaryWood: [String]
    let primaryPitType: [String]
    let mealsServed: [String]
    let drinks: [String]
    let features: [String]

    struct Links: Codable, Hashable {
        var website: String?
        var chronicle: String?
        var texasmonthly: String?
        var youtube: String?
        var facebook: String?
        var instagram: String?
        var twitter: String?
    }

    // MARK: Derived helpers

    var coordinate: CLLocationCoordinate2D? {
        guard let lat, let lng else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    /// The most specific neighborhood label (skip the broad compass regions).
    var primaryArea: String {
        let broad: Set<String> = ["North", "South", "East", "West", "Central",
                                   "Northwest", "Northeast", "Southwest", "Southeast"]
        return neighborhood.first { !broad.contains($0) } ?? neighborhood.first ?? "Houston"
    }

    var michelinAccolade: String? {
        accolades.first { $0.contains("Michelin") }
    }

    var isEssential: Bool { features.contains("Essential Houston") }

    func distance(from location: CLLocation) -> CLLocationDistance {
        guard let lat, let lng else { return .greatestFiniteMagnitude }
        return CLLocation(latitude: lat, longitude: lng).distance(from: location)
    }

    func imageURL() -> URL? {
        guard let image else { return nil }
        return URL(string: image)
    }
}

/// Top-level shape of Joints.json.
struct JointsFile: Codable {
    let source: String?
    let count: Int?
    let taxonomies: [String: [String]]
    let joints: [Joint]
    let events: [Event]?
}
