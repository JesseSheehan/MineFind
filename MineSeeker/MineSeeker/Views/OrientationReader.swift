//
//  OrientationReader.swift
//  MineSeeker
//
//  Created by Jesse Sheehan on 9/15/25.
//

import SwiftUI
import Combine

//struct OrientationReader<Content: View>: View {
//    
//    @ViewBuilder var content: (Bool) -> Content
//    
//    var body: some View {
//        GeometryReader { geo in
//            let isLandscape = geo.size.width > geo.size.height
//            content(isLandscape)
//        }
//    }
//}

@Observable
final class OrientationModel: ObservableObject {
    var current: UIDeviceOrientation = UIDevice.current.orientation
    var previous: UIDeviceOrientation = .portrait
    
    var isLandscape: Bool {
        current.isLandscape
    }

    //DISPLAY METRICS (used for iPhone Duo)
    var windowSize: CGSize = .zero
    var safeAreaInsets = EdgeInsets()
    /// How far below the top of the window a camera (or other hardware) in a top corner reaches.
    var topCornerObstructionDepth: CGFloat = 0

    /// Shortest window side that can fit the huge minefield (e.g. iPhone Duo open, or iPad).
    static let largeFieldMinimumSide: CGFloat = 600

    /// True when the window is big enough to play on the huge minefield.
    var supportsLargeFields: Bool {
        UIDevice.isIPad || min(windowSize.width, windowSize.height) >= Self.largeFieldMinimumSide
    }

    /// An iPhone with a window big enough for the huge field, like the iPhone Duo when open.
    var isLargeIPhoneDisplay: Bool {
        UIDevice.isIPhone && supportsLargeFields
    }

    /// True on a small window with a camera in the corner, like the iPhone Duo's outside screen.
    /// The status bar sits either along one side (uneven side insets) or across the top,
    /// where the camera reaches below the top safe area.
    var isOuterDisplay: Bool {
        guard !supportsLargeFields else { return false }
        let hasUnevenSides = abs(safeAreaInsets.leading - safeAreaInsets.trailing) > 1
        let cameraReachesContent = topCornerObstructionDepth > safeAreaInsets.top + 1
        return hasUnevenSides || cameraReachesContent
    }

    /// Extra safe area that makes the left and right insets match, so content stays centered.
    var centeringInsets: EdgeInsets {
        // Landscape fields are wide enough to use the full width, so only center in portrait
        guard isOuterDisplay && !isLandscape else { return EdgeInsets() }
        let difference = safeAreaInsets.trailing - safeAreaInsets.leading
        return EdgeInsets(top: 0, leading: max(difference, 0), bottom: 0, trailing: max(-difference, 0))
    }

    /// Portrait on the outer display, which is too short for the regular in-game layout.
    var usesOuterDisplayLayout: Bool {
        isOuterDisplay && !isLandscape
    }

    /// Room for the minefield on a large iPhone display (the open iPhone Duo), leaving space
    /// for the score and the flag, shovel, and buttons around it.
    var largeIPhoneFieldSpace: CGSize {
        let margin: CGFloat = 16
        let controlsHeight: CGFloat = isLandscape ? 160 : 260
        return CGSize(
            width: windowSize.width - safeAreaInsets.leading - safeAreaInsets.trailing - 2 * margin,
            height: windowSize.height - safeAreaInsets.top - safeAreaInsets.bottom - controlsHeight
        )
    }

    /// The side the status bar runs along on the outer display in portrait, or nil when
    /// it runs across the top instead.
    var outerDisplayStatusBarEdge: HorizontalEdge? {
        guard usesOuterDisplayLayout else { return nil }
        let difference = safeAreaInsets.trailing - safeAreaInsets.leading
        if difference > 1 { return .trailing }
        if difference < -1 { return .leading }
        return nil
    }

    /// Width of the side status bar strip on the outer display.
    var outerDisplayStatusBarWidth: CGFloat {
        abs(safeAreaInsets.trailing - safeAreaInsets.leading)
    }

    /// Room for the minefield on the outer display. The field spans the full window width
    /// (minus a small margin) so its tiles can stay full size, and the height leaves space
    /// for the score row above and the flag and shovel below.
    var outerDisplayFieldSpace: CGSize {
        let margin: CGFloat = 16
        let controlsHeight: CGFloat = 170
        return CGSize(
            width: windowSize.width - 2 * margin,
            height: windowSize.height - safeAreaInsets.top - safeAreaInsets.bottom - controlsHeight
        )
    }

