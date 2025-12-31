import Combine
import Foundation

@MainActor
final class MenuBarViewModel: ObservableObject {
    @Published private(set) var currentTrack: Track?
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var playbackPosition: TimeInterval = 0

    private var cancellables = Set<AnyCancellable>()

    var progress: Double {
        guard let duration = currentTrack?.duration, duration > 0 else { return 0 }
        return min(playbackPosition / duration, 1.0)
    }

    var elapsedTimeString: String {
        formatTime(playbackPosition)
    }

    var remainingTimeString: String {
        guard let duration = currentTrack?.duration else { return "--:--" }
        return "-\(formatTime(duration - playbackPosition))"
    }

    init() {
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        AppState.shared.$currentTrack
            .assign(to: &$currentTrack)

        AppState.shared.$playbackState
            .map { $0 == .playing }
            .assign(to: &$isPlaying)

        AppState.shared.$playbackPosition
            .assign(to: &$playbackPosition)
    }

    // MARK: - Actions

    func togglePlayPause() {
        Task {
            if isPlaying {
                try? await AppState.shared.musicServiceManager.pause()
            } else {
                try? await AppState.shared.musicServiceManager.play()
            }
        }
    }

    func nextTrack() {
        Task {
            try? await AppState.shared.musicServiceManager.nextTrack()
        }
    }

    func previousTrack() {
        Task {
            try? await AppState.shared.musicServiceManager.previousTrack()
        }
    }

    // MARK: - Helpers

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
