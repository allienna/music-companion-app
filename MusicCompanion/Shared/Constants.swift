import Foundation

enum Constants {
    enum App {
        static let name = "Music Companion"
        static let bundleIdentifier = "com.allienna.MusicCompanion"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    enum UI {
        static let popoverWidth: CGFloat = 320
        static let popoverHeight: CGFloat = 400
        static let miniPlayerMinWidth: CGFloat = 200
        static let miniPlayerMinHeight: CGFloat = 80
        static let artworkCornerRadius: CGFloat = 12
        static let animationDuration: Double = 0.25
    }

    enum Spotify {
        static let clientId = "" // Set in release builds
        static let redirectUri = "music-companion://spotify-callback"
        static let scopes = [
            "user-read-playback-state",
            "user-modify-playback-state",
            "user-read-currently-playing",
            "user-library-read",
            "user-library-modify"
        ]
    }

    enum LastFM {
        static let apiKey = "" // Set in release builds
        static let apiSecret = "" // Set in release builds
    }

    enum NotificationNames {
        static let trackChanged = Notification.Name("MusicCompanion.trackChanged")
        static let playbackStateChanged = Notification.Name("MusicCompanion.playbackStateChanged")
    }
}
