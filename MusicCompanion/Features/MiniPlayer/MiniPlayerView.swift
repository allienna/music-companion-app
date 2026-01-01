import SwiftUI

struct MiniPlayerView: View {
    @ObservedObject var viewModel: MiniPlayerViewModel
    @State private var isDragging = false
    @State private var dragProgress: Double = 0

    var body: some View {
        HStack(spacing: 12) {
            // Album artwork
            artworkView

            // Track info and controls
            VStack(alignment: .leading, spacing: 6) {
                // Track info
                trackInfoView

                // Progress bar
                progressBar

                // Controls
                controlsView
            }
        }
        .padding(12)
        .frame(width: 280, height: 100)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }

    // MARK: - Artwork

    private var artworkView: some View {
        Group {
            if let artworkData = viewModel.currentTrack?.artworkData,
               let nsImage = NSImage(data: artworkData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 76, height: 76)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.quaternary)
                    .frame(width: 76, height: 76)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary)
                    }
            }
        }
    }

    // MARK: - Track Info

    private var trackInfoView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(viewModel.currentTrack?.title ?? "Not Playing")
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)

            Text(viewModel.currentTrack?.artist ?? "—")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geometry in
            let displayProgress = isDragging ? dragProgress : viewModel.progress

            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(.primary.opacity(0.15))
                    .frame(height: 3)

                // Progress fill
                Capsule()
                    .fill(.primary.opacity(0.6))
                    .frame(width: max(0, geometry.size.width * displayProgress), height: 3)
            }
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
        .frame(height: 3)
    }

    // MARK: - Controls

    private var controlsView: some View {
        HStack(spacing: 16) {
            Button(action: viewModel.previousTrack) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.primary.opacity(0.7))
            }
            .buttonStyle(.plain)

            Button(action: viewModel.togglePlayPause) {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            Button(action: viewModel.nextTrack) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.primary.opacity(0.7))
            }
            .buttonStyle(.plain)

            Spacer()

            // Time display
            Text(isDragging ? formatTime(dragProgress * (viewModel.currentTrack?.duration ?? 0)) : viewModel.elapsedTimeString)
                .font(.system(size: 9, weight: .medium).monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview {
    MiniPlayerView(viewModel: MiniPlayerViewModel())
        .padding()
        .background(Color.gray.opacity(0.3))
}
