//
//  HomeView.swift
//  MineSeeker
//
//  Created by Jesse Sheehan on 9/1/25.
//

import SwiftUI

struct HomeView: View {
    
    
    //REORIENT FOR iPHONE LANDSCAPE
    
    @EnvironmentObject var orientation: OrientationModel
    
    
    @State var vm: FieldViewModel
    private var gridSizeOptions: [GridSize] {
        if orientation.supportsLargeFields {
            return [.small, .med, .big, .huge]
        } else {
            return [.small, .med, .big]
        }
    }
    
     let chanceOptions = [5, 14, 25]
    
    
    var body: some View {
        Spacer()
        
        HStack {
            Text("MineFind")
                .font(.largeTitle)
                .bold()
            
            
            if orientation.isLandscape {
                DraggableItemView(vm: vm, imageToDrag: "Flag")
            }
            
        }
        .padding(0)
        
        if !orientation.isLandscape {
            DraggableItemView(vm: vm, imageToDrag: "Flag")
                .padding(0)
        }
        
        
        Spacer()

        
        Text("Choose a minefield size:")
        Picker("Choose size of minefield", selection: $vm.gridSize) {
            ForEach(gridSizeOptions, id: \.self) { size in
                Text(vm.sizeLabel(for: size))
                    .tag(size)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 275)
        .padding(.bottom, 10)
        
        Text("Choose a difficulty:")
        Picker("Choose a percentage of Mines", selection: $vm.chanceOfMine) {
            ForEach(chanceOptions, id: \.self) { chance in
                Text(vm.difficultyLabel(for: chance))
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 350)
        VStack{
            HStack {
                NewGameButton(vm: vm)
                InstructionsButtonView(vm: vm)
            }
            HStack {
                HighScoreListButtonView(vm: vm)
                OptionsButton(vm: vm)
            }
            if !vm.gameTiles.isEmpty && !vm.gameIsOver {
                //while the iPhone Duo is closed, resuming a huge game shows the
                //full-screen "open your iPhone" message instead of the field
                Button("Resume Game") {
                    //vm.returnToGame(isLandscape: orientation.isLandscape)
                    //the picker may have dropped to Big while the iPhone Duo was closed
                    if vm.currentFieldNeedsLargeDisplay {
                        vm.gridSize = .huge
                    }
                    vm.gameStarted = true
                    vm.gameState = .playing

                }
                if vm.currentFieldNeedsLargeDisplay && !orientation.supportsLargeFields {
                    //iPhone Duo closed with a huge game waiting
                    Text("Open your iPhone to resume your \(vm.sizeLabel(for: .huge)) game")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(10)
        
        Spacer()
            .onAppear { clampGridSize() }
            .onChange(of: orientation.supportsLargeFields) { clampGridSize() }
        
    }
    
    //when the iPhone Duo closes, falls back to the biggest size the outer display can show
    private func clampGridSize() {
        if !gridSizeOptions.contains(vm.gridSize) {
            vm.gridSize = .big
        }
    }
}

#Preview {
    HomeView(vm: FieldViewModel())
        .environmentObject({
            let mock = OrientationModel()
            mock.current = .landscapeLeft
            return mock
        }())
}