    /// Horizontal shift (negative moves left) that keeps a field of the given width clear of
    /// the side safe areas, like the outer display's status bar, while staying as close to
    /// centered as possible.
    func outerDisplayFieldShift(fieldWidth: CGFloat) -> CGFloat {
        let margin: CGFloat = 8
        let allowedMinX = safeAreaInsets.leading + margin
        let allowedMaxX = windowSize.width - safeAreaInsets.trailing - margin
        let centeredMinX = (windowSize.width - fieldWidth) / 2
        let centeredMaxX = centeredMinX + fieldWidth
        if centeredMaxX > allowedMaxX {
            return max(allowedMaxX - centeredMaxX, allowedMinX - centeredMinX)
        }
        if centeredMinX < allowedMinX {
            return min(allowedMinX - centeredMinX, allowedMaxX - centeredMaxX)
        }
        return 0
    }

    /// Nudges the minefield down a little on the outer display, away from the corner camera.
    var fieldTopOffset: CGFloat {
        isOuterDisplay ? 20 : 0
    }
}

struct OrientationReaderView: View {
    var onChange: (UIDeviceOrientation) -> Void
    var onMetricsChange: (CGSize, EdgeInsets, CGFloat) -> Void = { _, _, _ in }
    
    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .contentShape(Rectangle()) // only needed if hit testing, here optional
                .onAppear {
                    reportMetrics(proxy: proxy)
                }
                .onChange(of: proxy.size) {
                    //print("change proxy size")
                    reportMetrics(proxy: proxy)
                }
                .onChange(of: proxy.safeAreaInsets) {
                    reportMetrics(proxy: proxy)
                }
        }
        // Reports the orientation the interface is actually in. Unlike watching the size,
        // this also catches 180° turns (landscape left <-> right, portrait <-> upside down),
        // which don't change the window's size
        .background {
            InterfaceOrientationObserver { interfaceOrientation in
                if let orientation = Self.deviceOrientation(for: interfaceOrientation) {
                    onChange(orientation)
                }
            }
        }
        .allowsHitTesting(false) // makes it completely non-interactive
    }

    /// The rest of the app works in `UIDeviceOrientation`. UIKit names the landscape cases
    /// opposite ways: the interface is landscape *left* when the device is landscape *right*.
    private static func deviceOrientation(for interfaceOrientation: UIInterfaceOrientation) -> UIDeviceOrientation? {
        switch interfaceOrientation {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        default: return nil
        }
    }

    private func reportMetrics(proxy: GeometryProxy) {
        let insets = proxy.safeAreaInsets
        // Window size includes the safe areas this reader sits inside of.
        let windowSize = CGSize(
            width: proxy.size.width + insets.leading + insets.trailing,
            height: proxy.size.height + insets.top + insets.bottom
        )
        onMetricsChange(windowSize, insets, topCornerObstructionDepth(proxy: proxy))
    }

    /// Bottom edge (measured from the window's top) of any hardware, like the iPhone Duo's
    /// outer camera, that covers the top half of the window.
    private func topCornerObstructionDepth(proxy: GeometryProxy) -> CGFloat {
        guard #available(iOS 27.1, *) else { return 0 }
        let insets = proxy.safeAreaInsets
        return proxy.reservedRegions(kind: .occlusion)
            // Only regions in a top corner, which skips a centered Dynamic Island
            .filter { $0.isActive && $0.frame.midY < proxy.size.height / 2 && abs($0.frame.midX - proxy.size.width / 2) > proxy.size.width / 4 }
            // Region frames are relative to the safe area, so add the top inset back.
            .map { $0.frame.maxY + insets.top }
            .max() ?? 0
    }
}

/// Watches the window scene's interface orientation, which changes on every rotation the
/// app follows, including 180° turns.
private struct InterfaceOrientationObserver: UIViewRepresentable {
    var onChange: (UIInterfaceOrientation) -> Void

    func makeUIView(context: Context) -> ObserverView {
        let view = ObserverView()
        view.onChange = onChange
        return view
    }

    func updateUIView(_ view: ObserverView, context: Context) {
        view.onChange = onChange
    }

    final class ObserverView: UIView {
        var onChange: ((UIInterfaceOrientation) -> Void)?
        private var observation: NSKeyValueObservation?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            // effectiveGeometry is key-value observable; .initial reports the starting value
            observation = window?.windowScene?.observe(\.effectiveGeometry, options: [.initial, .new]) { [weak self] scene, _ in
                let orientation = scene.effectiveGeometry.interfaceOrientation
                Task { @MainActor in
                    self?.onChange?(orientation)
                }
            }
        }
    }
}
