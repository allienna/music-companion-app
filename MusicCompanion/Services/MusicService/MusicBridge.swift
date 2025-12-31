import Foundation
import ScriptingBridge

// MARK: - Music Application Protocol

/// Swift protocol for ScriptingBridge access to Music.app
/// This mirrors the essential properties from Music.h for Swift compatibility
@objc protocol MusicApplicationProtocol {
    @objc optional var isRunning: Bool { get }
    @objc optional var playerState: MusicEPlS { get }
    @objc optional var playerPosition: Double { get set }
    @objc optional var soundVolume: Int { get set }
    @objc optional var currentTrack: SBObject? { get }

    @objc optional func playpause()
    @objc optional func pause()
    @objc optional func nextTrack()
    @objc optional func previousTrack()
    @objc optional func backTrack()
}

/// Make SBApplication conform to our protocol via extension
extension SBApplication: MusicApplicationProtocol {}

// MARK: - Music Track Protocol

/// Swift protocol for accessing track properties
@objc protocol MusicTrackProtocol {
    @objc optional var name: String { get }
    @objc optional var artist: String { get }
    @objc optional var album: String { get }
    @objc optional var duration: Double { get }
    @objc optional var databaseID: Int { get }
    @objc optional var favorited: Bool { get set }

    @objc optional func artworks() -> SBElementArray?
}

/// Make SBObject conform to track protocol
extension SBObject: MusicTrackProtocol {}

// MARK: - Music Artwork Protocol

/// Swift protocol for accessing artwork
@objc protocol MusicArtworkProtocol {
    @objc optional var data: NSImage? { get }
}

extension SBObject: MusicArtworkProtocol {}
