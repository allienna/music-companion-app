# Development Plan with Claude Code

**Last Updated:** December 31, 2024  
**Status:** ✅ Complete

## Overview

This document outlines the technical roadmap for building a macOS music companion app using Claude Code as an AI-assisted development tool.

---

## 1. Technology Stack

### Core Technologies

| Component | Technology | Rationale |
|-----------|------------|-----------|
| **Language** | Swift 5.9+ | Native performance, modern concurrency |
| **UI Framework** | SwiftUI + AppKit | SwiftUI for views, AppKit for system integration |
| **Minimum Target** | macOS 14.0 (Sonoma) | WidgetKit interactivity, modern APIs |
| **Architecture** | MVVM + Combine | Clean separation, reactive updates |
| **Persistence** | SwiftData / CoreData | Local storage for stats, lyrics cache |
| **Networking** | URLSession + async/await | Native, no dependencies |

### Key Frameworks

```
┌─────────────────────────────────────────────────────────────┐
│                      Your App                                │
├─────────────────────────────────────────────────────────────┤
│  SwiftUI          │  AppKit            │  Combine           │
│  (Views)          │  (System APIs)     │  (Reactive)        │
├───────────────────┴──────────────────────────────────────────┤
│  MusicKit         │  ScriptingBridge   │  WidgetKit         │
│  (Apple Music)    │  (Spotify/legacy)  │  (Widgets)         │
├───────────────────┴──────────────────────────────────────────┤
│  NSStatusItem     │  NSWindow          │  NSDistributed     │
│  (Menu bar)       │  (Notch/Mini)      │  NotificationCenter│
└─────────────────────────────────────────────────────────────┘
```

### Dependencies (Minimal)

| Package | Purpose | Source |
|---------|---------|--------|
| **DynamicNotchKit** | Notch integration helper | github.com/MrKai77/DynamicNotchKit |
| **KeyboardShortcuts** | Global hotkeys | github.com/sindresorhus/KeyboardShortcuts |
| **LaunchAtLogin** | Login item management | github.com/sindresorhus/LaunchAtLogin |
| **Sparkle** | Auto-updates (non-MAS) | github.com/sparkle-project/Sparkle |

---

## 2. Architecture Overview

### Project Structure

```
MusicCompanion/
├── App/
│   ├── MusicCompanionApp.swift      # @main entry point
│   ├── AppDelegate.swift            # NSApplicationDelegate
│   └── AppState.swift               # Global app state
│
├── Features/
│   ├── NowPlaying/
│   │   ├── NowPlayingView.swift
│   │   ├── NowPlayingViewModel.swift
│   │   └── Models/
│   │       └── Track.swift
│   │
│   ├── MenuBar/
│   │   ├── MenuBarController.swift  # NSStatusItem management
│   │   ├── MenuBarPopover.swift     # Popover view
│   │   └── MenuBarViewModel.swift
│   │
│   ├── Notch/
│   │   ├── NotchController.swift    # Notch window management
│   │   ├── NotchView.swift          # SwiftUI notch content
│   │   └── NotchAnimations.swift    # Custom animations
│   │
│   ├── MiniPlayer/
│   │   ├── MiniPlayerWindow.swift   # NSPanel configuration
│   │   ├── MiniPlayerView.swift
│   │   └── MiniPlayerStyles/        # Different visual styles
│   │
│   ├── Lyrics/
│   │   ├── LyricsView.swift
│   │   ├── LyricsViewModel.swift
│   │   └── LyricsSyncEngine.swift
│   │
│   ├── Statistics/
│   │   ├── StatsView.swift
│   │   ├── StatsViewModel.swift
│   │   └── Charts/
│   │
│   ├── Themes/
│   │   ├── ThemeManager.swift
│   │   ├── Theme.swift              # Theme model
│   │   └── ThemeEditor.swift
│   │
│   └── Settings/
│       ├── SettingsView.swift
│       └── Tabs/
│
├── Services/
│   ├── MusicService/
│   │   ├── MusicServiceProtocol.swift
│   │   ├── AppleMusicService.swift
│   │   ├── SpotifyService.swift
│   │   └── MusicServiceManager.swift  # Switches between services
│   │
│   ├── LyricsService/
│   │   ├── LyricsProvider.swift
│   │   ├── SpotifyLyricsProvider.swift
│   │   ├── LRCLIBProvider.swift
│   │   └── LyricsCache.swift
│   │
│   ├── ScrobblingService/
│   │   └── LastFMService.swift
│   │
│   └── DiscordService/
│       └── DiscordRichPresence.swift
│
├── Shared/
│   ├── Extensions/
│   ├── Utilities/
│   └── Constants.swift
│
├── Resources/
│   ├── Assets.xcassets
│   └── Localizable.strings
│
└── Widget/
    └── MusicCompanionWidget/        # WidgetKit extension
```

