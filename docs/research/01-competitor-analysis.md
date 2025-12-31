# Competitor Analysis: Tuneful vs Sleeve

**Last Updated:** December 31, 2024  
**Status:** ✅ Complete

## Executive Summary

This document analyzes the two leading macOS music companion apps: **Tuneful** and **Sleeve**. Both are native Swift/SwiftUI applications that display "Now Playing" information and provide playback controls for streaming music services.

| App | Price | Focus | Unique Strength |
|-----|-------|-------|-----------------|
| **Tuneful** | $4.99 | System integration | Notch & menu bar integration |
| **Sleeve** | $7.99 / $5.99 | Desktop aesthetic | Theme system & customization |

---

## Tuneful

**Developer:** Martin Fekete  
**Website:** https://www.tuneful.dev/  
**App Store:** https://apps.apple.com/us/app/tuneful/id6739804295  
**Price:** $4.99  
**Requirements:** macOS 14.0+  
**Supported Services:** Spotify, Apple Music

### Core Philosophy

Tuneful focuses on **seamless macOS integration**, embedding music controls into system UI elements (notch, menu bar) rather than creating a separate window. It aims to feel like a native extension of macOS.

### Features

#### Display Modes

| Mode | Description |
|------|-------------|
| **Notch Player** | Hover over MacBook notch to reveal music player with haptic feedback |
| **Menu Bar Player** | Click song name in menu bar for popover; three distinct styles available |
| **Mini Player** | Floating window with multiple designs (Compact, Horizontal, Vertical, Simple, Gradient Blur, Liquid Glass) |
| **Non-notch Support** | Simulated notch area for Macs without hardware notch |

#### Playback Controls

- Play/pause, skip forward/backward
- Volume control slider
- Music seeker/progress bar (with album-art-derived colors)
- Shuffle and repeat toggles
- **Audio output device selection** from menu bar
- Add to favorites (Spotify via Web API, Apple Music native)

#### Interactions

- **Trackpad gestures:** Horizontal swipe to skip, vertical swipe to open/close notch
- **Haptic feedback:** Tactile response on interactions
- Configurable hover duration to open notch
- Click or hover activation modes
- Context menu to switch between Spotify/Apple Music

#### Visual Features

- Song change notifications with scrolling text animation
- 3D album art flip animation on track change
- Waveform/equalizer visualization in notch
- Live Activity in notch (macOS Tahoe)
- Liquid Glass design style (macOS Tahoe)

#### Customization

- Notch height and width adjustment
- Menu bar display options (song info width, playback buttons)
- Mini player style selection
- Hide when not playing
- Multi-screen support (main screen, notch screen, or all)
- Keyboard shortcuts for all controls

### What Tuneful Does NOT Have

- ❌ Saveable/shareable theme system
- ❌ Last.fm scrobbling
- ❌ Doppler (third-party player) support
- ❌ Advanced typography customization
- ❌ Artwork shelving effects
- ❌ Theme export/import
- ❌ iCloud sync

---

## Sleeve

**Developer:** Replay Software (Alasdair Monk & Hector Simpson)  
**Website:** https://replay.software/sleeve  
**App Store:** https://apps.apple.com/us/app/sleeve/id1606145041  
**Price:** $7.99 (App Store) / $5.99 (Direct)  
**Requirements:** macOS 11.0+  
**Supported Services:** Spotify, Apple Music, Doppler

### Core Philosophy

Sleeve focuses on being a **beautiful desktop accessory** — a carefully designed "Now Playing" widget that sits on your desktop. It prioritizes visual customization and aesthetic flexibility over system integration.

### Features

#### Display Mode

- **Desktop Widget:** Floating window on desktop displaying album art, track info, and controls
- Multiple layouts: Horizontal, Vertical, Stacked, Text-only
- Pin to any corner or edge of any display

#### Theme System (Major Differentiator)

| Feature | Description |
|---------|-------------|
| **Built-in Themes** | 7 pre-designed themes included |
| **Custom Themes** | Create unlimited custom themes |
| **Theme Files** | Export/import .sleeve theme files |
| **Sharing** | Share themes with friends |
| **iCloud Sync** | Themes sync across devices automatically |
| **Appearance Modes** | Separate settings for Light/Dark mode |

#### Artwork Customization

- Scalable artwork (any size from hidden to full)
- Corner radius control (square to fully rounded)
- Shadow and lighting effects
- **Shelving effects** (8 styles) — artwork displayed on virtual shelf
- Option to hide artwork completely

#### Typography Customization

- Choose which track info lines to display
- Per-line customization:
  - Font family
  - Font weight
  - Font size
  - Transparency/opacity
  - Color
  - Shadow
