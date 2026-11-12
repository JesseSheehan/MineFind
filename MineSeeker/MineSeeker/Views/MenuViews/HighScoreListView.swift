//
//  HighScoreListView.swift
//  MineSeeker
//
//  Created by Jesse Sheehan on 9/6/25.
//

import SwiftUI
import SwiftData
import GameKit

struct HighScoreListView: View {
    
    @EnvironmentObject var orientation: OrientationModel
    @Environment(\.modelContext) private var modelContext
    @State var vm: FieldViewModel



    var body: some View {
        
        Text("HIGH SCORES")
            .font(Font.largeTitle.bold())
            .padding()
        
        TabView {
            VStack {
                
                VStack(alignment: .center) {
                    if UIDevice.isIPhone {
                        List {
                            ScrollView(.horizontal) {
                                Grid(alignment: .center, horizontalSpacing: orientation.isLandscape ? 25 : 10) {
                                    GridRow(alignment: .center) {
                                        Text("Name")
                                        //.gridCellAnchor(UnitPoint(x: 1, y: 0.5))
                                        Spacer()
                                        Text("Score")
                                        Spacer()
                                        Text("Mines")
                                        Spacer()
                                        Text("Size")
                                        Spacer()
                                        Text("Difficulty")
                                        Spacer()
                                        Text("Hints")
                                        Spacer()
                                        Text("Date")
                                    }
                                    .font(Font.headline)
                                    Divider()
                                    if vm.hsvm.highScores.isEmpty {
                                        
                                        Text("There are no high scores yet.")
                                            .font(Font.caption)
                                        
                                    } else {
                                        ForEach(vm.hsvm.highScores.prefix(20)) { highScore in
                                            GridRow(alignment: .center) {
                                                Text(highScore.name)
                                                //.gridCellAnchor(UnitPoint(x: 1, y: 0.5))
                                                Spacer()
                                                Text(String(highScore.score))
                                                Spacer()
                                                Text(String(highScore.mineCount))
                                                Spacer()
                                                Text(String(vm.sizeLabel(for: highScore.gridSize)))
                                                Spacer()
                                                Text(String(vm.difficultyLabel(for: highScore.difficulty)))
                                                Spacer()
                                                Text(String(highScore.hintsUsed))
                                                Spacer()
                                                Text(highScore.date.shortFormat)
                                            }
                                            .font(Font.caption)
                                            if highScore != vm.hsvm.highScores.last {
                                                Divider()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else
                    {
                        Table(vm.hsvm.highScores){
                            TableColumn("Name", value: \.name)
                            TableColumn("Date") { highScore in
                                Text(highScore.date, format: .dateTime.day().month().year())
                            }
                            TableColumn("Mine Count") {highScore in
                                Text(String(highScore.mineCount))
                            }
                            TableColumn("Hints Used") {highScore in
                                Text(String(highScore.hintsUsed))
                            }
                            TableColumn("GridSize") {highScore in
                                Text(vm.sizeLabel(for: highScore.gridSize))
                            }
                            TableColumn("Score") { highScore in
                                Text(String(highScore.score))
                            }
                        }
                        
                        
                    }
                }
                
                HomeButtonView(vm: vm)
                    .padding(.bottom, 10)
            }
            .onAppear {
                vm.hsvm.fetchHighScores(from: modelContext)
            }
            .tabItem {
                Image(systemName: "person.circle.fill")
                Text("My Scores")
            }
            
            LeaderboardTab(
                icon: "globe",
                title: "Global Leaderboard",
                buttonLabel: "View Global Scores",
                vm: vm
            ) {
                GKAccessPoint.shared.trigger(
                    leaderboardID: vm.classicLeaderboardID,
                    playerScope: .global,
                    timeScope: .allTime
                )
            }
            .tabItem {
                Image(systemName: "globe.fill")
                Text("Global Scores")
            }


            LeaderboardTab(
                icon: "person.3",
                title: "Friends Leaderboard",
                buttonLabel: "View Friend Scores",
                vm: vm
            ) {
                GKAccessPoint.shared.trigger(
                    leaderboardID: vm.classicLeaderboardID,
                    playerScope: .friendsOnly,
                    timeScope: .allTime
                )
            }
            .tabItem {
                Image(systemName: "person.3.fill")
                Text("Friend Scores")
            }
            
        }
        .padding(0)
    }
}


/// A leaderboard tab that prompts the player to open the native Game Center
/// leaderboard. Shows a sign-in note when the local player isn't authenticated,
/// since the native UI needs an authenticated Game Center account.
struct LeaderboardTab: View {
    let icon: String
    let title: String
    let buttonLabel: String
    @State var vm: FieldViewModel
    let action: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title2.bold())

            if vm.isGameCenterAuthenticated {
                Button(action: action) {
                    Text(buttonLabel)
                        .font(.headline)
                        .padding(.horizontal)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("Sign in to Game Center in Settings to see leaderboards.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            HomeButtonView(vm: vm)
                .padding(.bottom, 10)
        }
    }
}


#Preview {
    HighScoreListView(vm: FieldViewModel())
        .environmentObject({
            let mock = OrientationModel()
            mock.current = .landscapeLeft
            return mock
        }())
}


//    var highScoresExamples: [HighScore] = [
//        HighScore(id: UUID(), name: "Jesse S", score: 3000, date: Date(), gridSize: .big, hintsUsed: 0, duration: 1000, mineCount: 10),
//        HighScore(id: UUID(), name: "Florian R", score: 5000, date: Date(), gridSize: .big, hintsUsed: 0, duration: 1000, mineCount: 10),
//        HighScore(id: UUID(), name: "Jon K", score: 4000, date: Date(), gridSize: .big, hintsUsed: 0, duration: 1000, mineCount: 10),
//        HighScore(id: UUID(), name: "Victoria R", score: 2000, date: Date(), gridSize: .small, hintsUsed: 0, duration: 1000, mineCount: 10),
//        HighScore(id: UUID(), name: "Mel S", score: 8000, date: Date(), gridSize: .big, hintsUsed: 0, duration: 1000, mineCount: 10),
//        HighScore(id: UUID(), name: "Alex Y", score: 3500, date: Date(), gridSize: .small, hintsUsed: 0, duration: 1000, mineCount: 10),
//        HighScore(id: UUID(), name: "Maria E", score: 6000, date: Date(), gridSize: .big, hintsUsed: 0, duration: 1000, mineCount: 10),
//        ]
