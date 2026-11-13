//
//  FieldView.swift
//  MineSeeker
//
//  Created by Jesse Sheehan on 8/21/25.
//

import SwiftUI
import SwiftData
import Combine
import GameKit
//import Vortex

struct FieldView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var orientation: OrientationModel
    // @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @AppStorage("playerName") private var playerName: String = ""
    @AppStorage("gamesWon") var gamesWon: Int = 0
    @AppStorage("gamesLost") var gamesLost: Int = 0
    
    @State var explosion = false
    @Environment(\.reducesMotion) var reducesMotion
    
    @State var vm: FieldViewModel
    
    let textLimit = 20
    
    
    var body: some View {
        ZStack {
            VStack {
                Spacer().frame(height: (centersFieldVertically ? 0 : spacerHeight(isLandscape: orientation.isLandscape, gridSize: vm.gridSize))
                               + orientation.fieldTopOffset)
                
                if usesOuterDisplayLayout {
                    //iPhone Duo closed: score, hint, and home sit above the field
                    HStack {
                        ScoreView(vm: vm)
                        if vm.gameState == .playing {
                            CheckButtonView(vm: vm)
                            HomeButtonView(vm: vm)
                        }
                    }
                    .font(.caption.bold())
                } else if !orientation.isLandscape {
                    ScoreView(vm: vm)
                }
                
                ScrollView(.vertical, showsIndicators: false) {
                    StandardGridView(vm: vm)
                        .allowsHitTesting(vm.gameState == .playing ? true : false)
                        .transition(.screenSlide(insertionX: 1000, removalX: 1000, reducesMotion: reducesMotion))
                    
                    //this .anim makes bombs appear automatically instead of fade in
                        .animation(nil, value: vm.gameState)
                }
                .padding(usesOuterDisplayLayout ? [] : .all)
                .scrollDisabled(true)
                //iPhone Duo (open or closed): center the field vertically in the space it
                //has, rather than pinning it to the top
                .defaultScrollAnchor(centersFieldVertically ? .center : nil, for: .alignment)
                //Big field on the iPhone Duo's outer display: slide it away from the side
                //status bar. Padding on one side moves the centered field by half that amount
                .padding(.leading, max(bigFieldShift, 0) * 2)
                .padding(.trailing, max(-bigFieldShift, 0) * 2)
                //scroll views skip the centering safe area, so center across the full width;
                //the tiles are already sized to stay clear of the side status bar
                .ignoresSafeArea(.container, edges: usesOuterDisplayLayout ? .horizontal : [])
                
                HStack {
                    VStack {
                        if vm.gameState == .playing && usesOuterDisplayLayout {
                            //iPhone Duo closed: the flag and shovel go below the field, unless
                            //there's a side status bar to put them under (see overlay below)
                            HStack {
                                if !showsFlagAndShovelInStatusBar {
                                    DraggableItemView(vm: vm, imageToDrag: "Flag", onChanged: vm.itemMoved, onEnded: vm.itemDropped)
                                    DraggableItemView(vm: vm, imageToDrag: "Shovel", onChanged: vm.itemMoved, onEnded: vm.itemDropped)
                                }
                                if vm.difficultyLabel(for: vm.chanceOfMine) == "Beginner" {
                                    InstructionsButtonView(vm: vm)
                                        .font(.caption.bold())
                                }
                            }
                            .transition(.screenSlide(insertionX: nil, removalX: 1000, reducesMotion: reducesMotion))
                        } else if vm.gameState == .playing {
                            StandardGameOptionsView(vm: vm)
                                .transition(.screenSlide(insertionX: nil, removalX: 1000, reducesMotion: reducesMotion))
                            
                            
                        } else {
                            HStack{
                                if orientation.isLandscape {
                                    ScoreView(vm: vm)
                                    //.font(Font.title2)
                                }
                                NewGameButton(vm: vm)
                                HomeButtonView(vm: vm)
                            }
                            .transition(.screenSlide(insertionX: nil, removalX: 1000, reducesMotion: reducesMotion))
                            .padding()
                        }
                    }
                }
                if vm.gridSize != .big {
                    Spacer().frame(height: UIDevice.isIPhone && orientation.isLandscape ? 20 : 30)
                }
            }
            .animation(.smooth, value: vm.gameState)
            .opacity(showsOpenDeviceMessage ? 0 : 1)
            
            if vm.gameState == .lost {
                ExplosionView(vm: vm)
                    .opacity(showsOpenDeviceMessage ? 0 : 1)
                    .onAppear {
                        gamesLost += 1
                        //print("\(gamesLost) games lost")
                    }
            }
                if vm.gameState == .won {
                    CelebrationView(vm: vm)
                        .opacity(showsOpenDeviceMessage ? 0 : 1)
                        .onAppear {
                            gamesWon += 1
                            vm.submitScoreToGameCenter(vm.gameScore)
                            checkForHighScore()
                        }
            }
            
            //iPhone Duo closed during a huge game. The field stays hidden underneath
            //(instead of being removed) so the game picks right back up when reopened
            if showsOpenDeviceMessage {
                OpenDeviceView(vm: vm)
                    .transition(.opacity)
            }
        }
        //iPhone Duo closed: the flag and shovel sit in the side status bar's strip,
        //centered vertically so they stay below the time, signal, and camera
        .overlay {
            if showsFlagAndShovelInStatusBar && vm.gameState == .playing && !showsOpenDeviceMessage {
                HStack(spacing: 0) {
                    if orientation.outerDisplayStatusBarEdge == .trailing {
                        Spacer(minLength: 0)
                    }
                    VStack(spacing: 24) {
                        DraggableItemView(vm: vm, imageToDrag: "Flag", onChanged: vm.itemMoved, onEnded: vm.itemDropped)
                        DraggableItemView(vm: vm, imageToDrag: "Shovel", onChanged: vm.itemMoved, onEnded: vm.itemDropped)
                    }
                    .frame(width: orientation.outerDisplayStatusBarWidth)
                    if orientation.outerDisplayStatusBarEdge == .leading {
                        Spacer(minLength: 0)
                    }
                }
                //reach past the content area into the status bar's strip
                .ignoresSafeArea(.container, edges: .horizontal)
                .transition(.opacity)
            }
        }
        .padding(0)
        .ignoresSafeArea(ignoresSafeArea ? [.all] : [])
        .animation(.smooth, value: orientation.supportsLargeFields)
        
        
        
        
        //ALERTS
        .alert("New High Score!", isPresented: ($vm.newHighScore)) {
            TextField("New High Score!\nEnter your name", text: $playerName)
                .onReceive(Just(playerName)) { _ in limitText(textLimit) }
            
            
            Button("Enter") { saveHighScore(name: playerName)}
            Button("Cancel", role: .cancel) {}
        } message: {Text("You scored \(vm.gameScore) points!")}
        
            .alert(isPresented: $vm.showGameStatusAlert, content: {
                
                if vm.gameState == .won {
                    Alert(title: Text("You Won"), message: Text("You scored \(vm.gameScore) points!"), dismissButton: .default(Text("OK")))
//                } else if vm.gameState == .lost {
//                    Alert(title: Text("You Lost"), message: Text("Better luck next time!"), dismissButton: .default(Text("OK")))
                } else  {
                    //after the hint alert closes, the points lost float up from the score
                    Alert(title: vm.checkedTooSoonText, message: Text(vm.minusPointsText), dismissButton: .default(Text("OK")) {
                        vm.showHintScoreChange()
                    })
                }
                
            })
    }


    var ignoresSafeArea: Bool {
        UIDevice.isIPhone && vm.gridSize != .small && orientation.isLandscape
    }

    var usesOuterDisplayLayout: Bool {
        orientation.usesOuterDisplayLayout
    }

    //how far to move the Big field off center on the iPhone Duo's outer display
    var bigFieldShift: CGFloat {
        guard usesOuterDisplayLayout && vm.gridSize == .big else { return 0 }
        return orientation.outerDisplayFieldShift(fieldWidth: vm.outerDisplayFieldWidth(on: orientation))
    }

    //iPhone Duo, open or closed: its screens don't match the fixed spacing tuned for
    //regular iPhones in spacerHeight, so center the field in the space it has instead
    var centersFieldVertically: Bool {
        usesOuterDisplayLayout || orientation.isLargeIPhoneDisplay
    }

    //iPhone Duo closed with the status bar down one side
    var showsFlagAndShovelInStatusBar: Bool {
        orientation.outerDisplayStatusBarEdge != nil
    }

    var showsOpenDeviceMessage: Bool {
        vm.currentFieldNeedsLargeDisplay && !orientation.supportsLargeFields
    }

    func spacerHeight(isLandscape: Bool, gridSize: GridSize) -> CGFloat {
        let deviceType: String = UIDevice.isIPad ? "iPad" : "iPhone"
        
        switch (deviceType, gridSize, isLandscape) {
            
        // iPad cases
        case ("iPad", .small, true):
            return 200
        case ("iPad", .small, false):
            return 325
        case ("iPad", .med, true):
            return 100
        case ("iPad", .med, false):
            return 200
        case ("iPad", .big, _):
            return 100

        case ("iPad", .huge, _):
            return 20   // same regardless of orientation
        
        // iPhone cases
        case ("iPhone", .small, true):
            return 50
        case ("iPhone", .small, false):
            return 250
        case ("iPhone", .med, true):
            return 10
        case ("iPhone", .med, false):
            return 180
        case ("iPhone", .big, _):
            return 0
//        case ("iPhone", .big, false):
//            return 0
        
        // fallback
        default:
            return 30
        }
    }
    
    func checkForHighScore() {
        vm.hsvm.fetchHighScores(from: modelContext)
        
        print("lowest Score: \(vm.hsvm.getLowestHighScore(using: modelContext))")
        
        if vm.gameScore > vm.hsvm.getLowestHighScore(using: modelContext) || vm.hsvm.highScores.count < 20  {
            vm.newHighScore = true
        } else {
            vm.showGameStatusAlert = true
        }
    }
    
    @MainActor
    func saveHighScore(name: String) {
        let newestHighScore = HighScore(
            id: UUID(),
            name: name,
            score: vm.gameScore,
            date: .now,
            gridSize: vm.gridSize,
            hintsUsed: vm.hintsUsed,
            duration: nil,
            mineCount: vm.mineCount,
            difficulty: vm.chanceOfMine,
            wonGame: true
        )
        modelContext.insert(newestHighScore)
        if vm.hsvm.highScores.count > 20 {
            vm.hsvm.fetchHighScores(from: modelContext)
            let scoresToDelete = vm.hsvm.highScores.suffix(from: 20)
            for score in scoresToDelete {
                modelContext.delete(score)
            }
        }
        
        do {
            try modelContext.save()
            print("High score saved")
        } catch {
            print("Failed to save high score: \(error)")
        }
    }
    

    func limitText(_ upper: Int) {
            if playerName.count > upper {
                playerName = String(playerName.prefix(upper))
            }
        }
}

//Covers the field when the iPhone Duo closes, since a huge field won't fit the outer display
struct OpenDeviceView: View {
    @State var vm: FieldViewModel
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.background)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)
                
                Text("Open Your iPhone")
                    .font(.title.bold())
                
                Text("The \(vm.sizeLabel(for: .huge)) minefield needs the larger inside display. Open your iPhone to keep playing, or head home.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 320)
                
                HomeButtonView(vm: vm)
            }
            .padding()
        }
    }
}

#Preview {
    FieldView(vm: FieldViewModel())
        .environmentObject({
            let mock = OrientationModel()
            mock.current = .portrait
            return mock
        }())
}
