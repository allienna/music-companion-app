import AppKit
import Combine

/// A custom NSView that displays scrolling text when content exceeds the available width.
/// Uses Core Animation for smooth, performant scrolling with edge fade effects.
final class MarqueeView: NSView {
    // MARK: - Properties

    private let textLayer: CATextLayer = {
        let layer = CATextLayer()
        layer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        layer.alignmentMode = .left
        layer.truncationMode = .none
        return layer
    }()

    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        return layer
    }()

    private let containerLayer = CALayer()
    private var displayLink: CVDisplayLink?
    private var scrollOffset: CGFloat = 0
    private var isScrolling = false
    private var pauseFrames = 0
    private var lastTimestamp: CFTimeInterval = 0
    private var appearanceObserver: NSKeyValueObservation?

    /// The text to display with marquee effect
    var text: String = "" {
        didSet {
            updateTextLayer()
            resetScroll()
            updateScrollingState()
        }
    }

    /// The fixed width for the marquee view
    var maxWidth: CGFloat = 200 {
        didSet {
            invalidateIntrinsicContentSize()
            updateGradientMask()
            updateScrollingState()
        }
    }

    /// Speed of scrolling animation (points per second)
    var scrollSpeed: CGFloat = 30.0

    /// Pause duration at the start/end of scroll (in seconds)
    var pauseDuration: TimeInterval = 2.0

    /// Gap between text cycles
    var textGap: CGFloat = 50

    /// Whether to show fade effect at edges
    var showEdgeFade: Bool = true {
        didSet { updateGradientMask() }
    }

    /// Width of the fade effect
    var fadeWidth: CGFloat = 15

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    deinit {
        stopScrolling()
        appearanceObserver?.invalidate()
    }

    // MARK: - Setup

    private func setupView() {
        wantsLayer = true
        layer?.masksToBounds = true

        // Setup container layer
        containerLayer.masksToBounds = false
        layer?.addSublayer(containerLayer)

        // Setup text layer
        containerLayer.addSublayer(textLayer)

        // Setup gradient mask for fade effect
        updateGradientMask()

        // Observe appearance changes for theme support
        appearanceObserver = observe(\.effectiveAppearance, options: [.new]) { [weak self] _, _ in
            self?.updateColors()
        }

        updateColors()
    }

    // MARK: - Theme Support

    private func updateColors() {
        let isDarkMode = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

        // Update text color based on theme
        textLayer.foregroundColor = (isDarkMode ? NSColor.white : NSColor.black).cgColor

        // Update gradient colors for edge fade
        updateGradientMask()
    }

    private func updateGradientMask() {
        guard showEdgeFade else {
            containerLayer.mask = nil
            return
        }

        let textWidth = calculateTextWidth()
        let needsScrolling = textWidth > maxWidth && !text.isEmpty

        if needsScrolling {
            // Create fade gradient at edges
            gradientLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)

            let fadeRatio = fadeWidth / bounds.width
            gradientLayer.colors = [
                NSColor.clear.cgColor,
                NSColor.black.cgColor,
                NSColor.black.cgColor,
                NSColor.clear.cgColor,
            ]
            gradientLayer.locations = [
                0,
                NSNumber(value: Float(fadeRatio)),
                NSNumber(value: Float(1 - fadeRatio)),
                1,
            ]
            containerLayer.mask = gradientLayer
        } else {
            containerLayer.mask = nil
        }
    }

    // MARK: - Text Layer

    private func updateTextLayer() {
        // Use menu bar font
        let font = NSFont.menuBarFont(ofSize: 0)
        textLayer.font = font
        textLayer.fontSize = font.pointSize
        textLayer.string = text

        // Calculate size
        let textWidth = calculateTextWidth()
        let height = bounds.height > 0 ? bounds.height : font.pointSize + 4

        textLayer.frame = CGRect(x: 0, y: 0, width: textWidth, height: height)
    }

    private func calculateTextWidth() -> CGFloat {
        guard !text.isEmpty else { return 0 }

        let font = NSFont.menuBarFont(ofSize: 0)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let size = (text as NSString).size(withAttributes: attributes)
        return ceil(size.width)
    }

    // MARK: - Layout

    override var intrinsicContentSize: NSSize {
        let textWidth = calculateTextWidth()
        let width = min(textWidth, maxWidth)
        let font = NSFont.menuBarFont(ofSize: 0)
        return NSSize(width: width, height: font.pointSize + 4)
    }

    override func layout() {
        super.layout()

        containerLayer.frame = bounds
        updateTextLayer()
        updateGradientMask()
        updateTextPosition()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateColors()
    }

    private func updateTextPosition() {
        let textWidth = calculateTextWidth()

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        if textWidth <= bounds.width {
            // Text fits, left-align it
            textLayer.frame.origin.x = 0
        } else {
            // Text needs scrolling, position based on offset
            textLayer.frame.origin.x = -scrollOffset
        }

        // Center vertically
        textLayer.frame.origin.y = (bounds.height - textLayer.frame.height) / 2

        CATransaction.commit()
    }

    // MARK: - Scrolling

    private func updateScrollingState() {
        let textWidth = calculateTextWidth()

        if textWidth > maxWidth && !text.isEmpty {
            startScrolling()
        } else {
            stopScrolling()
        }
    }

    private func startScrolling() {
        guard !isScrolling else { return }
        isScrolling = true
        pauseFrames = Int(pauseDuration * 60)
        lastTimestamp = CACurrentMediaTime()

        // Use CADisplayLink for smooth animation
        var displayLinkRef: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLinkRef)

        if let link = displayLinkRef {
            displayLink = link

            let callback: CVDisplayLinkOutputCallback = { _, _, _, _, _, userInfo -> CVReturn in
                let view = Unmanaged<MarqueeView>.fromOpaque(userInfo!).takeUnretainedValue()
                DispatchQueue.main.async {
                    view.tick()
                }
                return kCVReturnSuccess
            }

            let userInfo = Unmanaged.passUnretained(self).toOpaque()
            CVDisplayLinkSetOutputCallback(link, callback, userInfo)
            CVDisplayLinkStart(link)
        }
    }

    private func stopScrolling() {
        isScrolling = false

        if let link = displayLink {
            CVDisplayLinkStop(link)
            displayLink = nil
        }

        resetScroll()
    }

    private func resetScroll() {
        scrollOffset = 0
        pauseFrames = Int(pauseDuration * 60)
        updateTextPosition()
    }

    private func tick() {
        guard isScrolling else { return }

        let currentTime = CACurrentMediaTime()
        let deltaTime = currentTime - lastTimestamp
        lastTimestamp = currentTime

        // Handle pause at start/end
        if pauseFrames > 0 {
            pauseFrames -= 1
            return
        }

        let textWidth = calculateTextWidth()
        let scrollDistance = textWidth - maxWidth + textGap

        // Apply easing near the end of scroll
        let progress = scrollOffset / scrollDistance
        var speed = scrollSpeed

        // Ease out near the end (last 20%)
        if progress > 0.8 {
            let easeProgress = (progress - 0.8) / 0.2
            speed *= 1.0 - (easeProgress * 0.7) // Slow down to 30% speed
        }

        // Ease in at the start (first 10%)
        if progress < 0.1 {
            let easeProgress = progress / 0.1
            speed *= 0.3 + (easeProgress * 0.7) // Start at 30% and accelerate
        }

        // Update scroll position
        scrollOffset += speed * CGFloat(deltaTime)

        // Reset when we've scrolled enough
        if scrollOffset >= scrollDistance {
            scrollOffset = 0
            pauseFrames = Int(pauseDuration * 60)
        }

        updateTextPosition()
    }
}

// MARK: - Menu Bar Integration

extension MarqueeView {
    /// Creates a marquee view configured for menu bar use
    static func forMenuBar(maxWidth: CGFloat = 200) -> MarqueeView {
        let view = MarqueeView()
        view.maxWidth = maxWidth
        view.scrollSpeed = 35.0 // Points per second
        view.pauseDuration = 2.0 // 2 seconds pause
        view.textGap = 60
        view.showEdgeFade = true
        view.fadeWidth = 12
        return view
    }
}
