import SwiftUI

/// The field-guide "smoked" palette — deliberately unlike a tier-list or a
/// generic restaurant app. Warm charcoal grounds, ember + amber accents.
enum Theme {
    static let bg      = Color(hex: 0x16100B)
    static let surface = Color(hex: 0x20180F)
    static let surface2 = Color(hex: 0x2A2017)
    static let ember   = Color(hex: 0xE2622F)
    static let amber   = Color(hex: 0xE8A54A)
    static let ink     = Color(hex: 0xEFE4D2)
    static let muted   = Color(hex: 0xA48F72)
    static let muted2  = Color(hex: 0x7D6B53)
    static let good    = Color(hex: 0x7BA05B)
    static let line    = Color.white.opacity(0.10)

    /// Serif "field guide" display face using the system serif design.
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
