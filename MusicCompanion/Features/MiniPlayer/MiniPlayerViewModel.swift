import Combine
import Foundation

@MainActor
final class MiniPlayerViewModel: ObservableObject {
    @Published private(set) var currentTrack: Track?
    @Published private(set) var isPlaying = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var elapsedTimeString = "0:00"
    @Published private(set) var remainingTimeString = "-0:00"

    private var cancellables = Set<AnyCancellable>()
    private let musicServiceManager: MusicServiceManager

    init() {
        musicServiceManager = AppState.shared.musicServiceManager
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        AppState.shared.$currentTrack
            .assign(to: &$currentTrack)

        AppState.shared.$playbackState
            .map { $0 == .playing }
            .assign(to: &$isPlaying)

        AppState.shared.$playbackPosition
            .combineLatest(AppState.shared.$currentTrack)
            .sink { [weak self] position, track in
                self?.updateProgress(position: position, duration: track?.duration ?? 0)
            }
            .store(in: &cancellables)
    }

    private func updateProgress(position: TimeInterval, duration: TimeInterval) {
        guard duration > 0 else {
            progress = 0
            elapsedTimeString = "0:00"
            remainingTimeString = "-0:00"
            return
        }

        progress = position / duration
        elapsedTimeString = formatTime(position)
        remainingTimeString = "-\(formatTime(duration - position))"
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Playback Controls

    func togglePlayPause() {
        Task {
            do {
                if isPlaying {
                    try await musicServiceManager.pause()
                } else {
                    try await musicServiceManager.play()
                }
            } catch {
                print("Playback control error: \(error)")
            }
        }
    }

    func nextTrack() {
        Task {
            try? await musicServiceManager.nextTrack()
        }
    }

    func previousTrack() {
        Task {
            try? await musicServiceManager.previousTrack()
        }
    }

    func seek(to progress: Double) {
        guard let duration = currentTrack?.duration else { return }
        let position = duration * progress
        Task {
            try? await musicServiceManager.seek(to: position)
        }
    }
}
