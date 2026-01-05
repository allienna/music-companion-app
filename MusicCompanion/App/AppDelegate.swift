import AppKit
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var notchPlayerController: NotchPlayerController?
    private var miniPlayerController: MiniPlayerController?
    private var lyricsWindowController: LyricsWindowController?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupNotchPlayer()
        setupMiniPlayer()
        setupLyricsWindow()
        setupMusicService()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup resources
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Menu bar apps should not terminate when windows close
        false
    }

    // MARK: - Private

    private func setupMenuBar() {
        menuBarController = MenuBarController()
    }

    private func setupNotchPlayer() {
        // Always create the controller - it handles visibility based on current screen
        // This allows proper handling when switching between external display and built-in
        Task { @MainActor in
            self.notchPlayerController = NotchPlayerController()
        }
    }

    private func setupMiniPlayer() {
        Task { @MainActor in
            self.miniPlayerController = MiniPlayerController()
        }
    }

    private func setupLyricsWindow() {
        Task { @MainActor in
            self.lyricsWindowController = LyricsWindowController()
            // Initialize the lyrics service
            _ = LyricsService.shared
        }
    }

    private func setupMusicService() {
        Task {
            await AppState.shared.musicServiceManager.startMonitoring()
        }
    }
}
