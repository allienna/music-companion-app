import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            ShortcutsSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 300)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    var body: some View {
        Form {
            LaunchAtLogin.Toggle("Launch at login")

            Section("Menu Bar") {
                Toggle("Show song info in menu bar", isOn: .constant(true))
                Toggle("Show album art in menu bar", isOn: .constant(false))
            }

            Section("Notifications") {
                Toggle("Show now playing notifications", isOn: .constant(true))
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Appearance Settings

struct AppearanceSettingsView: View {
    var body: some View {
        Form {
            Section("Theme") {
                Picker("Appearance", selection: .constant(0)) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
            }

            Section("Mini Player") {
                Toggle("Show mini player", isOn: .constant(false))
                Picker("Style", selection: .constant(0)) {
                    Text("Compact").tag(0)
                    Text("Horizontal").tag(1)
                    Text("Gradient").tag(2)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Shortcuts Settings

struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section("Playback") {
                KeyboardShortcuts.Recorder("Play/Pause", name: .togglePlayPause)
                KeyboardShortcuts.Recorder("Next Track", name: .nextTrack)
                KeyboardShortcuts.Recorder("Previous Track", name: .previousTrack)
            }

            Section("Window") {
                KeyboardShortcuts.Recorder("Show/Hide Mini Player", name: .toggleMiniPlayer)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - About Settings

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.house")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("Music Companion")
                .font(.title)

            Text("Version 1.0.0")
                .foregroundStyle(.secondary)

            Text("A beautiful music companion for your Mac")
                .foregroundStyle(.tertiary)

            Spacer()

            Link("GitHub Repository", destination: URL(string: "https://github.com/allienna/music-companion-app")!)
                .buttonStyle(.link)
        }
        .padding()
    }
}

// MARK: - Keyboard Shortcuts

extension KeyboardShortcuts.Name {
    static let togglePlayPause = Self("togglePlayPause")
    static let nextTrack = Self("nextTrack")
    static let previousTrack = Self("previousTrack")
    static let toggleMiniPlayer = Self("toggleMiniPlayer")
}

#Preview {
    SettingsView()
}