### Data Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Spotify    │     │ Apple Music  │     │   Doppler    │
└──────┬───────┘     └──────┬───────┘     └──────┬───────┘
       │                    │                    │
       └────────────────────┼────────────────────┘
                            │
                   ┌────────▼────────┐
                   │ MusicService    │
                   │ Manager         │
                   └────────┬────────┘
                            │
              ┌─────────────┼─────────────┐
              │             │             │
       ┌──────▼──────┐ ┌────▼────┐ ┌──────▼──────┐
       │ NowPlaying  │ │ Lyrics  │ │ Statistics  │
       │ ViewModel   │ │ Service │ │ Service     │
       └──────┬──────┘ └────┬────┘ └──────┬──────┘
              │             │             │
       ┌──────▼──────┐ ┌────▼────┐ ┌──────▼──────┐
       │ SwiftUI     │ │ SwiftUI │ │ SwiftUI     │
       │ Views       │ │ Views   │ │ Views       │
       └─────────────┘ └─────────┘ └─────────────┘
```

---

## 3. Development Phases

### Phase 0: Project Setup (Week 1)
- [ ] Create Xcode project with proper structure
- [ ] Configure signing & capabilities
- [ ] Set up Swift Package Manager dependencies
- [ ] Create basic app shell (menu bar only)
- [ ] Implement `NSApplicationDelegate` lifecycle

**Claude Code Tasks:**
```
"Create a new macOS menu bar app project structure with SwiftUI"
"Set up NSStatusItem with a popover for the menu bar"
"Configure Info.plist for agent app (LSUIElement)"
```

---

### Phase 1: Music Service Integration (Weeks 2-3)

#### 1.1 Apple Music Integration

**Approach:** MusicKit + ScriptingBridge fallback

```swift
// MusicKit for authorized access
import MusicKit

// ScriptingBridge for playback control
// Generate with: sdef /System/Applications/Music.app | sdp -fh --basename Music
```

**Key APIs:**
- `MusicKit.SystemMusicPlayer` — Current track info
- `NSDistributedNotificationCenter` — Playback state changes
- ScriptingBridge — Play/pause/skip commands

**Claude Code Tasks:**
```
"Create MusicServiceProtocol with async methods for track info, playback control"
"Implement AppleMusicService using MusicKit and ScriptingBridge"
"Subscribe to com.apple.Music.playerInfo distributed notifications"
```

#### 1.2 Spotify Integration

**Approach:** ScriptingBridge + Web API

```swift
// Generate Spotify scripting bridge:
// sdef /Applications/Spotify.app | sdp -fh --basename Spotify

// Web API for additional features (likes, playlists)
// OAuth 2.0 PKCE flow
```

**Key APIs:**
- ScriptingBridge — Local playback control
- Spotify Web API — User library, lyrics
- `NSWorkspace.shared.runningApplications` — Detect if running

**Claude Code Tasks:**
```
"Generate ScriptingBridge Swift files for Spotify app"
"Implement SpotifyService with playback monitoring"
"Create OAuth 2.0 PKCE flow for Spotify Web API authentication"
```

#### 1.3 Unified Music Service

```swift
protocol MusicServiceProtocol {
    var currentTrack: AnyPublisher<Track?, Never> { get }
    var playbackState: AnyPublisher<PlaybackState, Never> { get }
    var playbackPosition: AnyPublisher<TimeInterval, Never> { get }
    
    func play() async throws
    func pause() async throws
    func nextTrack() async throws
    func previousTrack() async throws
    func seek(to position: TimeInterval) async throws
    func setVolume(_ volume: Float) async throws
    func toggleLike() async throws
}
```

---

### Phase 2: Core UI Components (Weeks 4-6)

#### 2.1 Menu Bar Player

**Components:**
- `NSStatusItem` with variable length (song info)
- `NSPopover` with SwiftUI content
- Playback controls, volume slider, output selector

**Claude Code Tasks:**
```
"Create MenuBarController managing NSStatusItem with song title display"
"Build SwiftUI popover with album art, track info, playback controls"
"Add volume slider with audio output device picker"
"Implement keyboard shortcut HUD overlay"
```

#### 2.2 Notch Integration

**Approach:** Use DynamicNotchKit or custom implementation

**Components:**
- Hover detection over notch area
- Animated expansion with haptic feedback
- Live activity visualization (waveform)
- Non-notch Mac support (fake notch bar)

**Claude Code Tasks:**
```
"Implement NotchController with NSTrackingArea for hover detection"
"Create expanding notch animation using CAAnimation"
"Add NSHapticFeedbackManager integration for trackpad haptics"
"Build waveform visualization view using AudioVisualizerKit or custom"
```

#### 2.3 Mini Player Window

**Components:**
- `NSPanel` with `.floating` level
- Multiple style presets (Compact, Horizontal, Vertical, etc.)
- Drag-to-position, snap-to-edges
- Transparent/blurred backgrounds

**Claude Code Tasks:**
```
"Create MiniPlayerWindow as NSPanel with always-on-top option"
"Implement draggable window with edge snapping"
"Build multiple mini player style views (Compact, Horizontal, Gradient)"
"Add NSVisualEffectView for blur/vibrancy effects"
```

---

### Phase 3: Differentiating Features (Weeks 7-10)

#### 3.1 Real-Time Lyrics

**Architecture:**
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Spotify API │     │   LRCLIB    │     │ Musixmatch  │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       └───────────────────┼───────────────────┘
                           │
                  ┌────────▼────────┐
                  │ LyricsProvider  │
                  │ (Priority chain)│
                  └────────┬────────┘
                           │
                  ┌────────▼────────┐
                  │ LyricsSyncEngine│
                  │ (Time matching) │
                  └────────┬────────┘
                           │
                  ┌────────▼────────┐
                  │  LyricsCache    │
                  │  (CoreData)     │
                  └─────────────────┘
```

