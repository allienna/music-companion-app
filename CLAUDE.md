# CLAUDE.md — Instructions for Claude Code

This file provides context and instructions for Claude Code when working on this project.

## Project Overview

**Name:** Music Companion App (working title)  
**Type:** Native macOS application  
**Purpose:** Display "Now Playing" information and control playback for Spotify and Apple Music  
**Inspiration:** Tuneful, Sleeve  
**Differentiators:** Lyrics, widgets

## Tech Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI + AppKit (hybrid)
- **Minimum Target:** macOS 14.0 (Sonoma)
- **Architecture:** MVVM with Combine
- **Persistence:** SwiftData
- **Package Manager:** Swift Package Manager

## Dependencies

```swift
// Package.swift dependencies
.package(url: "https://github.com/MrKai77/DynamicNotchKit", from: "1.0.0"),
.package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "1.0.0"),
.package(url: "https://github.com/sindresorhus/LaunchAtLogin", from: "5.0.0"),
```

## Key Technical Areas

### 1. Music Service Integration

**Apple Music / Music.app:**
```swift
// Use MusicKit for modern API access
import MusicKit

// Monitor playback changes
DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name("com.apple.Music.playerInfo"),
    object: nil,
    queue: .main
) { notification in
    // Handle track change
}

// ScriptingBridge for playback control
// Generate: sdef /System/Applications/Music.app | sdp -fh --basename Music
```

**Spotify:**
```swift
// ScriptingBridge for local control
// Generate: sdef /Applications/Spotify.app | sdp -fh --basename Spotify

// Web API for additional features
// OAuth 2.0 PKCE flow - no client secret needed
```

### 2. UI Components

**Menu Bar App:**
```swift
// NSStatusItem for menu bar presence
let statusItem = NSStatusBar.system.statusItem(withLength: .variableLength)
statusItem.button?.title = "♫ Song Name"

// NSPopover for dropdown interface
let popover = NSPopover()
popover.contentViewController = NSHostingController(rootView: PopoverView())
```

**Notch Integration:**
```swift
// Use DynamicNotchKit or custom NSWindow
// Position at screen top, handle hover with NSTrackingArea
// Add haptic feedback with NSHapticFeedbackManager
```

**Mini Player:**
```swift
// NSPanel with floating level
let panel = NSPanel(
    contentRect: rect,
    styleMask: [.borderless, .nonactivatingPanel],
    backing: .buffered,
    defer: false
)
panel.level = .floating
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
```

### 3. Required Entitlements

```xml
<!-- For AppleScript/automation -->
<key>com.apple.security.automation.apple-events</key>
<true/>

<!-- For App Groups (widget data sharing) -->
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.yourcompany.musiccompanion</string>
</array>
```

### 4. Info.plist Keys

```xml
<!-- Agent app (no dock icon) -->
<key>LSUIElement</key>
<true/>

<!-- AppleScript permission description -->
<key>NSAppleEventsUsageDescription</key>
<string>MusicCompanion needs permission to control your music apps.</string>
```

## Code Style Guidelines

### Swift Conventions
- Use Swift's native concurrency (async/await)
- Prefer value types (structs) over reference types
- Use Combine for reactive data flow
- Mark @MainActor for UI-related code
- Document public APIs with DocC comments

### Naming
- Types: `PascalCase` (e.g., `MusicService`, `TrackViewModel`)
- Properties/methods: `camelCase` (e.g., `currentTrack`, `fetchLyrics()`)
- Constants: `camelCase` (e.g., `defaultPadding`)
- Protocols: Noun or `-able`/`-ible` suffix (e.g., `MusicServiceProtocol`, `Playable`)

### File Organization
- One type per file (usually)
- Group related files in feature folders
- Keep views and view models together
- Separate protocols into their own files

## Common Patterns

### Service Protocol
```swift
protocol MusicServiceProtocol {
    var currentTrack: AnyPublisher<Track?, Never> { get }
    var playbackState: AnyPublisher<PlaybackState, Never> { get }
    
    func play() async throws
    func pause() async throws
    func nextTrack() async throws
    func previousTrack() async throws
}
```

### ViewModel Pattern
```swift
@MainActor
final class NowPlayingViewModel: ObservableObject {
    @Published private(set) var track: Track?
    @Published private(set) var isPlaying: Bool = false
    
    private let musicService: MusicServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(musicService: MusicServiceProtocol) {
        self.musicService = musicService
        setupBindings()
    }
}
```

### Error Handling
```swift
enum MusicServiceError: LocalizedError {
    case notRunning
    case notAuthorized
    case networkError(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .notRunning: return "Music app is not running"
        case .notAuthorized: return "Not authorized to control music"
        case .networkError(let error): return error.localizedDescription
        }
    }
}
```

## Common Commands

```bash
# Build the project
xcodebuild -scheme MusicCompanion -configuration Debug build

# Run tests
xcodebuild -scheme MusicCompanion -configuration Debug test

# Generate ScriptingBridge headers
sdef /Applications/Spotify.app | sdp -fh --basename Spotify
sdef /System/Applications/Music.app | sdp -fh --basename Music

# Format code (if SwiftFormat is installed)
swiftformat .

# Lint code (if SwiftLint is installed)
swiftlint
```

## Current Status

- [x] Step 1: Competitor analysis complete
- [x] Step 2: Feature proposals complete
- [x] Step 3: Development plan complete
- [ ] Step 4: Monetization strategy
- [ ] Development: Not started

## Development Priorities

### Phase 1 (MVP)
1. Menu bar player with popover
2. Apple Music integration
3. Spotify integration
4. Basic playback controls

### Phase 2 (Core Features)
1. Notch integration
2. Mini player window
3. Theme system basics

### Phase 3 (Differentiators)
1. Real-time lyrics
2. macOS widgets

## Notes for Claude Code

When generating code for this project:

1. **Always use SwiftUI** for views unless AppKit is specifically required
2. **Prefer async/await** over completion handlers
3. **Use Combine** for reactive state management
4. **Follow MVVM** — keep views dumb, logic in view models
5. **Handle errors gracefully** — music apps may not always be running
6. **Consider accessibility** — VoiceOver, keyboard navigation
7. **Minimize energy impact** — use efficient polling/observation
8. **Test on both** Intel and Apple Silicon if possible

## Resources

- [MusicKit Documentation](https://developer.apple.com/documentation/musickit)
- [Spotify Web API](https://developer.spotify.com/documentation/web-api)
- [NSStatusItem Documentation](https://developer.apple.com/documentation/appkit/nsstatusitem)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [DynamicNotchKit](https://github.com/MrKai77/DynamicNotchKit)
