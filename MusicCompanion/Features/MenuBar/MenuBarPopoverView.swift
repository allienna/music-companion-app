import SwiftUI

struct MenuBarPopoverView: View {
    @Environment(\.openSettings) private var openSettings
    @StateObject private var viewModel = MenuBarViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Album Art
            albumArtView
                .padding(.top, 24)
                .padding(.bottom, 12)

            // Track Info - fixed height to prevent layout shifts
            trackInfoView
                .frame(height: 50)
                .padding(.horizontal, 16)

            // Playback Controls
            playbackControlsView
                .padding(.vertical, 10)

            // Progress Bar
            progressView
                .padding(.horizontal, 20)

            Divider()
                .padding(.horizontal, 16)
                .padding(.top, 12)

            // Quick Actions
            quickActionsView
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
        .frame(width: 280, height: 360)
    }

    // MARK: - Album Art

    private var albumArtView: some View {
        Group {
            if let artworkData = viewModel.currentTrack?.artworkData,
               let nsImage = NSImage(data: artworkData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [.gray.opacity(0.2), .gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(.secondary)
                    }
            }
        }
    }

    // MARK: - Track Info

    private var trackInfoView: some View {
        VStack(spacing: 2) {
            // Title - always present
            Text(viewModel.currentTrack?.title ?? "Not Playing")
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity)

            // Artist - always present
            Text(viewModel.currentTrack?.artist ?? "—")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity)

            // Album - always reserve space even if empty
            Text(viewModel.currentTrack?.album ?? " ")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity)
                .opacity(viewModel.currentTrack?.album != nil ? 1 : 0)
        }
    }

    // MARK: - Playback Controls

    private var playbackControlsView: some View {
        HStack(spacing: 36) {
            PlaybackButton(
                systemName: "backward.fill",
                size: .medium,
                action: viewModel.previousTrack
            )

            PlaybackButton(
                systemName: viewModel.isPlaying ? "pause.fill" : "play.fill",
                size: .large,
                action: viewModel.togglePlayPause
            )

            PlaybackButton(
                systemName: "forward.fill",
                size: .medium,
                action: viewModel.nextTrack
            )
        }
    }

    // MARK: - Progress View

    private var progressView: some View {
        VStack(spacing: 4) {
            ProgressSlider(
                progress: viewModel.progress,
                onSeek: { newProgress in
                    viewModel.seek(to: newProgress)
                }
            )

            HStack {
                Text(viewModel.elapsedTimeString)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .frame(width: 36, alignment: .leading)

                Spacer()

                Text(viewModel.remainingTimeString)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .frame(width: 36, alignment: .trailing)
            }
        }
    }

    // MARK: - Quick Actions

    @ObservedObject private var appState = AppState.shared

    private var quickActionsView: some View {
        HStack {
            ActionButton(
                systemName: viewModel.isLiked ? "heart.fill" : "heart",
                isActive: viewModel.isLiked,
                action: viewModel.toggleLike
            )

            Spacer()

            ActionButton(
                systemName: appState.showLyrics ? "text.quote.rtl" : "text.quote",
                isActive: appState.showLyrics,
                action: { appState.showLyrics.toggle() }
            )
            .help("Toggle Lyrics")

            Spacer()

            ActionButton(
                systemName: "gear",
                action: { openSettings() }
            )
        }
    }
}

// MARK: - Playback Button

private struct PlaybackButton: View {
    enum Size {
        case medium
        case large

        var fontSize: CGFloat {
            switch self {
            case .medium: return 18
            case .large: return 26
            }
        }

        var padding: CGFloat {
            switch self {
            case .medium: return 6
            case .large: return 10
            }
        }
    }

    let systemName: String
    let size: Size
    let action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size.fontSize, weight: .medium))
                .foregroundStyle(isPressed ? .primary : (isHovered ? .primary : .secondary))
                .frame(width: size.fontSize + size.padding * 2, height: size.fontSize + size.padding * 2)
                .contentShape(Rectangle())
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    let systemName: String
    var isActive: Bool = false
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isActive ? Color.red : (isHovered ? .primary : .secondary))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Progress Slider

private struct ProgressSlider: View {
    let progress: Double
    let onSeek: (Double) -> Void

    @State private var isHovered = false
    @State private var isDragging = false
    @State private var dragProgress: Double = 0

    private var displayProgress: Double {
        isDragging ? dragProgress : progress
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track background
                Capsule()
                    .fill(.quaternary)
                    .frame(height: isHovered || isDragging ? 5 : 3)

                // Progress fill
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: max(0, geometry.size.width * displayProgress), height: isHovered || isDragging ? 5 : 3)

                // Knob (only visible on hover/drag)
                if isHovered || isDragging {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 10, height: 10)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .offset(x: max(0, min(geometry.size.width - 10, geometry.size.width * displayProgress - 5)))
                }
            }
            .frame(height: 10)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let newProgress = max(0, min(1, value.location.x / geometry.size.width))
                        dragProgress = newProgress
                    }
                    .onEnded { value in
                        let newProgress = max(0, min(1, value.location.x / geometry.size.width))
                        onSeek(newProgress)
                        isDragging = false
                    }
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
        }
        .frame(height: 10)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.15), value: isDragging)
    }
}

#Preview {
    MenuBarPopoverView()
}
