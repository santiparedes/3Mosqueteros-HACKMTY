import SwiftUI

extension Color {
    // Original Blue Color Scheme
    static let nepBlue = Color(red: 0.0, green: 0.3, blue: 0.8)
    static let nepLightBlue = Color(red: 0.2, green: 0.5, blue: 0.9)
    static let nepDarkBlue = Color(red: 0.0, green: 0.2, blue: 0.6)
    
    // Background Colors
    static let nepBackground = Color(red: 0.95, green: 0.97, blue: 1.0)
    static let nepCardBackground = Color(red: 0.98, green: 0.99, blue: 1.0)
    static let nepDarkBackground = Color(red: 0.1, green: 0.1, blue: 0.15)
    
    // Text Colors
    static let nepTextPrimary = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let nepTextSecondary = Color(red: 0.4, green: 0.4, blue: 0.4)
    static let nepTextLight = Color.white
    
    // Accent Colors
    static let nepAccent = Color(red: 0.0, green: 0.7, blue: 0.3)
    static let nepWarning = Color(red: 0.9, green: 0.6, blue: 0.0)
    static let nepError = Color(red: 0.8, green: 0.2, blue: 0.2)
    
    // Semantic color mappings
    static let primary = nepBlue
    static let primaryLight = nepLightBlue
    static let primaryDark = nepDarkBlue
    static let background = nepBackground
    static let surface = nepCardBackground
    static let darkBackground = nepDarkBackground
    static let onBackground = nepTextPrimary
    static let onSurface = nepTextSecondary
    static let onDark = nepTextLight
    static let success = nepAccent
    static let warning = nepWarning
    static let error = nepError
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
