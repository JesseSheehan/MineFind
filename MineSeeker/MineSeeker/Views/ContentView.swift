//
//  ContentView.swift
//  MineSeeker
//
//  Created by Jesse Sheehan on 8/21/25.
//

import SwiftUI
import AVFoundation
import StoreKit

struct ContentView: View {
    @EnvironmentObject var orientation: OrientationModel
    @Environment(\.requestReview) var requestReview

    @AppStorage("gamesWon") var gamesWon: Int = 0
    @AppStorage("lastVersionPromptedForReview") var lastVersionPromptedForReview: String = ""
    @AppStorage("reduceMotion") var reduceMotionSetting: Bool = false
    @Environment(\.accessibilityReduceMotion) var systemReduceMotion

    //the system setting or the in-game option both turn motion down
    var reducesMotion: Bool { systemReduceMotion || reduceMotionSetting }
    
    @State var vm = FieldViewModel()
    
    var body: some View {
            VStack {
                
                if vm.gameState == .home || vm.gameState == .reloadingGame {
                    HomeView(vm: vm)
                        .transition(.screenSlide(insertionX: nil, removalX: 1000, reducesMotion: reducesMotion))
                } else if vm.gameState == .instructions {
                    InstructionsView(vm: vm)
                        .transition(.screenSlide(insertionX: nil, removalX: 1000, reducesMotion: reducesMotion))
                } else if vm.gameState == .highScoreList {
                    HighScoreListView(vm: vm)
                        .transition(.screenSlide(insertionX: nil, removalX: 1000, reducesMotion: reducesMotion))
                } else if vm.gameState == .options {
                    OptionsView(vm: vm)
                        .transition(.screenSlide(insertionX: nil, removalX: 1000, reducesMotion: reducesMotion))
                } else {
                    FieldView(vm: vm)
                        .transition(.screenSlide(insertionX: -1000, removalX: 1000, reducesMotion: reducesMotion))
                }
            }
            .onAppear {
                vm.authenticateUser()
            }
            .onChange(of: orientation.current) {_, newOrientation in
                //print("change orientation")
                vm.handleOrientationChange(to: newOrientation)
            }
            //closing the iPhone Duo during a huge game heads back to the main menu,
            //since the field won't fit the outer display. The game can be resumed once reopened
            .onChange(of: orientation.supportsLargeFields) {_, supportsLargeFields in
                let isInGame = [GameState.playing, .animating, .won, .lost].contains(vm.gameState)
                if !supportsLargeFields && isInGame && vm.currentFieldNeedsLargeDisplay {
                    vm.gameStarted = false
                    vm.gameState = .home
                }
            }
            .onChange(of: gamesWon) {
                print("\(gamesWon) gamewon")
                print("\(lastVersionPromptedForReview) last version")
                print("\(vm.currentVersion) current version")
                if (gamesWon == 5 || gamesWon.isMultiple(of: 20)) && lastVersionPromptedForReview != vm.currentVersion {
                    print ("\(gamesWon) games won")
                    requestReview()
                    lastVersionPromptedForReview = vm.currentVersion
                    
                }
        }
            .animation(.smooth, value: vm.gameState)
            .environment(\.reducesMotion, reducesMotion)
        
    }
}


#Preview {
    ContentView()
        .environmentObject({
            let mock = OrientationModel()
            mock.current = .portrait
            return mock
        }())
}
