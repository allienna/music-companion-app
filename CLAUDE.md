# CLAUDE.md — Instructions for Claude Code

This file provides context and instructions for Claude Code when working on this project.

## Project Overview

**Name:** Music Companion App (working title)  
**Type:** Native macOS application  
**Purpose:** Display "Now Playing" information and control playback for Spotify and Apple Music  
**Inspiration:** Tuneful, Sleeve

## Tech Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Minimum Target:** macOS 14.0 (Sonoma)
- **Architecture:** MVVM with Combine
- **Package Manager:** Swift Package Manager

## Key Technical Areas

### 1. Music Service Integration

**Apple Music / Music.app:**
- Use `MusicKit` framework for modern API access
- Fall back to `ScriptingBridge` for legacy support
- Monitor `NSDistributedNotificationCenter` for playback changes

**Spotify:**
- Use AppleScript/ScriptingBridge for local control
- Spotify Web API for additional features (likes, playlists)
- OAuth 2.0 authentication flow

### 2. UI Components

**Menu Bar App:**
- `NSStatusItem` for menu bar presence
- `NSPopover` for dropdown interface

**Notch Integration:**
- `NSWindow` positioned at screen top
- `NSTrackingArea` for hover detection
- Core Animation for smooth transitions

**Mini Player:**
- `NSPanel` with `.floating` level
- Drag-to-position with `NSWindow` delegate

### 3. System Integration

- `NSEvent.addGlobalMonitorForEvents` for global keyboard shortcuts
- `NSHapticFeedbackManager` for trackpad haptics
- `NSWorkspace` notifications for app lifecycle

## Code Style Guidelines

- Use Swift's native concurrency (async/await)
- Prefer value types (structs) over reference types
- Use Combine for reactive data flow
- Follow Apple's Human Interface Guidelines
- Document public APIs with DocC comments

## File Organization

```
src/
├── App/
│   ├── MusicCompanionApp.swift
│   └── AppDelegate.swift
├── Features/
│   ├── NowPlaying/
│   ├── MenuBar/
│   ├── Notch/
│   ├── MiniPlayer/
│   └── Settings/
├── Services/
│   ├── MusicService/
│   ├── SpotifyService/
│   └── AppleMusicService/
├── Models/
├── Views/
├── ViewModels/
└── Utilities/
```

## Common Commands

```bash
# Build the project
xcodebuild -scheme MusicCompanion -configuration Debug build

# Run tests
xcodebuild -scheme MusicCompanion -configuration Debug test

# Format code (if SwiftFormat is installed)
swiftformat .

# Lint code (if SwiftLint is installed)
swiftlint
```

## Current Status

- [x] Step 1: Competitor analysis complete
- [ ] Step 2: Feature proposals (in progress)
- [ ] Step 3: Development plan
- [ ] Step 4: Monetization strategy
- [ ] Development: Not started

## Resources

- [MusicKit Documentation](https://developer.apple.com/documentation/musickit)
- [Spotify Web API](https://developer.spotify.com/documentation/web-api)
- [NSStatusItem Documentation](https://developer.apple.com/documentation/appkit/nsstatusitem)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)

## Notes for Claude Code

When generating code for this project:

1. **Always use SwiftUI** for views unless AppKit is specifically required
2. **Prefer async/await** over completion handlers
3. **Use Combine** for reactive state management
4. **Follow MVVM** — keep views dumb, logic in view models
5. **Handle errors gracefully** — music apps may not always be running
6. **Test on both** Intel and Apple Silicon if possible
7. **Consider accessibility** — VoiceOver, keyboard navigation
8. **Minimize energy impact** — use efficient polling/observation
