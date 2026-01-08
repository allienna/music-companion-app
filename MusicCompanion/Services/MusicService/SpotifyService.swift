import AppKit
import Combine
import Foundation
import os.log

private let logger = Logger(subsystem: "com.allienna.musiccompanion", category: "SpotifyService")

final class SpotifyService: MusicServiceProtocol {
    // MARK: - Properties

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
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.spotify.client" }
    }

    let source: MusicSource = .spotify

    // MARK: - Lifecycle

    init() {}

    deinit {
        positionTimer?.invalidate()
    }

    // MARK: - Monitoring

    func startMonitoring() async {
        NSLog("[SpotifyService] Starting monitoring, isAvailable: %d", isAvailable)
        logger.info("Starting monitoring, isAvailable: \(self.isAvailable)")

        // Listen for Spotify notifications
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handlePlaybackStateChanged(_:)),
            name: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
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

    @objc private func handlePlaybackStateChanged(_ notification: Notification) {
        Task { @MainActor in
            await fetchCurrentState()
        }
    }

    @MainActor
    private func fetchCurrentState() async {
        NSLog("[SpotifyService] fetchCurrentState called, isAvailable: %d", isAvailable)
        logger.info("fetchCurrentState called, isAvailable: \(self.isAvailable)")

        guard isAvailable else {
            logger.info("Spotify not available")
            playbackStateSubject.send(.stopped)
            currentTrackSubject.send(nil)
            return
        }

        // Use AppleScript to get all track info reliably
        let script = """
        tell application "Spotify"
            if player state is playing then
                set ps to "playing"
            else if player state is paused then
                set ps to "paused"
            else
                set ps to "stopped"
            end if

            set pos to player position

            try
                set t to current track
                set trackName to name of t
                set trackArtist to artist of t
                set trackAlbum to album of t
                set trackId to id of t
                set trackDuration to duration of t
                set trackArtwork to artwork url of t
                return ps & "|||" & pos & "|||" & trackName & "|||" & trackArtist & "|||" & trackAlbum & "|||" & trackId & "|||" & trackDuration & "|||" & trackArtwork
            on error
                return ps & "|||" & pos & "|||"
            end try
        end tell
        """

        guard let result = runAppleScript(script) else {
            NSLog("[SpotifyService] AppleScript returned nil")
            logger.error("AppleScript returned nil")
            playbackStateSubject.send(.stopped)
            currentTrackSubject.send(nil)
            return
        }

        NSLog("[SpotifyService] AppleScript result: %@", result)
        logger.info("AppleScript result: \(result)")
        let parts = result.components(separatedBy: "|||")
        guard parts.count >= 2 else { return }

        // Parse player state
        let stateString = parts[0]
        let state: PlaybackState
        switch stateString {
        case "playing": state = .playing
        case "paused": state = .paused
        default: state = .stopped
        }
        playbackStateSubject.send(state)

        // Parse position (handle locale-specific decimal separator)
        let positionString = parts[1].replacingOccurrences(of: ",", with: ".")
        if let position = Double(positionString) {
            playbackPositionSubject.send(position)
        }

        // Parse track info if available
        guard parts.count >= 8 else {
            currentTrackSubject.send(nil)
            return
        }

        let name = parts[2]
        let artist = parts[3]
        let album = parts[4]
        let trackId = parts[5]
        let durationMs = Int(parts[6]) ?? 0
        let duration = Double(durationMs) / 1000.0
        let artworkUrlString = parts[7]

        // Fetch artwork
        var artworkData: Data?
        if !artworkUrlString.isEmpty, let url = URL(string: artworkUrlString) {
            artworkData = await fetchArtwork(from: url)
        }

        let track = Track(
            id: trackId,
            title: name,
            artist: artist,
            album: album.isEmpty ? nil : album,
            duration: duration,
            artworkData: artworkData,
            artworkURL: URL(string: artworkUrlString),
            source: .spotify
        )

        logger.info("Created track: \(track.title) - \(track.artist)")
        currentTrackSubject.send(track)
    }

    private func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        let script = NSAppleScript(source: source)
        let result = script?.executeAndReturnError(&error)
        if let error = error {
            let errorMessage = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
            let errorNumber = error[NSAppleScript.errorNumber] as? Int ?? 0
            NSLog("[SpotifyService] AppleScript error: %@ (code: %d)", errorMessage, errorNumber)
            logger.error("AppleScript error: \(errorMessage) (code: \(errorNumber))")
            return nil
        }
        return result?.stringValue
    }

    private func fetchArtwork(from url: URL) async -> Data? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch {
            return nil
        }
    }

    private func startPositionTimer() {
        // Ensure timer runs on main run loop
        DispatchQueue.main.async { [weak self] in
            self?.positionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self, self.playbackStateSubject.value == .playing else { return }

                // Update position using AppleScript (handle locale-specific decimal separator)
                if let result = self.runAppleScript("tell application \"Spotify\" to player position") {
                    let positionString = result.replacingOccurrences(of: ",", with: ".")
                    if let position = Double(positionString) {
                        self.playbackPositionSubject.send(position)
                    }
                }
            }
        }
    }

    // MARK: - Playback Control

    func play() async throws {
        guard isAvailable else { throw MusicServiceError.notAvailable }
        _ = runAppleScript("tell application \"Spotify\" to play")
    }

    func pause() async throws {
        guard isAvailable else { throw MusicServiceError.notAvailable }
        _ = runAppleScript("tell application \"Spotify\" to pause")
    }

    func nextTrack() async throws {
        guard isAvailable else { throw MusicServiceError.notAvailable }
        _ = runAppleScript("tell application \"Spotify\" to next track")
    }

    func previousTrack() async throws {
        guard isAvailable else { throw MusicServiceError.notAvailable }
        _ = runAppleScript("tell application \"Spotify\" to previous track")
    }

    func seek(to position: TimeInterval) async throws {
        guard isAvailable else { throw MusicServiceError.notAvailable }
        _ = runAppleScript("tell application \"Spotify\" to set player position to \(position)")
    }

    func setVolume(_ volume: Float) async throws {
        guard isAvailable else { throw MusicServiceError.notAvailable }
        let volumeInt = Int(volume * 100)
        _ = runAppleScript("tell application \"Spotify\" to set sound volume to \(volumeInt)")
    }

    func toggleLike() async throws {
        throw MusicServiceError.operationFailed("Liking tracks requires Spotify Web API")
    }
}
