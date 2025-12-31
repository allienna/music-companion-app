import Foundation

// MARK: - Lyrics Provider Protocol

protocol LyricsProvider {
    var source: LyricsSource { get }
    var priority: Int { get }

    func fetchLyrics(for query: LyricsSearchQuery) async throws -> Lyrics
    func isAvailable() -> Bool
}

extension LyricsProvider {
    func isAvailable() -> Bool { true }
}
