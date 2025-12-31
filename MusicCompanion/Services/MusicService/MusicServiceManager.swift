import Combine
import Foundation

@MainActor
final class MusicServiceManager: ObservableObject {
    private var services: [MusicServiceProtocol] = []
    private var activeService: MusicServiceProtocol?
    private var cancellables = Set<AnyCancellable>()

    private let currentTrackSubject = CurrentValueSubject<Track?, Never>(nil)
    private let playbackStateSubject = CurrentValueSubject<PlaybackState, Never>(.stopped)
    private let playbackPositionSubject = CurrentValueSubject<TimeInterval, Never>(0)

    var currentTrack: AnyPublisher<Track?, Never> {
        currentTrackSubject.eraseToAnyPublisher()
    }

    var playbackState: AnyPublisher<PlaybackState, Never> {
        playbackStateSubject.eraseToAnyPublisher()
    }

    var playbackPosition: AnyPublisher<TimeInterval, Never> {
        playbackPositionSubject.eraseToAnyPublisher()
    }

    init() {
        setupServices()
    }

    private func setupServices() {
        // Register available music services
        services.append(AppleMusicService())
        // TODO: Add SpotifyService when implemented
        // services.append(SpotifyService())
    }

    func startMonitoring() async {
        for service in services {
            await service.startMonitoring()
            subscribeToService(service)
        }
    }

    func stopMonitoring() async {
        for service in services {
            await service.stopMonitoring()
        }
        cancellables.removeAll()
    }

    private func subscribeToService(_ service: MusicServiceProtocol) {
        service.currentTrack
            .sink { [weak self] track in
                if track != nil {
                    self?.activeService = service
                    self?.currentTrackSubject.send(track)
                }
            }
            .store(in: &cancellables)

        service.playbackState
            .sink { [weak self] state in
                self?.playbackStateSubject.send(state)
            }
            .store(in: &cancellables)

        service.playbackPosition
            .sink { [weak self] position in
                self?.playbackPositionSubject.send(position)
            }
            .store(in: &cancellables)
    }

    // MARK: - Playback Control

    func play() async throws {
        guard let service = activeService else {
            throw MusicServiceError.notAvailable
        }
        try await service.play()
    }

    func pause() async throws {
        guard let service = activeService else {
            throw MusicServiceError.notAvailable
        }
        try await service.pause()
    }

    func nextTrack() async throws {
        guard let service = activeService else {
            throw MusicServiceError.notAvailable
        }
        try await service.nextTrack()
    }

    func previousTrack() async throws {
        guard let service = activeService else {
            throw MusicServiceError.notAvailable
        }
        try await service.previousTrack()
    }

    func seek(to position: TimeInterval) async throws {
        guard let service = activeService else {
            throw MusicServiceError.notAvailable
        }
        try await service.seek(to: position)
    }

    func setVolume(_ volume: Float) async throws {
        guard let service = activeService else {
            throw MusicServiceError.notAvailable
        }
        try await service.setVolume(volume)
    }

    func toggleLike() async throws {
        guard let service = activeService else {
            throw MusicServiceError.notAvailable
        }
        try await service.toggleLike()
    }
}
