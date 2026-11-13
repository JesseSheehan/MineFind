//
//  ExplosionView.swift
//  MineSeeker
//
//  Created by Jesse Sheehan on 9/2/25.
//

import SwiftUI
import Vortex
//import AVFoundation
import CoreHaptics

struct ExplosionView: View {

    var vm: FieldViewModel
    

    //@State var vm: FieldViewModel
//    var xCoord: CGFloat
//    var yCoord: CGFloat
    @State var tapThrough = false
    @Environment(\.reducesMotion) var reducesMotion
    //Reduce Motion: a quick red flash that fades out instead of flying particles
    @State private var flashOpacity = 0.35
    
    var body: some View {
        Group {
            if reducesMotion {
                Color.red
                    .opacity(flashOpacity)
                    .ignoresSafeArea()
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.8)) {
                            flashOpacity = 0
                        }
                    }
            } else {
                VortexViewReader { proxy in
                    VortexView(createExplosion()) {
                        Rectangle()
                           // .fill(.red)
                            .fill(.white)
                            .blur(radius: 3)
                            //.blendMode(.plusLighter)
                            .frame(width: 20, height: 20)
                            .tag("one")

                    }
                    .onAppear { //location in
                        proxy.burst()
                    }
                    
        //            Button("burst", action: proxy.burst)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                tapThrough = true
            }
            vm.playSFX("lose2")
            vm.prepareHaptics()
            explosionHaptic()
        }
        .allowsHitTesting(tapThrough ? false : true)
        //purely visual; VoiceOver hears about the loss from the game's announcement
        .accessibilityHidden(true)
        //.zIndex(100)
    }
    
    func createExplosion() -> VortexSystem {
        let system = VortexSystem(tags: ["one"])
        //system.position = [0.5, 0.5]//[xCoord, yCoord]
        system.speed = 1
        system.speedVariation = 0.75
        system.lifespan = 2
        system.angleRange = .degrees(360)
        system.size = 0.75
        system.shape = .box(width: 0.5, height: 0.5)
        system.dampingFactor = 5
        system.sizeVariation = 0.75
        system.emissionLimit = 200
        system.emissionDuration = 1.5
        system.burstCount = 200
        system.stretchFactor = 2.0
        system.colors = .random(.red, .orange, .yellow, .gray)
        system.sizeMultiplierAtDeath = 0.001
        

        return system
    }
    
    func explosionHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        var events = [CHHapticEvent]()
        
        let blastIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let blastSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let blast = CHHapticEvent(eventType: .hapticTransient, parameters: [blastIntensity, blastSharpness], relativeTime: 0)
        events.append(blast)

        let decaySteps = 25
            for i in 0..<decaySteps {
                let t = Double(i) * 0.1  // spacing events every 0.1 sec
                let intensity = Float(1.0 - Double(i) / Double(decaySteps)) // fade out
                let sharpness = Float(0.2 + 0.3 * (1.0 - Double(i) / Double(decaySteps))) // slight taper
                let continuous = CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                    ],
                    relativeTime: t,
                    duration: 0.1
                )
                events.append(continuous)
        
        
//        let rumbleIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
//        let rumbleSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
//        let continuous = CHHapticEvent(eventType: .hapticContinuous, parameters: [rumbleIntensity, rumbleSharpness], relativeTime: 0.05, duration: 0.3)
//        events.append(continuous)

        
//        for i in stride(from: 0, to: 1, by: 0.1) {
//            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(1 - i))
//            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(1 - i))
//            
//            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: i)
//            events.append(event)
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

//extension

#Preview {
    ExplosionView(vm: FieldViewModel())//xCoord: 0.5, yCoord: 0.5)
}
