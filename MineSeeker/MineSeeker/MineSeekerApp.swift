//
//  MineSeekerApp.swift
//  MineSeeker
//
//  Created by Jesse Sheehan on 8/21/25.
//

import SwiftUI
import SwiftData

@main
struct MineSeekerApp: App {

    @StateObject var orientation = OrientationModel()

    var body: some Scene {
        WindowGroup {
            // The outer GeometryReader always matches the window, so pinning the content
            // to its size keeps an oversized minefield (like Huge on the iPhone Duo's
            // outer display) from stretching the measurements in OrientationReaderView.
            GeometryReader { window in
                ContentView()
                    .environmentObject(orientation)
                    // Keeps everything centered on the iPhone Duo's outer display
                    .safeAreaPadding(orientation.centeringInsets)
                    .frame(width: window.size.width, height: window.size.height)
                    .background {
                        OrientationReaderView { newOrientation in
                            orientation.previous = orientation.current
                            orientation.current = newOrientation
                        } onMetricsChange: { size, insets, obstructionDepth in
                            orientation.windowSize = size
                            orientation.safeAreaInsets = insets
                            orientation.topCornerObstructionDepth = obstructionDepth
                        }
                    }
            }
        }
        .modelContainer(for: HighScore.self)
    }
}


