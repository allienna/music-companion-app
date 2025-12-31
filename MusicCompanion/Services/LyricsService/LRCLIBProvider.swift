import Foundation
import os.log

private let logger = Logger(subsystem: "com.allienna.musiccompanion", category: "LRCLIBProvider")

// MARK: - LRCLIB Provider

final class LRCLIBProvider: LyricsProvider {
    let source: LyricsSource = .lrclib
    let priority: Int = 100

    private let baseURL = "https://lrclib.net/api"
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.httpAdditionalHeaders = [
            "User-Agent": "MusicCompanion/1.0 (https://github.com/allienna/music-companion-app)"
        ]
        self.session = URLSession(configuration: config)
    }

    func fetchLyrics(for query: LyricsSearchQuery) async throws -> Lyrics {
        // Build URL with query parameters
        var components = URLComponents(string: "\(baseURL)/get")!
        var queryItems = [
            URLQueryItem(name: "artist_name", value: query.artist),
            URLQueryItem(name: "track_name", value: query.title)
        ]

        if let album = query.album, !album.isEmpty {
            queryItems.append(URLQueryItem(name: "album_name", value: album))
        }

        if let duration = query.duration {
            queryItems.append(URLQueryItem(name: "duration", value: String(Int(duration))))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw LyricsError.invalidResponse
        }

        logger.info("Fetching lyrics from LRCLIB: \(url.absoluteString)")

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LyricsError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            return try parseResponse(data, query: query)
        case 404:
            throw LyricsError.notFound
        case 429:
            throw LyricsError.rateLimited
        default:
            logger.error("LRCLIB returned status code: \(httpResponse.statusCode)")
            throw LyricsError.invalidResponse
        }
    }

    private func parseResponse(_ data: Data, query: LyricsSearchQuery) throws -> Lyrics {
        let response = try JSONDecoder().decode(LRCLIBResponse.self, from: data)

        // Prefer synced lyrics, fall back to plain lyrics
        let lyricsText = response.syncedLyrics ?? response.plainLyrics
        guard let lyricsText, !lyricsText.isEmpty else {
            throw LyricsError.notFound
        }

        let isSynced = response.syncedLyrics != nil
        let lines = isSynced ? parseSyncedLyrics(lyricsText) : parsePlainLyrics(lyricsText)

        return Lyrics(
            trackId: "\(response.id)",
            trackTitle: response.trackName,
            artistName: response.artistName,
            lines: lines,
            isSynced: isSynced,
            source: .lrclib
        )
    }

    // MARK: - LRC Parsing

    private func parseSyncedLyrics(_ lrc: String) -> [LyricsLine] {
        var lines: [LyricsLine] = []
        let pattern = #"\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)$"#

        for line in lrc.components(separatedBy: .newlines) {
            guard let match = line.range(of: pattern, options: .regularExpression) else {
                continue
            }

            let matchedLine = String(line[match])
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let result = regex.firstMatch(in: matchedLine, range: NSRange(matchedLine.startIndex..., in: matchedLine))
            else {
                continue
            }

            let minutesRange = Range(result.range(at: 1), in: matchedLine)!
            let secondsRange = Range(result.range(at: 2), in: matchedLine)!
            let millisecondsRange = Range(result.range(at: 3), in: matchedLine)!
            let textRange = Range(result.range(at: 4), in: matchedLine)!

            let minutes = Double(matchedLine[minutesRange])!
            let seconds = Double(matchedLine[secondsRange])!
            var milliseconds = Double(matchedLine[millisecondsRange])!

            // Handle both 2-digit and 3-digit milliseconds
            if matchedLine[millisecondsRange].count == 2 {
                milliseconds *= 10
            }

            let startTime = minutes * 60 + seconds + milliseconds / 1000
            let text = String(matchedLine[textRange]).trimmingCharacters(in: .whitespaces)

            // Skip empty lines
            if !text.isEmpty {
                lines.append(LyricsLine(startTime: startTime, text: text))
            }
        }

        // Sort by start time and calculate end times
        lines.sort { $0.startTime < $1.startTime }

        // Set end times based on next line's start time
        for i in 0 ..< lines.count {
            let endTime = i < lines.count - 1 ? lines[i + 1].startTime : nil
            lines[i] = LyricsLine(
                startTime: lines[i].startTime,
                endTime: endTime,
                text: lines[i].text
            )
        }

        return lines
    }

    private func parsePlainLyrics(_ text: String) -> [LyricsLine] {
        text.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .enumerated()
            .map { index, line in
                LyricsLine(startTime: Double(index), text: line)
            }
    }
}

// MARK: - LRCLIB Response Model

private struct LRCLIBResponse: Decodable {
    let id: Int
    let trackName: String
    let artistName: String
    let albumName: String?
    let duration: Double?
    let instrumental: Bool
    let plainLyrics: String?
    let syncedLyrics: String?
}
