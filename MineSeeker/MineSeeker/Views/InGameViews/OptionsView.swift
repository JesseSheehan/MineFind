//
//  OptionsView.swift
//  MineSeeker
//
//  Created by Jesse Sheehan on 9/11/25.
//

import SwiftUI

struct OptionsView: View {
    
    @AppStorage("sfx") var sfxSave = true
    @AppStorage("music") var musicSave = true
    @AppStorage("reduceMotion") var reduceMotionSave = false
    @Environment(\.accessibilityReduceMotion) var systemReduceMotion
    @Environment(\.reducesMotion) var reducesMotion
    
    var vm: FieldViewModel
    
    var body: some View {
        Spacer()
        Spacer()
        Button {
            vm.sfx.toggle()
            UserDefaults.standard.set(vm.sfx, forKey: "sfx")
            if vm.sfx {
                vm.playSFX("buttonUp1")
            }
        } label: {
            Label(vm.sfx ? "Sound Effects On" : "Sound Effects Off", systemImage: "waveform.circle")
                .symbolRenderingMode(.multicolor)
                .symbolEffect(.bounce, isActive: !reducesMotion)
                .padding(10)
                .foregroundColor(.primary)
                .background(vm.sfx ? .blue : .gray)
                .cornerRadius(20)
                //.
        }
        
        Button {
            vm.music.toggle()
            if vm.sfx {
                vm.playSFX("buttonUp1")
            } else {
                vm.playSFX("buttondown1")
            }
        } label: {
            Label(vm.music ? "Music On" : "Music Off", systemImage: "music.quarternote.3")
                .symbolRenderingMode(.multicolor)
                .symbolEffect(.bounce, isActive: !reducesMotion)
                .padding(10)
                .foregroundColor(.primary)
                .background(vm.music ? .blue : .gray)
                .cornerRadius(20)
                //.
        }

        Button {
            reduceMotionSave.toggle()
            vm.playSFX(reduceMotionSave ? "buttonUp1" : "buttondown1")
        } label: {
            Label(reducesMotion ? "Reduce Motion On" : "Reduce Motion Off", systemImage: "figure.walk.motion")
                .symbolRenderingMode(.multicolor)
                .symbolEffect(.bounce, isActive: !reducesMotion)
                .padding(10)
                .foregroundColor(.primary)
                .background(reducesMotion ? .blue : .gray)
                .cornerRadius(20)
        }
        //can't be turned off here while it's on in the system Settings
        .disabled(systemReduceMotion)
        .accessibilityHint("Replaces explosions, confetti, and sliding screens with simple fades")

        if systemReduceMotion {
            Text("On because Reduce Motion is on in Settings")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        Spacer()
        HomeButtonView(vm: vm)
        Spacer()
        Text("v\(vm.currentVersion)")
    }
}

#Preview {
    OptionsView(vm: FieldViewModel())
        .environmentObject({
            let mock = OrientationModel()
            mock.current = .portrait
            return mock
        }())
}
