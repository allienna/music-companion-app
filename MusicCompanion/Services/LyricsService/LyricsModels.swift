import Foundation

// MARK: - Lyrics Line

struct LyricsLine: Identifiable, Equatable {
    let id = UUID()
    let startTime: TimeInterval
    let endTime: TimeInterval?
    let text: String
    let words: [LyricsWord]?

    init(startTime: TimeInterval, endTime: TimeInterval? = nil, text: String, words: [LyricsWord]? = nil) {
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
        self.words = words
    }
}

// MARK: - Lyrics Word (for word-by-word sync)

struct LyricsWord: Identifiable, Equatable {
    let id = UUID()
    let startTime: TimeInterval
    let endTime: TimeInterval
    let text: String
}

// MARK: - Lyrics

struct Lyrics: Equatable {
    let trackId: String
    let trackTitle: String
    let artistName: String
    let lines: [LyricsLine]
    let isSynced: Bool
    let source: LyricsSource

    var plainText: String {
        lines.map { $0.text }.joined(separator: "\n")
    }
}

// MARK: - Lyrics Source

enum LyricsSource: String, Codable {
    case lrclib
    case spotify
    case musixmatch
    case local
    case unknown
}

// MARK: - Lyrics Search Query

struct LyricsSearchQuery {
    let title: String
    let artist: String
    let album: String?
    let duration: TimeInterval?

    init(track: Track) {
        self.title = track.title
        self.artist = track.artist
        self.album = track.album
        self.duration = track.duration
    }

    init(title: String, artist: String, album: String? = nil, duration: TimeInterval? = nil) {
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
    }
}

// MARK: - Lyrics Error

enum LyricsError: Error, LocalizedError {
    case notFound
    case networkError(Error)
    case parseError(String)
    case rateLimited
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Lyrics not found"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parseError(let message):
            return "Parse error: \(message)"
        case .rateLimited:
            return "Rate limited, please try again later"
        case .invalidResponse:
            return "Invalid response from lyrics provider"
        }
    }
}
