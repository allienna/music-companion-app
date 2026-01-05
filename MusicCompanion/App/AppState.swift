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
    @Published var showLyrics: Bool = false
    @Published var menuBarSettings: MenuBarSettings = .default {
        didSet {
            saveMenuBarSettings()
        }
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let menuBarSettings = "menuBarSettings"
    }

    private init() {
        musicServiceManager = MusicServiceManager()
        loadMenuBarSettings()
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

    // MARK: - Settings Persistence

    private func loadMenuBarSettings() {
        guard let data = UserDefaults.standard.data(forKey: Keys.menuBarSettings),
              let settings = try? JSONDecoder().decode(MenuBarSettings.self, from: data)
        else {
            return
        }
        menuBarSettings = settings
    }

    private func saveMenuBarSettings() {
        guard let data = try? JSONEncoder().encode(menuBarSettings) else {
            return
        }
        UserDefaults.standard.set(data, forKey: Keys.menuBarSettings)
    }
}
