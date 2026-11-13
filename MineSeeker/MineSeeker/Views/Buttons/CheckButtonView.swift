//
//  CheckButtonView.swift
//  MineSeeker
//
//  Created by Jesse Sheehan on 9/1/25.
//

import SwiftUI
import SwiftData

struct CheckButtonView: View {
    @Environment(\.reducesMotion) var reducesMotion
    
    @State var vm: FieldViewModel
    @Environment(\.modelContext) private var modelContext

    //@State var showCheckAlert = false
    
    var body: some View {
        
        Button {
            if vm.gameState == .playing {
                vm.hintButton()
                
            }
        } label: {
            Label("Hint", systemImage: "lightbulb.fill")
                .symbolRenderingMode(.multicolor)
                .symbolEffect(.bounce, isActive: !reducesMotion)
        }
        .buttonStyle(.glassProminent)
        //.buttonStyle(.borderedProminent)
        //.disabled(vm.gameScore <= 0 ? true : false)
        .sensoryFeedback(.error, trigger: vm.showGameStatusAlert)

    }

}

#Preview {
    CheckButtonView(vm: FieldViewModel())
}
