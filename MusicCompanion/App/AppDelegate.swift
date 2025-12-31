import AppKit
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
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

    private func setupMusicService() {
        // Initialize music service and subscribe to updates
        Task {
            await AppState.shared.musicServiceManager.startMonitoring()
        }
    }
}
