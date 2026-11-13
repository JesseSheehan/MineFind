//
//  HighScoreView.swift
//  MineSeeker
//
//  Created by Jesse Sheehan on 9/6/25.
//

import SwiftUI

struct ScoreView: View {
    @EnvironmentObject var orientation: OrientationModel
    
    @State var vm: FieldViewModel
    @Environment(\.reducesMotion) var reducesMotion
    
    var body: some View {
        
        HStack {
            Text(vm.gameState == .lost ? "GAME OVER!" : "SCORE:")
                .bold()
            
            //Text("100000")
            Text(vm.gameState == .lost ? "" : "\(vm.gameScore)")
                .foregroundStyle(vm.newHighScore ? .green : .primary)
                //digits roll to the new score (a quick fade with Reduce Motion)
                .contentTransition(reducesMotion ? .opacity : .numericText(value: Double(vm.gameScore)))
                .animation(.snappy, value: vm.gameScore)
            
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 15)
        .background(vm.gameState == .lost ? .red : .blue)
        .cornerRadius(20)
        //reads as one phrase, e.g. "Score: 120"
        .accessibilityElement(children: .combine)
        //hint penalties float up from the score
        .overlay(alignment: .top) {
            if let pop = vm.scorePop {
                FloatingPointsView(amount: pop.amount, rise: 40)
                    .id(pop.id)
                    .offset(y: -12)
            }
        }
        .font(orientation.isLandscape ? Font.title : orientation.isOuterDisplay ? Font.title3 : Font.largeTitle)
    }
}

#Preview {
    
//    @Previewable @State var myVm = FieldViewModel()
    //@Previewable @State myVm.gameScore = 100
    
//    ScoreView(vm: myVm)
}
