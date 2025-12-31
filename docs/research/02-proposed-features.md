# Proposed Features for Differentiation

**Last Updated:** December 31, 2024  
**Status:** ✅ Complete

## Overview

This document outlines unique features to differentiate our music companion app from Tuneful and Sleeve, based on competitor analysis and market research.

---

## 1. Combined Best Features (Foundation)

The first layer of differentiation is combining the best of both competitors:

| From Tuneful | From Sleeve |
|--------------|-------------|
| Notch integration | Full theme system with export/import |
| Menu bar player | Last.fm scrobbling |
| Trackpad gestures + haptics | Extensive typography customization |
| Audio output device selection | Artwork shelving effects |
| Waveform visualization | iCloud sync |
| Song change notifications | Keyboard shortcut HUD |

**Priority:** These combined features form the MVP foundation.

---

## 2. Missing Features (Neither App Has)

### 2.1 Real-Time Lyrics Display 🎤

**What:** Floating lyrics window with synchronized, word-by-word highlighting

**Why:** Neither Tuneful nor Sleeve offers lyrics. Apps like LyricFever and LyricGlow prove strong demand.

**Features:**
- Word-by-word sync with karaoke-style highlighting
- Floating window (always-on-top option)
- Mini lyrics mode in notch/menu bar (single line, scrolling)
- Lyrics translation (powered by Apple Translation API)
- Multiple lyrics sources: Spotify API, LRCLIB, Musixmatch
- Customizable font, size, colors, glow effects
- RTL language support (Arabic, Hebrew, Persian)

**Technical Approach:**
- Map Apple Music songs to Spotify via ISRC codes (like LyricFever)
- Cache lyrics locally with CoreData
- Use Spotify's time-synced lyrics API

---

### 2.2 Discord Rich Presence Integration 🎮

**What:** Show what you're listening to on your Discord profile

**Why:** Music Presence app has huge community demand. Neither competitor offers this.

**Features:**
- Display track, artist, album, and progress on Discord status
- Album artwork in Discord profile
- "Listening to [Song]" or "Listening to [Artist]" modes
- Toggle for music vs. podcasts
- Option to hide certain tracks/artists
- Animated album art support (if Discord allows)

**Technical Approach:**
- Discord Rich Presence SDK
- Run as background service
- Handle Discord connection state gracefully

---

### 2.3 Listening Statistics & Analytics 📊

**What:** Personal listening insights and visualizations

**Why:** Spotify Wrapped is massively popular. No desktop companion app offers this.

**Features:**
- **Daily/Weekly/Monthly stats:**
  - Top artists, albums, tracks
  - Total listening time
  - Genre breakdown
  - Listening patterns (time of day, day of week)
- **Visualizations:**
  - Heat maps (when you listen)
  - Pie charts (genre distribution)
  - Trend lines (listening over time)
- **"Wrapped-style" summaries:**
  - Monthly mini-wrapped
  - Shareable cards for social media
- **Integration with Last.fm** for historical data

**Technical Approach:**
- Local SQLite database for play history
- Charts with Swift Charts framework
- Export to image for sharing

---

### 2.4 macOS Widgets (Notification Center) 🔲

**What:** Native macOS widgets for desktop and Notification Center

**Why:** Users have been requesting this for years (see Spotify Community). Neither app offers true widgets.

**Features:**
- Small widget: Album art only
- Medium widget: Album art + track info
- Large widget: Full player with controls
- Interactive widgets (macOS 14+): Play/pause, skip
- Widget gallery with multiple styles

**Technical Approach:**
- WidgetKit framework
- App Intents for interactivity
- Background refresh for updates

---

### 2.5 Queue & Up Next Preview 📋

**What:** See and manage upcoming tracks

**Why:** Neither app shows what's coming next.

**Features:**
- "Up Next" preview (next 3-5 tracks)
- Drag to reorder queue
- Remove tracks from queue
- Add current track to queue position
- Queue visualization in mini player

**Technical Approach:**
- Spotify API for queue access
- Apple Music queue via MusicKit
- Local cache for responsiveness

---

### 2.6 Smart Notifications & Focus Integration 🔔

**What:** Intelligent notifications and Focus mode awareness

**Why:** No competitor integrates with macOS Focus modes.

**Features:**
- **Focus mode integration:**
  - Different appearance per Focus mode
  - Auto-hide during "Do Not Disturb"
  - Show/hide based on Work, Personal, etc.
- **Smart notifications:**
  - "You've been listening for 2 hours"
  - "New release from [Followed Artist]"
  - "Your top artist this week: [Artist]"
