//
//  CelebrationView.swift
//  MineSeeker
//
//  Created by Jesse Sheehan on 9/8/25.
//

import SwiftUI
import Vortex
import CoreHaptics
struct CelebrationView: View {
    
    var vm: FieldViewModel

    @Environment(\.reducesMotion) var reducesMotion

    var body: some View {
        Group {
            //Reduce Motion: skip the falling confetti; the sound and haptics still play
            if !reducesMotion {
                VortexView(createFallingConfetti()) {
                    Rectangle()
                        .fill(.white)
                        .frame(width: 20)
                        .tag("circle")
                        .frame(width: 10, height: 10)
                }
            } else {
                //keeps something on screen so onAppear still fires
                Color.clear
            }
        }
        .onAppear { //location in
            vm.playSFX("win1")
            vm.prepareHaptics()
            celebrationHaptic()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        
    }
    
    func createFallingConfetti() -> VortexSystem {
        let system = VortexSystem(tags: ["circle"])
        system.position = [0.5, 0]
        system.speed = 0.5
        system.speedVariation = 0.5
        system.lifespan = 3
        system.birthRate = 200
        system.shape = .box(width: 1, height: 1)
        system.burstCount = 100
        system.acceleration = [0, 1]
        system.angle = .degrees(180)
        system.angleRange = .degrees(20)
        system.angularSpeedVariation = [4, 4, 4]
        system.colors = .random(.white, .red, .green, .blue, .pink, .orange, .cyan)
        system.size = 0.5
        system.sizeVariation = 0.5

        return system
    }
    
    func celebrationHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        var events = [CHHapticEvent]()
        
        
        let rumbleIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let rumbleSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
        let continuous = CHHapticEvent(eventType: .hapticContinuous, parameters: [rumbleIntensity, rumbleSharpness], relativeTime: 0.05, duration: 0.3)
        events.append(continuous)

        
        for i in stride(from: 0, to: 1, by: 0.1) {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(1 - i))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(1 - i))

            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: i)
            events.append(event)
        }
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try vm.engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern \(error.localizedDescription)")
        }
    }
    
}



#Preview {
    CelebrationView(vm: FieldViewModel())
}
