//
//  InstructionsButtonView.swift
//  MineSeeker
//
//  Created by Jesse Sheehan on 9/2/25.
//
import SwiftUI

struct InstructionsButtonView: View {
    @Environment(\.reducesMotion) var reducesMotion
    @State var vm: FieldViewModel
    
    var body: some View {
        Button {
            vm.gameState = .instructions
            vm.playSFX("buttonUp1")
        } label: {
            Label("How to Play ", systemImage: "questionmark.text.page.fill")
                .symbolRenderingMode(.multicolor)
                .symbolEffect(.bounce, isActive: !reducesMotion)
        }
        .buttonStyle(.glassProminent)
        //.buttonStyle(.borderedProminent)
        .sensoryFeedback(.impact(weight: .heavy), trigger: vm.gameState == .instructions)
    }
}
    
#Preview {
    
    InstructionsButtonView(vm: FieldViewModel())
        .environmentObject({
            let mock = OrientationModel()
            mock.current = .landscapeLeft
            return mock
        }())
}