- Letter spacing control
- Text capitalization options
- Font styles: Monospaced, Condensed, Expanded

#### Interface Options

- Layout selection (horizontal, vertical, stacked)
- Alignment and position controls
- Backdrop layer with customization
- Progress bar for playback position
- Playback controls positioning (above or below metadata)
- Show/hide playback controls with hover effects

#### Behavior Settings

- Window layering: Above windows, below windows, or float on track change
- Show on all desktops or current only
- **Hide on pause** (auto-fade when music stops)
- Ignore Mission Control toggle
- Automatic Dock avoidance
- Dock icon options (multiple styles or hidden)

#### Integrations

| Integration | Description |
|-------------|-------------|
| **Last.fm** | Full scrobbling support with customizable scrobble timing |
| **Spotify Web API** | Like tracks directly from Sleeve |
| **Apple Music** | Native favorites support |
| **Doppler** | Third-party music player support |

#### Keyboard Shortcuts

Global hotkeys with **custom HUD feedback window**:
- Play/pause
- Next/previous track
- Like track
- Volume up/down/mute
- Bring Sleeve to front

### What Sleeve Does NOT Have

- ❌ Notch integration
- ❌ Menu bar player
- ❌ Trackpad gesture support
- ❌ Haptic feedback
- ❌ Audio output device selection
- ❌ Waveform/equalizer visualization
- ❌ Song change notification animations (in notch style)

---

## Feature Comparison Matrix

| Category | Tuneful | Sleeve |
|----------|:-------:|:------:|
| **Display Modes** | | |
| Notch integration | ✅ | ❌ |
| Menu bar player | ✅ | ❌ |
| Desktop mini player | ✅ | ✅ |
| **Customization** | | |
| Saveable themes | ❌ | ✅ |
| Theme sharing/export | ❌ | ✅ |
| iCloud sync | ❌ | ✅ |
| Typography control | Basic | Extensive |
| Artwork shelving | ❌ | ✅ |
| **Interactions** | | |
| Trackpad gestures | ✅ | ❌ |
| Haptic feedback | ✅ | ❌ |
| Keyboard shortcuts | ✅ | ✅ |
| Keyboard shortcut HUD | ❌ | ✅ |
| **Integrations** | | |
| Spotify | ✅ | ✅ |
| Apple Music | ✅ | ✅ |
| Doppler | ❌ | ✅ |
| Last.fm scrobbling | ❌ | ✅ |
| Spotify like/save | ✅ | ✅ |
| **Features** | | |
| Audio output selection | ✅ | ❌ |
| Progress bar | ✅ | ✅ |
| Hide when not playing | ✅ | ✅ |
| Multi-monitor support | ✅ | ✅ |
| Waveform visualization | ✅ | ❌ |

---

## Market Positioning

```
                    HIGH CUSTOMIZATION
                           │
                           │
                    ┌──────┴──────┐
                    │   SLEEVE    │
                    └─────────────┘
                           │
    DESKTOP ───────────────┼─────────────── SYSTEM
    FOCUSED                │               INTEGRATED
                           │
                    ┌──────┴──────┐
                    │   TUNEFUL   │
                    └─────────────┘
                           │
                           │
                    LOW CUSTOMIZATION
```

---

## User Reviews Summary

### Tuneful Reviews

> "The notch display feature! It's one of those rare Mac apps that makes you feel like 'Oh, Apple should make this part of the OS.'"

> "Lots of options for how you want to control (eg. menubar, mini player, notch player) and just enough customization to be useful but not overwhelming."

### Sleeve Reviews

> "It seems like it ought to be built into MacOS. It strikes the perfect balance of simplicity and customizability."

> "The control it gives the user over the size, positioning, etc. is excellent."

---

## Opportunities for Differentiation

Based on this analysis, a new competitor could differentiate by:

1. **Combining strengths** — Notch/menu bar integration (Tuneful) + theme system (Sleeve)
2. **Adding missing features** — Features neither app has
3. **New integrations** — Support for more music services
4. **Platform expansion** — iOS companion app, widgets
5. **Social features** — Share what you're listening to
6. **AI features** — Smart recommendations, mood detection

See [02-proposed-features.md](02-proposed-features.md) for detailed feature proposals.

---

## Sources

- Tuneful App Store: https://apps.apple.com/us/app/tuneful/id6739804295
- Tuneful Website: https://www.tuneful.dev/
- Sleeve App Store: https://apps.apple.com/us/app/sleeve/id1606145041
- Sleeve Website: https://replay.software/sleeve
