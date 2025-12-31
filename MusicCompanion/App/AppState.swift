import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    // MARK: - Services

    let musicServiceManager: MusicServiceManager

    // MARK: - Published State

    @Published private(set) var currentTrack: Track?
    @Published private(set) var playbackState: PlaybackState = .stopped
    @Published private(set) var playbackPosition: TimeInterval = 0

    // MARK: - Settings

    @Published var showInMenuBar: Bool = true
    @Published var showNotchPlayer: Bool = true
    @Published var showMiniPlayer: Bool = false
    @Published var menuBarSettings: MenuBarSettings = .default

    private var cancellables = Set<AnyCancellable>()

    private init() {
        musicServiceManager = MusicServiceManager()
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        musicServiceManager.currentTrack
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentTrack)

        musicServiceManager.playbackState
            .receive(on: DispatchQueue.main)
            .assign(to: &$playbackState)

        musicServiceManager.playbackPosition
            .receive(on: DispatchQueue.main)
            .assign(to: &$playbackPosition)
    }
}
