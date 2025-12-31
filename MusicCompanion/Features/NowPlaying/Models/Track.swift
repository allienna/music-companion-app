import Foundation

struct Track: Identifiable, Equatable, Hashable {
    let id: String
    let title: String
    let artist: String
    let album: String?
    let duration: TimeInterval
    let artworkData: Data?
    let artworkURL: URL?
    let source: MusicSource

    init(
        id: String,
        title: String,
        artist: String,
        album: String? = nil,
        duration: TimeInterval = 0,
        artworkData: Data? = nil,
        artworkURL: URL? = nil,
        source: MusicSource
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.artworkData = artworkData
        self.artworkURL = artworkURL
        self.source = source
    }
}

enum MusicSource: String, Codable, CaseIterable {
    case appleMusic = "Apple Music"
    case spotify = "Spotify"
    case unknown = "Unknown"

    var iconName: String {
        switch self {
        case .appleMusic: "music.note"
        case .spotify: "music.note.list"
        case .unknown: "questionmark.circle"
        }
    }
}

enum PlaybackState: String, Codable {
    case playing
    case paused
    case stopped

    var isActive: Bool {
        self == .playing || self == .paused
    }
}
