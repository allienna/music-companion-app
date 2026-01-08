import AppKit
import Combine
import Foundation
import ScriptingBridge

final class AppleMusicService: MusicServiceProtocol {
    // MARK: - Properties

    private var musicApp: MusicApplicationProtocol? {
        SBApplication(bundleIdentifier: "com.apple.Music") as MusicApplicationProtocol?
    }

    private let currentTrackSubject = CurrentValueSubject<Track?, Never>(nil)
    private let playbackStateSubject = CurrentValueSubject<PlaybackState, Never>(.stopped)
    private let playbackPositionSubject = CurrentValueSubject<TimeInterval, Never>(0)

    private var positionTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    var currentTrack: AnyPublisher<Track?, Never> {
        currentTrackSubject.eraseToAnyPublisher()
    }

    var playbackState: AnyPublisher<PlaybackState, Never> {
        playbackStateSubject.eraseToAnyPublisher()
    }

    var playbackPosition: AnyPublisher<TimeInterval, Never> {
        playbackPositionSubject.eraseToAnyPublisher()
    }

    var isAvailable: Bool {
        musicApp?.isRunning ?? false
    }

    let source: MusicSource = .appleMusic

    // MARK: - Lifecycle

    init() {}

    deinit {
        positionTimer?.invalidate()
    }

    // MARK: - Monitoring

    func startMonitoring() async {
        // Listen for Music.app notifications
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handlePlayerStateChanged(_:)),
            name: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil
        )

        // Initial state fetch
        await fetchCurrentState()

        // Start position timer
        startPositionTimer()
    }

    func stopMonitoring() async {
        DistributedNotificationCenter.default().removeObserver(self)
        positionTimer?.invalidate()
        positionTimer = nil
    }

    @objc private func handlePlayerStateChanged(_ notification: Notification) {
        Task { @MainActor in
            // Use notification userInfo directly - it contains all track data
            // ScriptingBridge KVC doesn't work properly in sandboxed apps
            updateFromNotification(notification.userInfo ?? [:])
        }
    }

    @MainActor
    private func updateFromNotification(_ userInfo: [AnyHashable: Any]) {
        // Extract player state from notification
        if let playerStateString = userInfo["Player State"] as? String {
            let state: PlaybackState
            switch playerStateString {
            case "Playing":
                state = .playing
            case "Paused":
                state = .paused
            case "Stopped":
                state = .stopped
            default:
                state = .stopped
            }
            playbackStateSubject.send(state)
        }

        // Extract track info from notification
        guard let name = userInfo["Name"] as? String, !name.isEmpty else {
            currentTrackSubject.send(nil)
            return
        }

        let artist = userInfo["Artist"] as? String ?? "Unknown Artist"
        let album = userInfo["Album"] as? String
        let totalTime = userInfo["Total Time"] as? Int ?? 0
        let duration = Double(totalTime) / 1000.0 // Convert ms to seconds
        let persistentID = userInfo["PersistentID"] as? Int64 ?? 0

        let track = Track(
            id: "\(persistentID)",
            title: name,
            artist: artist,
            album: album,
            duration: duration,
            artworkData: nil, // Artwork not available via notification
            artworkURL: nil,
            source: .appleMusic
        )
        currentTrackSubject.send(track)
    }

    @MainActor
    private func fetchCurrentState() async {
        // Note: ScriptingBridge KVC doesn't work properly in sandboxed apps
        // Track info is obtained via distributed notifications (updateFromNotification)
        // This method just checks if Music is running for isAvailable
        // No action needed on initial load - notifications will provide track info
    }

    private func startPositionTimer() {
        // Ensure timer runs on main run loop
        DispatchQueue.main.async { [weak self] in
            self?.positionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self,
                      let app = self.musicApp,
                      app.isRunning == true,
                      self.playbackStateSubject.value == .playing else { return }

                if let position = app.playerPosition {
                    self.playbackPositionSubject.send(position)
                }
            }
        }
    }

    // MARK: - Playback Control

    func play() async throws {
        guard let app = musicApp, app.isRunning == true else {
            throw MusicServiceError.notAvailable
        }
        app.playpause?()
    }

    func pause() async throws {
        guard let app = musicApp, app.isRunning == true else {
            throw MusicServiceError.notAvailable
        }
        app.pause?()
    }

    func nextTrack() async throws {
        guard let app = musicApp, app.isRunning == true else {
            throw MusicServiceError.notAvailable
        }
        app.nextTrack?()
    }

    func previousTrack() async throws {
        guard let app = musicApp, app.isRunning == true else {
            throw MusicServiceError.notAvailable
        }
        app.previousTrack?()
    }

    func seek(to position: TimeInterval) async throws {
        guard let sbApp = SBApplication(bundleIdentifier: "com.apple.Music"),
              (sbApp as MusicApplicationProtocol).isRunning == true else {
            throw MusicServiceError.notAvailable
        }
        sbApp.setValue(position, forKey: "playerPosition")
    }

    func setVolume(_ volume: Float) async throws {
        guard let sbApp = SBApplication(bundleIdentifier: "com.apple.Music"),
              (sbApp as MusicApplicationProtocol).isRunning == true else {
            throw MusicServiceError.notAvailable
        }
        sbApp.setValue(Int(volume * 100), forKey: "soundVolume")
    }

    func toggleLike() async throws {
        guard let app = musicApp, app.isRunning == true else {
            throw MusicServiceError.notAvailable
        }
        guard let trackObject = app.currentTrack as? MusicTrackProtocol else {
            throw MusicServiceError.notPlaying
        }
        let currentFavorited = trackObject.favorited ?? false
        (trackObject as? SBObject)?.setValue(!currentFavorited, forKey: "favorited")
    }

    // MARK: - Helpers

    private func mapPlayerState(_ state: MusicEPlS) -> PlaybackState {
        switch state {
        case MusicEPlSPlaying, MusicEPlSFastForwarding, MusicEPlSRewinding:
            return .playing
        case MusicEPlSPaused:
            return .paused
        case MusicEPlSStopped:
            return .stopped
        default:
            return .stopped
        }
    }
}
