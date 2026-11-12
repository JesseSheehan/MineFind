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
    
    @State var vm = FieldViewModel()
    
    var body: some View {
            VStack {
                
                if vm.gameState == .home || vm.gameState == .reloadingGame {
                    HomeView(vm: vm)
                        .transition(.asymmetric(
                            insertion: .opacity.animation(.smooth),
                            removal: .offset(x: 1000))
                        )
                } else if vm.gameState == .instructions {
                    InstructionsView(vm: vm)
                        .transition(.asymmetric(
                            insertion: .opacity.animation(.smooth),
                            removal: .offset(x: 1000))
                        )
                } else if vm.gameState == .highScoreList {
                    HighScoreListView(vm: vm)
                        .transition(.asymmetric(
                            insertion: .opacity.animation(.smooth),
                            removal: .offset(x: 1000))
                        )
                } else if vm.gameState == .options {
                    OptionsView(vm: vm)
                        .transition(.asymmetric(
                            insertion: .opacity.animation(.smooth),
                            removal: .offset(x: 1000))
                        )
                } else {
                    FieldView(vm: vm)
                        .transition(.asymmetric(
                            insertion: .offset(x: -1000),
                            removal: .offset(x: 1000))
                        )
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