**Claude Code Tasks:**
```
"Create LyricsProvider protocol with fetchLyrics(for track:) async"
"Implement SpotifyLyricsProvider using Spotify's lyrics API"
"Build LRCLIB provider as fallback"
"Create LyricsSyncEngine that matches lyrics to playback position"
"Build floating lyrics window with word-by-word highlighting"
```

#### 3.2 Discord Rich Presence

**Approach:** Discord Game SDK or IPC

**Claude Code Tasks:**
```
"Implement Discord Rich Presence using Discord's IPC protocol"
"Create DiscordService that updates presence on track change"
"Add settings for what info to share (track, artist, album art)"
```

#### 3.3 Listening Statistics

**Data Model:**
```swift
@Model
class PlayRecord {
    var trackId: String
    var trackName: String
    var artistName: String
    var albumName: String
    var playedAt: Date
    var duration: TimeInterval
    var source: MusicSource
}
```

**Claude Code Tasks:**
```
"Create SwiftData models for tracking play history"
"Build StatsService that records plays and calculates insights"
"Create charts using Swift Charts (top artists, listening time, etc.)"
"Design shareable 'mini-wrapped' card view"
```

#### 3.4 macOS Widgets

**Widget Types:**
- Small: Album art only
- Medium: Album art + track info
- Large: Full player with controls (interactive)

**Claude Code Tasks:**
```
"Create WidgetKit extension with timeline provider"
"Build widget views for small, medium, large sizes"
"Implement App Intents for interactive widget controls (macOS 14+)"
"Set up App Groups for data sharing between app and widget"
```

---

### Phase 4: Theme System (Weeks 11-12)

**Theme Model:**
```swift
struct Theme: Codable, Identifiable {
    var id: UUID
    var name: String
    var appearance: Appearance  // light, dark, auto
    
    // Typography
    var titleFont: FontConfig
    var artistFont: FontConfig
    var albumFont: FontConfig
    
    // Colors
    var backgroundColor: ColorConfig
    var textColor: ColorConfig
    var accentColor: ColorConfig
    
    // Layout
    var artworkSize: CGFloat
    var artworkCornerRadius: CGFloat
    var showControls: Bool
    var controlsPosition: ControlsPosition
    
    // Effects
    var backgroundBlur: Bool
    var artworkShadow: Bool
    var artworkShelving: ShelvingStyle?
}
```

**Claude Code Tasks:**
```
"Create Theme model with Codable conformance"
"Build ThemeManager with iCloud sync via NSUbiquitousKeyValueStore"
"Create theme editor UI with live preview"
"Implement theme import/export as .musictheme files"
```

---

### Phase 5: Polish & Release (Weeks 13-14)

- [ ] Settings UI consolidation
- [ ] Onboarding flow
- [ ] Accessibility (VoiceOver, keyboard navigation)
- [ ] Localization (at minimum: EN, FR, DE, ES, JA)
- [ ] Performance optimization
- [ ] Memory leak testing
- [ ] Beta testing via TestFlight

---

## 4. Claude Code Workflow

### Setting Up Claude Code

1. **Install Claude Code CLI:**
   ```bash
   # Install via npm or direct download
   npm install -g @anthropic/claude-code
   ```

2. **Initialize in project:**
   ```bash
   cd MusicCompanion
   claude init
   ```

3. **Configure CLAUDE.md** (already created in repo)

### Effective Prompting Strategies

#### For New Features
```
Context: I'm building [feature] for a macOS music companion app.
Current state: [describe what exists]
Goal: [describe desired outcome]

Please:
1. Suggest the best approach
2. Write the implementation
3. Include error handling
4. Add documentation comments
```

