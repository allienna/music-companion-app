import AppKit
import Combine

/// A custom NSView that displays scrolling text when content exceeds the available width.
/// Used for the menu bar status item to show track information with a marquee effect.
final class MarqueeView: NSView {
    // MARK: - Properties

    private let textField: NSTextField = {
        let field = NSTextField(labelWithString: "")
        field.font = NSFont.menuBarFont(ofSize: 0)
        field.textColor = .labelColor
        field.lineBreakMode = .byClipping
        field.cell?.truncatesLastVisibleLine = false
        return field
    }()

    private var scrollTimer: Timer?
    private var scrollOffset: CGFloat = 0
    private var isScrolling = false
    private var pauseCounter = 0

    /// The text to display with marquee effect
    var text: String = "" {
        didSet {
            textField.stringValue = text
            resetScroll()
            updateScrollingState()
        }
    }

    /// The fixed width for the marquee view
    var maxWidth: CGFloat = 200 {
        didSet {
            invalidateIntrinsicContentSize()
            updateScrollingState()
        }
    }

    /// Speed of scrolling animation (points per tick)
    var scrollSpeed: CGFloat = 1.0

    /// Pause duration at the start/end of scroll (in timer ticks, ~60 ticks = 1 second)
    var pauseDuration: Int = 90

    /// Gap between repeated text during scroll
    var textGap: CGFloat = 40

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
    }

    // MARK: - Setup

    private func setupView() {
        wantsLayer = true
        layer?.masksToBounds = true

        addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
    }

    // MARK: - Layout

    override var intrinsicContentSize: NSSize {
        let textWidth = textField.intrinsicContentSize.width
        let width = min(textWidth, maxWidth)
        return NSSize(width: width, height: textField.intrinsicContentSize.height)
    }

    override func layout() {
        super.layout()
        updateTextFieldFrame()
    }

    private func updateTextFieldFrame() {
        let textWidth = textField.intrinsicContentSize.width
        let height = bounds.height

        if textWidth <= bounds.width {
            // Text fits, center it
            textField.frame = NSRect(
                x: 0,
                y: 0,
                width: textWidth,
                height: height
            )
        } else {
            // Text needs scrolling, position based on offset
            textField.frame = NSRect(
                x: -scrollOffset,
                y: 0,
                width: textWidth,
                height: height
            )
        }
    }

    // MARK: - Scrolling

    private func updateScrollingState() {
        let textWidth = textField.intrinsicContentSize.width

        if textWidth > maxWidth && !text.isEmpty {
            startScrolling()
        } else {
            stopScrolling()
        }
    }

    private func startScrolling() {
        guard !isScrolling else { return }
        isScrolling = true
        pauseCounter = pauseDuration

        scrollTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopScrolling() {
        isScrolling = false
        scrollTimer?.invalidate()
        scrollTimer = nil
        resetScroll()
    }

    private func resetScroll() {
        scrollOffset = 0
        pauseCounter = pauseDuration
        updateTextFieldFrame()
    }

    private func tick() {
        let textWidth = textField.intrinsicContentSize.width
        let scrollDistance = textWidth - maxWidth + textGap

        // Handle pause at start
        if pauseCounter > 0 {
            pauseCounter -= 1
            return
        }

        // Scroll the text
        scrollOffset += scrollSpeed

        // Reset when we've scrolled enough
        if scrollOffset >= scrollDistance {
            scrollOffset = 0
            pauseCounter = pauseDuration
        }

        updateTextFieldFrame()
    }

    // MARK: - Icon Support

    /// Sets the content with an optional icon
    func setContent(icon: NSImage?, text: String) {
        self.text = text

        // If we have an icon, we'd need to handle it differently
        // For now, the icon is handled separately in the status item button
    }
}

// MARK: - Menu Bar Integration

extension MarqueeView {
    /// Creates a marquee view configured for menu bar use
    static func forMenuBar(maxWidth: CGFloat = 200) -> MarqueeView {
        let view = MarqueeView()
        view.maxWidth = maxWidth
        view.scrollSpeed = 0.5
        view.pauseDuration = 120 // 2 seconds pause
        view.textGap = 50
        return view
    }
}
