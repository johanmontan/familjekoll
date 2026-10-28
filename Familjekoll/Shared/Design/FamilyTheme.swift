import SwiftUI

enum FamilyTheme {
    static let background = adaptive(
        light: UIColor(red: 0.96, green: 0.95, blue: 0.92, alpha: 1),
        dark: UIColor(red: 0.075, green: 0.086, blue: 0.10, alpha: 1)
    )

    static let surface = adaptive(
        light: UIColor(white: 1, alpha: 0.94),
        dark: UIColor(red: 0.12, green: 0.14, blue: 0.17, alpha: 0.98)
    )

    static let ink = adaptive(
        light: UIColor(red: 0.12, green: 0.14, blue: 0.18, alpha: 1),
        dark: UIColor(red: 0.95, green: 0.95, blue: 0.92, alpha: 1)
    )

    static let secondaryInk = adaptive(
        light: UIColor(red: 0.36, green: 0.38, blue: 0.42, alpha: 1),
        dark: UIColor(red: 0.69, green: 0.71, blue: 0.74, alpha: 1)
    )

    static let accent = adaptive(
        light: UIColor(red: 0.20, green: 0.48, blue: 0.40, alpha: 1),
        dark: UIColor(red: 0.39, green: 0.78, blue: 0.66, alpha: 1)
    )

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}
