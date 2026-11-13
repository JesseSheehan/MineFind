//
//  HomeButtonView.swift
//  MineSeeker
//
//  Created by Jesse Sheehan on 9/2/25.
//

import SwiftUI

struct HomeButtonView: View {
    @Environment(\.reducesMotion) var reducesMotion
    
    @State var vm: FieldViewModel
    
    var body: some View {
        
        Button("Home", systemImage: "house.circle.fill") {
            vm.gameStarted = false
            vm.gameState = .home
            vm.playSFX("buttondown1")
        }
        .buttonStyle(.glassProminent)
        //.buttonStyle(.borderedProminent)
        .symbolRenderingMode(.multicolor)
        .symbolEffect(.bounce, isActive: !reducesMotion)
        .sensoryFeedback(.impact(weight: .heavy), trigger: vm.gameState == .home)

        
    }
}

#Preview {
    HomeButtonView(vm: FieldViewModel())
}
