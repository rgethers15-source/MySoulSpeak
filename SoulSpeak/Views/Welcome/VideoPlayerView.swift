import SwiftUI
import AVKit

/// Full-screen video player that plays bundled MP4 files.
/// Optimized for smooth playback with async loading and preroll.
struct VideoPlayerView: UIViewRepresentable {
    let videoName: String
    let fileExtension: String
    var looping: Bool = false
    var onVideoFinished: (() -> Void)? = nil

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.configure(videoName: videoName, fileExtension: fileExtension, looping: looping)
        view.onVideoFinished = onVideoFinished
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {}
}

/// UIView subclass that hosts an AVPlayerLayer for smooth video playback.
/// Loads asset asynchronously and only plays when ready — no lag.
class PlayerUIView: UIView {
    private var player: AVPlayer?
    private var looping = false
    var onVideoFinished: (() -> Void)?

    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    func configure(videoName: String, fileExtension: String, looping: Bool) {
        self.looping = looping

        guard let url = Bundle.main.url(forResource: videoName, withExtension: fileExtension) else {
            print("[SoulSpeak] Video not found: \(videoName).\(fileExtension)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.onVideoFinished?()
            }
            return
        }

        // Load asset asynchronously to prevent main thread lag
        let asset = AVURLAsset(url: url, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: false // Faster load
        ])

        // Load playable status async
        Task { @MainActor in
            do {
                let isPlayable = try await asset.load(.isPlayable)
                guard isPlayable else {
                    self.onVideoFinished?()
                    return
                }
                self.setupPlayer(with: asset)
            } catch {
                print("[SoulSpeak] Video asset load error: \(error)")
                self.onVideoFinished?()
            }
        }
    }

    private func setupPlayer(with asset: AVURLAsset) {
        let playerItem = AVPlayerItem(asset: asset)
        // Small buffer for fast start
        playerItem.preferredForwardBufferDuration = 2.0

        player = AVPlayer(playerItem: playerItem)
        // Let it buffer slightly before playing to avoid stutter
        player?.automaticallyWaitsToMinimizeStalling = true

        let avPlayerLayer = layer as! AVPlayerLayer
        avPlayerLayer.player = player
        avPlayerLayer.videoGravity = .resizeAspectFill
        avPlayerLayer.backgroundColor = UIColor.black.cgColor

        // Observe when video ends
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoDidEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        // Play when ready (observe status)
        playerItem.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status", let item = object as? AVPlayerItem {
            if item.status == .readyToPlay {
                player?.play()
                item.removeObserver(self, forKeyPath: "status")
            } else if item.status == .failed {
                print("[SoulSpeak] Video failed to load: \(item.error?.localizedDescription ?? "unknown")")
                DispatchQueue.main.async { [weak self] in
                    self?.onVideoFinished?()
                }
                item.removeObserver(self, forKeyPath: "status")
            }
        }
    }

    @objc private func videoDidEnd() {
        if looping {
            player?.seek(to: .zero)
            player?.play()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.onVideoFinished?()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        (layer as? AVPlayerLayer)?.frame = bounds
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        player?.pause()
        player = nil
    }
}

/// SwiftUI wrapper for a full-screen background video with skip button.
/// Optimized: shows black background instantly, video fades in when ready.
struct FullScreenVideoBackground: View {
    let videoName: String
    let fileExtension: String
    var looping: Bool = true
    var onFinished: (() -> Void)? = nil

    @State private var showSkip = false
    @State private var videoReady = false

    var body: some View {
        ZStack {
            // Solid black background (prevents flash/white frame)
            Color.black.ignoresSafeArea()

            // Video player
            VideoPlayerView(
                videoName: videoName,
                fileExtension: fileExtension,
                looping: looping,
                onVideoFinished: onFinished
            )
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .ignoresSafeArea()

            // Skip button (appears after 2 seconds for non-looping videos)
            if showSkip && !looping {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { onFinished?() }) {
                            Text("Skip")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color.black.opacity(0.5)))
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 60)
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            if !looping {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    showSkip = true
                }
            }
        }
    }
}
