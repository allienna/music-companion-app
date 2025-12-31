import Combine
import Foundation
import os.log

private let logger = Logger(subsystem: "com.allienna.musiccompanion", category: "LyricsService")

// MARK: - Lyrics Service

@MainActor
final class LyricsService: ObservableObject {
    static let shared = LyricsService()

    @Published private(set) var currentLyrics: Lyrics?
    @Published private(set) var isLoading = false
    @Published private(set) var error: LyricsError?

    let syncEngine = LyricsSyncEngine()

    private var providers: [LyricsProvider] = []
    private var cache: [String: Lyrics] = [:]
    private var currentTrackId: String?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupProviders()
        setupSubscriptions()
    }

    // MARK: - Setup

    private func setupProviders() {
        // Add providers in priority order
        providers = [
            LRCLIBProvider()
        ]
        providers.sort { $0.priority > $1.priority }
    }

    private func setupSubscriptions() {
        // Subscribe to track changes
        AppState.shared.$currentTrack
            .removeDuplicates { $0?.id == $1?.id }
            .sink { [weak self] track in
                Task { @MainActor in
                    await self?.handleTrackChange(track)
                }
            }
            .store(in: &cancellables)

        // Subscribe to playback position for sync
        AppState.shared.$playbackPosition
            .sink { [weak self] position in
                self?.syncEngine.updatePosition(position)
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func fetchLyrics(for track: Track) async {
        let query = LyricsSearchQuery(track: track)
        await fetchLyrics(for: query, trackId: track.id)
    }

    func clearCache() {
        cache.removeAll()
    }

    // MARK: - Private Methods

    private func handleTrackChange(_ track: Track?) async {
        guard let track else {
            currentLyrics = nil
            syncEngine.setLyrics(nil)
            currentTrackId = nil
            return
        }

        // Skip if same track
        guard track.id != currentTrackId else { return }
        currentTrackId = track.id

        // Check cache first
        if let cached = cache[track.id] {
            logger.info("Using cached lyrics for: \(track.title)")
            currentLyrics = cached
            syncEngine.setLyrics(cached)
            return
        }

        // Fetch new lyrics
        await fetchLyrics(for: track)
    }

    private func fetchLyrics(for query: LyricsSearchQuery, trackId: String) async {
        isLoading = true
        error = nil
        currentLyrics = nil
        syncEngine.setLyrics(nil)

        logger.info("Fetching lyrics for: \(query.title) by \(query.artist)")

        for provider in providers where provider.isAvailable() {
            do {
                let lyrics = try await provider.fetchLyrics(for: query)
                logger.info("Found lyrics from \(provider.source.rawValue)")

                // Cache the result
                cache[trackId] = lyrics

                currentLyrics = lyrics
                syncEngine.setLyrics(lyrics)
                isLoading = false
                return
            } catch let lyricsError as LyricsError {
                logger.warning("Provider \(provider.source.rawValue) failed: \(lyricsError.localizedDescription)")
                continue
            } catch {
                logger.error("Provider \(provider.source.rawValue) error: \(error.localizedDescription)")
                continue
            }
        }

        // No provider found lyrics
        isLoading = false
        self.error = .notFound
        logger.info("No lyrics found for: \(query.title)")
    }
}
