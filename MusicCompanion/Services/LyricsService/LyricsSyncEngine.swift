import Combine
import Foundation

// MARK: - Lyrics Sync Engine

@MainActor
final class LyricsSyncEngine: ObservableObject {
    @Published private(set) var currentLineIndex: Int?
    @Published private(set) var currentLine: LyricsLine?
    @Published private(set) var upcomingLines: [LyricsLine] = []

    private var lyrics: Lyrics?
    private let upcomingLineCount = 3

    // MARK: - Public Methods

    func setLyrics(_ lyrics: Lyrics?) {
        self.lyrics = lyrics
        currentLineIndex = nil
        currentLine = nil
        upcomingLines = []

        if let lyrics, !lyrics.lines.isEmpty {
            updateUpcomingLines(from: 0)
        }
    }

    func updatePosition(_ position: TimeInterval) {
        guard let lyrics, lyrics.isSynced else { return }

        let newIndex = findCurrentLineIndex(at: position, in: lyrics.lines)

        if newIndex != currentLineIndex {
            currentLineIndex = newIndex
            currentLine = newIndex != nil ? lyrics.lines[newIndex!] : nil
            updateUpcomingLines(from: (newIndex ?? -1) + 1)
        }
    }

    func reset() {
        lyrics = nil
        currentLineIndex = nil
        currentLine = nil
        upcomingLines = []
    }

    // MARK: - Private Methods

    private func findCurrentLineIndex(at position: TimeInterval, in lines: [LyricsLine]) -> Int? {
        // Find the line that contains the current position
        for (index, line) in lines.enumerated() {
            let endTime = line.endTime ?? (index < lines.count - 1 ? lines[index + 1].startTime : .infinity)

            if position >= line.startTime && position < endTime {
                return index
            }
        }

        // If we're before the first line
        if let firstLine = lines.first, position < firstLine.startTime {
            return nil
        }

        // If we're after the last line, return the last line
        if let lastIndex = lines.indices.last {
            return lastIndex
        }

        return nil
    }

    private func updateUpcomingLines(from startIndex: Int) {
        guard let lyrics else {
            upcomingLines = []
            return
        }

        let endIndex = min(startIndex + upcomingLineCount, lyrics.lines.count)
        if startIndex < lyrics.lines.count {
            upcomingLines = Array(lyrics.lines[startIndex ..< endIndex])
        } else {
            upcomingLines = []
        }
    }
}
