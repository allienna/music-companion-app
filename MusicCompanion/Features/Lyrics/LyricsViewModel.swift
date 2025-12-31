import Combine
import Foundation

@MainActor
final class LyricsViewModel: ObservableObject {
    @Published private(set) var lyrics: Lyrics?
    @Published private(set) var currentLineIndex: Int?
    @Published private(set) var isLoading = false
    @Published private(set) var hasError = false

    @Published private(set) var currentTrack: Track?
    @Published private(set) var isPlaying = false

    private var cancellables = Set<AnyCancellable>()
    private let lyricsService = LyricsService.shared

    init() {
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        // Lyrics state
        lyricsService.$currentLyrics
            .assign(to: &$lyrics)

        lyricsService.$isLoading
            .assign(to: &$isLoading)

        lyricsService.$error
            .map { $0 != nil }
            .assign(to: &$hasError)

        // Sync engine state
        lyricsService.syncEngine.$currentLineIndex
            .assign(to: &$currentLineIndex)

        // Track state
        AppState.shared.$currentTrack
            .assign(to: &$currentTrack)

        AppState.shared.$playbackState
            .map { $0 == .playing }
            .assign(to: &$isPlaying)
    }

    // MARK: - Actions

    func refreshLyrics() {
        guard let track = currentTrack else { return }
        Task {
            await lyricsService.fetchLyrics(for: track)
        }
    }
}
