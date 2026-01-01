import SwiftUI

struct NotchPlayerView: View {
    @ObservedObject var viewModel: NotchPlayerViewModel
    let isExpanded: Bool

    // Progress bar interaction state
    @State private var isDragging = false
    @State private var dragProgress: Double = 0

    // Layout constants
    private let notchWidth: CGFloat = 200
    private let notchHeight: CGFloat = 32
    private let expandedHeight: CGFloat = 170
    private let expandedWidth: CGFloat = 380
    private let cornerRadius: CGFloat = 20

    var body: some View {
        expandedView
    }

    // MARK: - Expanded View (wraps around notch)

    private var expandedView: some View {
        VStack(spacing: 0) {
            // Top area that wraps around the notch
            HStack(spacing: 0) {
                // Left panel - album art
                leftPanel
                    .frame(width: (expandedWidth - notchWidth) / 2, height: notchHeight)

                // Notch space (transparent)
                Color.clear
                    .frame(width: notchWidth, height: notchHeight)

                // Right panel - visualizer
                rightPanel
                    .frame(width: (expandedWidth - notchWidth) / 2, height: notchHeight)
            }

            // Main content below notch
            mainContentView
        }
        .background(
            ExpandedNotchShape(notchWidth: notchWidth, topCornerRadius: notchHeight, bottomCornerRadius: notchHeight)
                .fill(Color.black)
        )
        .frame(width: expandedWidth, height: expandedHeight)
    }

    private var leftPanel: some View {
        Color.clear
    }

    private var rightPanel: some View {
        HStack {
            Spacer()
            if viewModel.isPlaying {
                MiniVisualizerView()
                    .frame(width: 24, height: 16)
                    .padding(.trailing, 16)
            }
        }
    }

    private var mainContentView: some View {
        HStack(spacing: 16) {
            // Large album artwork
            largeArtwork
                .padding(.leading, 20)

            // Track info and controls
            VStack(spacing: 8) {
                // Track info
                VStack(spacing: 2) {
                    Text(viewModel.currentTrack?.title ?? "Not Playing")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(viewModel.currentTrack?.artist ?? "—")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 8)

                Spacer()

                // Progress bar
                progressView

                // Playback controls
                controlsView
                    .padding(.bottom, 12)
            }
            .padding(.trailing, 20)
        }
    }

    private var largeArtwork: some View {
        Group {
            if let artworkData = viewModel.currentTrack?.artworkData,
               let nsImage = NSImage(data: artworkData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.4))
                    }
            }
        }
    }

    // MARK: - Progress View

    private var progressView: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                let displayProgress = isDragging ? dragProgress : viewModel.progress

                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(.white.opacity(0.2))
                        .frame(height: 4)

                    // Progress fill
                    Capsule()
                        .fill(.white)
                        .frame(width: max(0, geometry.size.width * displayProgress), height: 4)

                    // Scrubber handle (visible when dragging)
                    if isDragging {
                        Circle()
                            .fill(.white)
                            .frame(width: 12, height: 12)
                            .offset(x: max(0, min(geometry.size.width - 12, geometry.size.width * displayProgress - 6)))
                    }
                }
                .frame(height: 12)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            dragProgress = max(0, min(1, value.location.x / geometry.size.width))
                        }
                        .onEnded { value in
                            let finalProgress = max(0, min(1, value.location.x / geometry.size.width))
                            viewModel.seek(to: finalProgress)
                            isDragging = false
                        }
                )
            }
            .frame(height: 12)

            HStack {
                Text(isDragging ? formatTime(dragProgress * (viewModel.currentTrack?.duration ?? 0)) : viewModel.elapsedTimeString)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .monospacedDigit()

                Spacer()

                Text(viewModel.remainingTimeString)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .monospacedDigit()
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Playback Controls

    private var controlsView: some View {
        HStack(spacing: 40) {
            Button(action: viewModel.previousTrack) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .buttonStyle(.plain)

            Button(action: viewModel.togglePlayPause) {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            Button(action: viewModel.nextTrack) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Expanded Notch Shape (wraps around notch)

private struct ExpandedNotchShape: Shape {
    let notchWidth: CGFloat
    let topCornerRadius: CGFloat
    let bottomCornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let notchStart = (rect.width - notchWidth) / 2
        let notchEnd = notchStart + notchWidth
        let topHeight: CGFloat = topCornerRadius * 2

        // Start at bottom-left
        path.move(to: CGPoint(x: bottomCornerRadius, y: rect.height))

        // Bottom-left corner
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height - bottomCornerRadius),
            control: CGPoint(x: 0, y: rect.height)
        )

        // Left edge up
        path.addLine(to: CGPoint(x: 0, y: topCornerRadius))

        // Top-left corner
        path.addQuadCurve(
            to: CGPoint(x: topCornerRadius, y: 0),
            control: CGPoint(x: 0, y: 0)
        )

        // Top edge to notch
        path.addLine(to: CGPoint(x: notchStart, y: 0))

        // Notch cutout (goes up into the notch area)
        path.addLine(to: CGPoint(x: notchStart, y: -topHeight))
        path.addLine(to: CGPoint(x: notchEnd, y: -topHeight))
        path.addLine(to: CGPoint(x: notchEnd, y: 0))

        // Top edge from notch to right
        path.addLine(to: CGPoint(x: rect.width - topCornerRadius, y: 0))

        // Top-right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: topCornerRadius),
            control: CGPoint(x: rect.width, y: 0)
        )

        // Right edge down
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - bottomCornerRadius))

        // Bottom-right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.width - bottomCornerRadius, y: rect.height),
            control: CGPoint(x: rect.width, y: rect.height)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: bottomCornerRadius, y: rect.height))

        return path
    }
}

// MARK: - Mini Visualizer

private struct MiniVisualizerView: View {
    @State private var heights: [CGFloat] = [0.3, 0.6, 0.4, 0.7]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0 ..< 4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(.white.opacity(0.7))
                    .frame(width: 3, height: 16 * heights[index])
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                heights = [0.7, 0.4, 0.8, 0.5]
            }
        }
    }
}

// MARK: - Preview

#Preview("Expanded") {
    NotchPlayerView(viewModel: NotchPlayerViewModel(), isExpanded: true)
        .frame(width: 500, height: 250)
        .background(Color.gray.opacity(0.3))
}
