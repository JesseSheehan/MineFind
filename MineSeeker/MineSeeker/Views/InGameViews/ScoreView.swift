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
    
    var body: some View {
        
        HStack {
            Text(vm.gameState == .lost ? "GAME OVER!" : "SCORE:")
                .bold()
            
            //Text("100000")
            Text(vm.gameState == .lost ? "" : "\(vm.gameScore)")
                .foregroundStyle(vm.newHighScore ? .green : .primary)
            
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 15)
        .background(vm.gameState == .lost ? .red : .blue)
        .cornerRadius(20)
        .font(orientation.isLandscape ? Font.title : orientation.isOuterDisplay ? Font.title3 : Font.largeTitle)
    }
}

#Preview {
    
//    @Previewable @State var myVm = FieldViewModel()
    //@Previewable @State myVm.gameScore = 100
    
//    ScoreView(vm: myVm)
}
