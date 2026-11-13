//
//  MotionSettings.swift
//  MineSeeker
//

import SwiftUI

extension EnvironmentValues {
    /// True when motion should be kept to a minimum: either Reduce Motion is on in the
    /// system Settings, or the player turned on the in-game Reduce Motion option.
    /// Set once in ContentView so every view can read it.
    @Entry var reducesMotion = false
}

extension AnyTransition {
    /// Slides a screen in from the given offset, or just fades it when motion is reduced.
    static func screenSlide(insertionX: CGFloat?, removalX: CGFloat, reducesMotion: Bool) -> AnyTransition {
        if reducesMotion {
            return .opacity
        }
        return .asymmetric(
            insertion: insertionX.map { .offset(x: $0) } ?? .opacity,
            removal: .offset(x: removalX)
        )
    }
}