#### For Debugging
```
I'm getting [error] when [action].

Here's the relevant code:
[paste code]

The expected behavior is [X] but actual behavior is [Y].
```

#### For Code Review
```
Please review this code for:
- Swift best practices
- Memory management issues
- Thread safety
- Potential crashes
- Performance concerns

[paste code]
```

### Iterative Development Pattern

```
┌─────────────────┐
│ 1. Describe     │
│    feature      │
└────────┬────────┘
         │
┌────────▼────────┐
│ 2. Claude Code  │
│    generates    │
└────────┬────────┘
         │
┌────────▼────────┐
│ 3. Test in      │
│    Xcode        │
└────────┬────────┘
         │
┌────────▼────────┐
│ 4. Refine with  │
│    follow-ups   │
└────────┬────────┘
         │
┌────────▼────────┐
│ 5. Commit       │
│    working code │
└─────────────────┘
```

---

## 5. Technical Challenges & Solutions

### Challenge 1: macOS Tahoe Apple Music API Changes

**Problem:** macOS Tahoe broke third-party access to Apple Music streaming data.

**Solution:**
- Use MusicKit for what's available
- Fall back to ScriptingBridge
- Monitor for API updates
- Consider Shazam-style audio fingerprinting as last resort

### Challenge 2: Notch Area Restrictions

**Problem:** macOS restricts window positioning in notch area.

**Solution:**
- Use `NSWindow.Level.floating` or higher
- Set `collectionBehavior` to `.canJoinAllSpaces`
- Use DynamicNotchKit which handles edge cases
- For non-notch Macs, create custom "fake notch" bar

### Challenge 3: App Sandbox & AppleScript

**Problem:** Sandboxed apps can't freely send AppleEvents.

**Solution:**
- Add `NSAppleEventsUsageDescription` to Info.plist
- Request specific entitlements:
  ```xml
  <key>com.apple.security.automation.apple-events</key>
  <true/>
  ```
- For App Store: Use `NSUserAppleScriptTask` with user-provided scripts
- Consider non-sandboxed distribution for full features

### Challenge 4: Spotify Authentication

**Problem:** Spotify Web API requires OAuth, but embedding client secrets is insecure.

**Solution:**
- Use PKCE (Proof Key for Code Exchange) flow
- No client secret needed
- Store tokens securely in Keychain
- Implement token refresh logic

---

## 6. Testing Strategy

### Unit Tests
- Music service protocol conformance
- Lyrics sync timing accuracy
- Theme encoding/decoding
- Statistics calculations

### UI Tests
- Menu bar popover interaction
- Mini player drag/resize
- Settings persistence

### Integration Tests
- Spotify OAuth flow
- Last.fm scrobbling
- Widget data refresh

### Manual Testing Checklist
- [ ] Fresh install experience
- [ ] Upgrade from previous version
- [ ] Multiple monitors
- [ ] Notch vs non-notch Macs
- [ ] Light/dark mode switching
- [ ] Low power mode
- [ ] Accessibility features

---

## 7. Timeline Summary

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| 0: Setup | Week 1 | Project shell, menu bar app |
| 1: Music Services | Weeks 2-3 | Spotify + Apple Music integration |
| 2: Core UI | Weeks 4-6 | Menu bar, notch, mini player |
| 3: Features | Weeks 7-10 | Lyrics, Discord, stats, widgets |
| 4: Themes | Weeks 11-12 | Full theme system |
| 5: Polish | Weeks 13-14 | Beta release |

**Total: ~14 weeks to beta**

---

## 8. Resources

### Documentation
- [MusicKit](https://developer.apple.com/documentation/musickit)
- [AppKit NSStatusItem](https://developer.apple.com/documentation/appkit/nsstatusitem)
- [WidgetKit](https://developer.apple.com/documentation/widgetkit)
- [Spotify Web API](https://developer.spotify.com/documentation/web-api)
- [Discord Rich Presence](https://discord.com/developers/docs/rich-presence/how-to)

### Reference Implementations
- [DynamicNotchKit](https://github.com/MrKai77/DynamicNotchKit) — Notch integration
- [LyricFever](https://github.com/aviwad/LyricFever) — Lyrics sync approach
- [NotchBar](https://github.com/navtoj/NotchBar) — Notch app example
- [SwiftScripting](https://github.com/nickmain/SwiftScripting) — ScriptingBridge Swift tools

### Tutorials
- [AppCoda: Status Bar Apps](https://www.appcoda.com/macos-status-bar-apps/)
- [BrightDigit: ScriptingBridge + Swift](https://brightdigit.com/tutorials/scriptingbridge-applescript-swift/)
- [Medium: Menu Bar App with SwiftUI](https://medium.com/@acwrightdesign/creating-a-macos-menu-bar-application-using-swiftui-54572a5d5f87)
