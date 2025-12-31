import Combine
import Foundation

protocol MusicServiceProtocol: AnyObject {
    /// Publisher for the currently playing track
    var currentTrack: AnyPublisher<Track?, Never> { get }

    /// Publisher for the current playback state
    var playbackState: AnyPublisher<PlaybackState, Never> { get }

    /// Publisher for the current playback position in seconds
    var playbackPosition: AnyPublisher<TimeInterval, Never> { get }

    /// Whether this service is currently available (app running, authenticated, etc.)
    var isAvailable: Bool { get }

    /// The source type this service handles
    var source: MusicSource { get }

    /// Start monitoring for playback changes
    func startMonitoring() async

    /// Stop monitoring for playback changes
    func stopMonitoring() async

    /// Resume playback
    func play() async throws

    /// Pause playback
    func pause() async throws

    /// Skip to next track
    func nextTrack() async throws

    /// Go to previous track
    func previousTrack() async throws

    /// Seek to a specific position
    func seek(to position: TimeInterval) async throws

    /// Set the playback volume (0.0 - 1.0)
    func setVolume(_ volume: Float) async throws

    /// Toggle like/favorite status for current track
    func toggleLike() async throws
}

enum MusicServiceError: LocalizedError {
    case notAvailable
    case notPlaying
    case unauthorized
    case operationFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            "Music service is not available"
        case .notPlaying:
            "No track is currently playing"
        case .unauthorized:
            "Not authorized to control playback"
        case .operationFailed(let message):
            "Operation failed: \(message)"
        }
    }
}