- **Pomodoro-friendly:** Pause notifications during focus sessions

**Technical Approach:**
- FocusFilter API (macOS 15+)
- UserNotifications framework
- Background monitoring

---

## 3. New Integrations

### 3.1 Additional Music Services

| Service | Priority | Difficulty |
|---------|----------|------------|
| **YouTube Music** | High | Medium (needs browser integration) |
| **Tidal** | Medium | Medium |
| **Deezer** | Medium | Medium |
| **SoundCloud** | Low | Hard |
| **Pandora** | Low | Hard |

### 3.2 Social & Sharing Integrations

| Integration | Feature |
|-------------|---------|
| **Last.fm** | Full scrobbling + stats import |
| **Discord** | Rich Presence status |
| **ListenBrainz** | Open-source scrobbling alternative |
| **Twitter/X** | Share what you're listening to |
| **Mastodon** | ActivityPub sharing |
| **iMessage** | Share song cards |

### 3.3 Utility Integrations

| Integration | Feature |
|-------------|---------|
| **Shortcuts** | Automation actions |
| **Raycast** | Extension for quick controls |
| **Alfred** | Workflow integration |
| **Stream Deck** | Hardware button controls |
| **HomeKit** | "Set the mood" scenes |

---

## 4. Platform Expansion

### 4.1 iOS Companion App 📱

**Features:**
- Remote control for Mac app
- View stats synced from Mac
- Widgets for iPhone/iPad
- Apple Watch complication

### 4.2 Cross-Device Sync

- iCloud sync for:
  - Themes
  - Settings
  - Listening history (optional)
  - Statistics

---

## 5. AI/Smart Features 🤖

### 5.1 Mood Detection

- Analyze current music mood (energetic, calm, sad, happy)
- Dynamic theme colors based on mood
- Suggest Focus mode based on music

### 5.2 Smart Controls

- "Play something similar" action
- Auto-adjust volume based on time of day
- Smart shuffle improvements

### 5.3 AI Artist Bios

- Quick AI-summarized artist info
- "Why you might like this" explanations
- Genre/style context

---

## 6. Feature Prioritization Matrix

| Feature | Impact | Effort | Priority |
|---------|--------|--------|----------|
| Combined best features | High | High | P0 (MVP) |
| Real-time lyrics | High | Medium | P1 |
| Discord Rich Presence | High | Low | P1 |
| macOS Widgets | High | Medium | P1 |
| Listening statistics | Medium | Medium | P2 |
| Queue preview | Medium | Low | P2 |
| Focus integration | Medium | Low | P2 |
| YouTube Music support | Medium | High | P3 |
| iOS companion | Medium | High | P3 |
| AI features | Low | High | P4 |

---

## 7. Competitive Positioning

```
                          LYRICS
                            │
              ┌─────────────┼─────────────┐
              │             │             │
              │    ┌────────┴────────┐    │
              │    │   OUR APP       │    │
              │    │  (All features) │    │
              │    └────────┬────────┘    │
              │             │             │
    SYSTEM ───┼─────────────┼─────────────┼─── DESKTOP
    INTEGRATION             │             │    AESTHETIC
              │   ┌─────────┴─────┐       │
              │   │    TUNEFUL    │       │
              │   └───────────────┘       │
              │             │     ┌───────┴───────┐
              │             │     │    SLEEVE     │
              │             │     └───────────────┘
              │             │             │
              └─────────────┼─────────────┘
                            │
                         STATS/
                        ANALYTICS
```

**Our unique value proposition:**
> "The only music companion that combines notch integration, full customization, real-time lyrics, Discord status, and personal analytics — all in one native app."

---

## 8. Naming Ideas

| Name | Available? | Notes |
|------|------------|-------|
| Melodic | Check | Evokes music, pleasant |
| Cadence | Check | Musical term, rhythm |
| Vinyl | Likely taken | Nostalgia, but overused |
| Tempo | Check | Musical term |
| Harmonic | Check | Musical, harmonious |
| Sonora | Check | Musical, Spanish for "sonorous" |
| Groove | Likely taken | Fun, musical |
| Notation | Check | Musical, suggests display |

---

## Sources & Inspiration

- LyricFever: https://github.com/aviwad/LyricFever
- LyricGlow: https://amirteymoori.com/lyricglow-real-time-lyrics-macos/
- Music Presence: https://musicpresence.app/
- bijou.fm: https://www.bijou.fm/
- Spotify Community requests for widgets
- Last.fm Discord integration requests
