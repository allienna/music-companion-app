import Foundation

/// Settings for the menu bar display behavior
struct MenuBarSettings: Codable, Equatable {
    /// Whether to use a fixed width with marquee scrolling
    var useFixedWidth: Bool = false

    /// The fixed width in points when useFixedWidth is enabled
    var fixedWidth: CGFloat = 200

    /// Default settings
    static let `default` = MenuBarSettings()
}
