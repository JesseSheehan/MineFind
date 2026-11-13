//
//  FieldViewModel.swift
//  MineSeeker
//
//  Created by Jesse Sheehan on 8/25/25.
//

import SwiftUI
import AVFoundation
import CoreHaptics
import GameKit

//the string/codable/caseIterable are so it cane be stored in the high score model w/ swiftdata
enum GridSize: String, Codable, CaseIterable {
    case small
    case med
    case big
    case huge
}

enum GameState {
    case home
    case animating
    case playing
    case won
    case lost
    case reloadingGame
    case instructions
    case highScoreList
    case options
}

enum GridRotation: Int {
    case portraitUp = 0
    case landscapeRight = 1
    case portraitDown = 2
    case landscapeLeft = 3
}

@Observable
final class FieldViewModel {
    //var currentVersion = "1.0.1"
    var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A"
    }
    
    //@Environment(\.verticalSizeClass) var verticalSizeClass
   
    //var isLandscape = false
    
    //App Setup
    var gameState = GameState.home
    var hsvm = HighScoresViewModel()
    
    //MineField SetUp
    var gridSize = GridSize.med
    var rowCount: Int = 5
    var columnCount: Int = 5
    var gameTiles: [Tile] = []
    
    var lastWasMine: Bool = false
    var chanceOfMine: Int = 14
    
    //Tile Setup (Draggable)
    var iPhoneWidth = 40.0
    var iPadWidth = 60.0
    var tileFrames: [CGRect] = []
    var framesReady = false
    var shouldMeasureFrames = false

    //GameState Details
    var lostGame = false
    var gameStarted = false
    var gameIsOver = false
    var showGameStatusAlert = false
    var isFirstTile = true
    var checkedTooSoonText: Text = Text("")
    var minusPointsText = ""
    var usedCheckButton = false
   
    //Scoring (and Saving)
    var newHighScore = false
    //
    var gameScore: Int = 0
    var mineCount: Int = 0
    //worked out from the tiles so it's always right, even when digging clears a flag
    var flagCount: Int { gameTiles.filter(\.isFlagged).count }
    var hintsUsed: Int = 0
    
    //ANIMATION
    //the tile under the dragged flag/shovel, highlighted green or red
    var dragHover: DragHover?
    //points floating up from the score (hint penalties)
    var scorePop: ScorePop?
    //the hint's score change, shown once its alert is dismissed
    var pendingHintScoreChange: Int?
    //bumping this shakes the board
    var shakeCount = 0

    //HAPTICS
    var engine: CHHapticEngine?
    
    //rotation stuff?
    private var gridRotation: GridRotation = .portraitUp
    
    
    //SOUNDS
    var musicFile: AVAudioPlayer?
    var sfxPlayers: [String:AVAudioPlayer] = [:]
    var sfx: Bool
    var music: Bool {
        didSet {
            guard music != oldValue else { return }
            
            if music {
                startMusic()
            } else {
                stopMusic()
            }
            UserDefaults.standard.set(music, forKey:"music")
        }
    }
    
   
 
    

    init() {
        self.sfx = UserDefaults.standard.bool(forKey: "sfx")
        let savedMusic = UserDefaults.standard.bool(forKey: "music")
        self.music = UserDefaults.standard.bool(forKey: "music")
        
        if savedMusic && !AVAudioSession.sharedInstance().isOtherAudioPlaying {
            startMusic()
        } else {
            music = false
        }
    }
    
    func startMusic() {
        if musicFile == nil {
            if let url = Bundle.main.url(forResource: "mineFindSong", withExtension: "caf") {
                            do {
                                //try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
                                try AVAudioSession.sharedInstance().setActive(true, options: [])
                                musicFile = try AVAudioPlayer(contentsOf: url)
                                musicFile?.volume = 0.2
                                musicFile?.numberOfLoops = -1
                                musicFile?.prepareToPlay()
                            } catch {
                                print("[FieldViewModel] Failed to initialize music: \(error)")
                            }
                        } else {
                            print("[FieldViewModel] Missing resource mineFindSong.caf")
                        }
                    }
                    musicFile?.play()
        }
    
    private func stopMusic() {
        musicFile?.stop()
    }

    func playSFX(_ name: String, ext: String = "mp3") {
        guard sfx else {return}
        
        if let player = sfxPlayers[name] {
            player.currentTime = 0
            player.play()
        } else if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
                let newPlayer = try AVAudioPlayer(contentsOf: url)
                newPlayer.prepareToPlay()
                sfxPlayers[name] = newPlayer
                newPlayer.play()
            } catch {
                print("[FieldViewModel] failed to load sfx: \(error)")
            }
        } else {
            print("[FieldViewModel]  missing sfx resource: \(name).\(ext)")
        }
    }
    
    private func gridRotation(for orientation: UIDeviceOrientation) -> GridRotation? {
        switch orientation {
        case .portrait: return .portraitUp
        case .landscapeRight: return .landscapeRight
        case .portraitUpsideDown: return .portraitDown
        case .landscapeLeft: return .landscapeLeft
        default: return nil
        }
    }
    
        func handleOrientationChange(to newOrientation: UIDeviceOrientation) {
            guard let newRotation = gridRotation(for: newOrientation),
                  !gameTiles.isEmpty else { return }

            let oldRotation = gridRotation
            let delta = (newRotation.rawValue - oldRotation.rawValue + 4) % 4

            //tiles swap places when the field turns, which would otherwise replay their
            //reveal and flag animations
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                for _ in 0..<delta {
                    rotateTilesForOrientation(isClockwise: true)
                }
                dragHover = nil
            }

            gridRotation = newRotation
        }

     func rotateTilesForOrientation(isClockwise: Bool) {
        //
        let oldRows = rowCount
        let oldCols = columnCount

        // Swap row/column counts
         if oldRows != oldCols {
             rowCount = oldCols
             columnCount = oldRows
         }

        var newTiles: [Tile] = Array(repeating: Tile(row: 0, column: 0, isMine: false), count: rowCount * columnCount)

        for oldRow in 0..<oldRows {
            for oldCol in 0..<oldCols {
                let oldIndex = oldRow * oldCols + oldCol
                let oldTile = gameTiles[oldIndex]
                let (newRow, newCol): (Int, Int)

                if isClockwise {
                    newRow = oldCol
                    newCol = oldRows - 1 - oldRow
                } else {
                    newRow = oldCols - 1 - oldCol
                    newCol = oldRow
                }

                var newTile = oldTile
                newTile.row = newRow
                newTile.column = newCol
                let newIndex = newRow * columnCount + newCol
                newTiles[newIndex] = newTile
            }
        }
        //gameTiles = newTiles
         for i in newTiles.indices {
             newTiles[i].index = i
         }
         gameTiles = newTiles
    }
    
    
    func setUpGame(orientation: UIDeviceOrientation) {
        let isLandscape = orientation.isLandscape
        rowCount = getRowCount(size: gridSize, isLandscape: isLandscape)
        columnCount = getColumnCount(size: gridSize, isLandscape: isLandscape)
        mineCount = 0
        gameScore = 0
        gameStarted = false
        isFirstTile = true
        gameTiles.removeAll()
        gameIsOver = false
        lostGame = false
        hintsUsed = 0
        
        tileFrames = Array(repeating: .zero, count: rowCount * columnCount)
        framesReady = false
        
        newHighScore = false
        dragHover = nil
        scorePop = nil
        pendingHintScoreChange = nil
        gameTiles = createTiles()
        
        gameStarted = true
        gameState = .playing
        
        //start from the actual orientation so later rotations turn the field the right way
        gridRotation = gridRotation(for: orientation) ?? (isLandscape ? .landscapeRight : .portraitUp)

    }
    
    
    //CREAT TILES/set up
    func createTiles(/*rowCount: Int, columnCount: Int*/) -> [Tile] {
        
        //CREATE TILES FOR TILEVIEW
        var tiles: [Tile] = []
        for row in 0..<rowCount {
            for column in 0..<columnCount {
                tiles.append(Tile(row: row, column: column, isMine: MineRandomizer(percentChance: chanceOfMine)))
                
            }
        }
        
        //if no mines found, adds one
        if mineCount == 0 && !tiles.isEmpty {
            if let randomIndex = tiles.indices.randomElement() {
                tiles[randomIndex].isMine = true
                print("added a mine to \(tiles[randomIndex].row), + \(tiles[randomIndex].column) ")
                mineCount += 1
            }
        }
        
        // Calculate surrounding mines for each tile
        //tiles.indices is basically like tiles.count, but it's not type specific
        //indices is commonly used when you need to mutate items
        for i in tiles.indices {
            //for each tile...
            let tile = tiles[i]
            tiles[i].index = i
            //collect it's neighbors...
            let neighbors = neighborCoordinates(tile: tile)
            //take each neighbor...
            let thisMineCount = neighbors.reduce(0) { count, coord in
                //find a tile (if it exists) that has the same row/column properties as the neighborTile coordinates
                if let neighborTile = tiles.first(where: { $0.row == coord.0 && $0.column == coord.1 }) {
                
                    
                    //return the current count + 1 if the neighborTile was a mine
                    return count + (neighborTile.isMine ? 1 : 0)
                    
                }
                print(count)
                return count
            }
            tiles[i].surroundingMineCount = thisMineCount
        }
        
        return tiles
    }
    
    //THIS IS MOSTLY REPEATED CODE, BUT WHATEVER
    func recountSurroundingMines(gameTiles: [Tile]) {
        for i in gameTiles.indices {
            //for each tile...
            let neighbors = neighborCoordinates(tile: gameTiles[i])
            //take each neighbor...
            let thisMineCount = neighbors.reduce(0) { count, coord in
                //find a tile (if it exists) that has the same row/column properties as the neighborTile coordinates
                if let neighborTile = gameTiles.first(where: { $0.row == coord.0 && $0.column == coord.1 }) {
                    //return the current count + 1 if the neighborTile was a mine
                    return count + (neighborTile.isMine ? 1 : 0)
                }
                return count
            }
            self.gameTiles[i].surroundingMineCount = thisMineCount
        }
    }
  
    
    func MineRandomizer(percentChance: Int) -> Bool {
       // var minegoal = floor(Double((rowCount * columnCount)/4))
        //print("minegoal is \(minegoal)")

        
        if percentChance >= Int.random(in: 0..<100) {
            mineCount += 1
            return true
        } else {
            return false
        }
    }
    
    // Helper to get neighbors' coordinates
    //maybe fold this into get neighbors??
    func neighborCoordinates(tile: Tile) -> [(Int, Int)] {
        let neighbors = [
            (tile.row - 1, tile.column - 1),
            (tile.row - 1, tile.column),
            (tile.row - 1, tile.column + 1),
            (tile.row, tile.column - 1),
            (tile.row, tile.column + 1),
            (tile.row + 1, tile.column - 1),
            (tile.row + 1, tile.column),
            (tile.row + 1, tile.column + 1)
        ]
        
        // Stay in bounds
        //NOTE: apple AI did this, i should learn why/how it works
        //$0.0 is the key and $0.1 is the value. so in other words:
        // filter out: row ($0.0) is more/equal to 0 and less than 10
        //         and column ($0.1) is more/equal to 0 and less than 10
        return neighbors.filter { $0.0 >= 0 && $0.0 < rowCount && $0.1 >= 0 && $0.1 < columnCount }
    }
    
    //index is the mine that was hit; the rest of the board is revealed in a wave spreading out from it
    func gameOver(from index: Int? = nil) {
        let hiddenTiles = gameTiles.indices.filter { !gameTiles[$0].isRevealed }
        gameState = .lost
        gameIsOver = true
        //showGameStatusAlert = true

        lostGame = true
        for i in self.gameTiles.indices {
            
            gameTiles[i].isRevealed = true
        }
        if let index {
            setRevealDelays(for: hiddenTiles, from: index, step: 0.05)
        }
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//            self.showGameStatusAlert = true
//        }
        
    }
    
    func adjacentReveal(tile: Tile) {
        //if tile is revealed and has 0 bombs
        if (tile.surroundingMineCount == 0 && !tile.isMine) {
            //print("LonelyTile's coords: \(tile.coordinates)")
            
            //gather neighboring tiles's coordinates
            let neighbors = neighborCoordinates(tile: tile)
            //print (" Hello neighbors: \(neighbors)")
            
            //for each coordinate
            for neighbor in neighbors {
                //find the gameTile with matching coords
                if let index = self.gameTiles.firstIndex(where: { $0.row == neighbor.0 && $0.column == neighbor.1 }) {
                    
                    //HOW DO I MAKE WORK!?
                    if !self.gameTiles[index].isRevealed {
                        self.gameTiles[index].isRevealed = true
                        self.gameTiles[index].isFlagged = false
                        gameScore += (gameTiles[index].surroundingMineCount * 25)
                    } else {
                        continue
                    }
                    
                    //if the tile's mineCount is also 0
                    if self.gameTiles[index].surroundingMineCount == 0 {
                        //do it all again with this tile!
                        adjacentReveal(tile: self.gameTiles[index])
                    }
                }
            }
        }
    }
    
    func checkForMines() {
        var mineTiles: [Tile] = []
        var flaggedTiles: [Tile] = []

        for myTile in gameTiles {
            if myTile.isMine {
                mineTiles.append(myTile)
            }
            if myTile.isFlagged {
                flaggedTiles.append(myTile)
            }
        }
        //if mineTiles is same as flaggedTiles, you won
        if mineTiles == flaggedTiles {
            gameScore += 500 + (200 * mineTiles.count)
            mineCount = mineTiles.count
            gameState = .won
            gameIsOver = true
            announce("All mines found! You won with \(gameScore) points.", highPriority: true)

        }
    }
    
    func firstTileRule(at index: Int) {
        if isFirstTile {
            isFirstTile = false
            if gameTiles[index].isMine {
                gameTiles[index].isMine.toggle()
                print("this was a mine!")
                mineCount -= 1
                if mineCount == 0  {
                    if let randomIndex = gameTiles.indices.randomElement() {
                        gameTiles[randomIndex].isMine = true
                        print("added a mine to \(gameTiles[randomIndex].row), + \(gameTiles[randomIndex].column) ")
                        mineCount += 1
                    }
                }
                recountSurroundingMines(gameTiles: gameTiles)
            }
        }
    }
    
    func handleTileReveal(at index: Int) {
        if !gameTiles[index].isRevealed {
            let hiddenBefore = gameTiles.indices.filter { !gameTiles[$0].isRevealed }
            gameTiles[index].isRevealed = true
            gameTiles[index].isFlagged = false
            adjacentReveal(tile: gameTiles[index])
            gameScore += gameTiles[index].surroundingMineCount == 0 ? 10 : (gameTiles[index].surroundingMineCount * 50)

            if gameTiles[index].isMine {
                gameOver(from: index)
                announce("Boom! You hit a mine. Game over.", highPriority: true)
            } else {
                let newlyRevealed = hiddenBefore.filter { gameTiles[$0].isRevealed }
                setRevealDelays(for: newlyRevealed, from: index, step: 0.03)

                //VoiceOver doesn't re-read a tile after it changes, so say what was found
                let revealedCount = newlyRevealed.count
                let mines = gameTiles[index].surroundingMineCount
                if revealedCount > 1 {
                    announce("No mines nearby. Revealed \(revealedCount) tiles.")
                } else {
                    announce(mines == 0 ? "No mines nearby." : nearbyMinesDescription(mines))
                }
            }
        }
    }
    
    func hintButton() {
        let scoreBefore = gameScore
        var mineTiles: [Tile] = []
        var flaggedTiles: [Tile] = []
        var correctTiles: Int = 0
        //get tiles
        for myTile in gameTiles {
            if myTile.isMine {
                mineTiles.append(myTile)
            }
            if myTile.isFlagged {
                flaggedTiles.append(myTile)
            }
            if myTile.isMine && myTile.isFlagged {
                correctTiles += 1
            }
        }
        
        if flaggedTiles.count > mineTiles.count {
            checkedTooSoonText = Text("There's ^[\(flaggedTiles.count - mineTiles.count) extra flag](inflect: true) on the field")
            minusPointsText = "Minus 50 points for every extra flag"
            gameScore -= (50 * (flaggedTiles.count - mineTiles.count))
            
        } else if flaggedTiles.count > correctTiles {
            checkedTooSoonText = Text("There's ^[\(flaggedTiles.count - correctTiles) misplaced flag](inflect:true) on the field")
            minusPointsText = "Minus 25 points for each mislabeled flag"
            gameScore -= (25 * (flaggedTiles.count - correctTiles))
            
        } else if mineTiles.count > correctTiles {
            checkedTooSoonText = Text("There's ^[\(mineTiles.count - correctTiles) mine](inflect: true) still unflagged")
            minusPointsText = "Minus 10 points for every unflagged mine"
            gameScore -= (10 * (mineTiles.count - correctTiles))
        } else {
            checkedTooSoonText = Text("You may have found a bug! Try removing a flag and then placing it again.")
            minusPointsText = "Earned 1 point for finding a bug!"
            gameScore += 1
        }
        hintsUsed += 1
        pendingHintScoreChange = gameScore - scoreBefore
        showGameStatusAlert = true
        playSFX("buttondown1")
    }
    
    func getRowCount(size: GridSize, isLandscape: Bool) -> Int {
        switch size {
        case .small:
            return 4
        case .med:
            return isLandscape ? 7 : 9
        case .big:
            return isLandscape ? 8 : 14
        case .huge:
            return isLandscape ? 12 : 16
        }
    }
    
    func getColumnCount(size: GridSize, isLandscape: Bool) -> Int {
        switch size {
        case .small:
            return 4
        case .med:
            return isLandscape ? 9 : 7
        case .big:
            return isLandscape ? 14 : 8
        case .huge:
            return isLandscape ? 16 : 12
        }
    }
    
    //space between tiles on the iPhone Duo's outer display, where width is tight
    static let outerDisplayTileSpacing: CGFloat = 1
    
    //space between columns on the open iPhone Duo (the system default elsewhere)
    static let largeIPhoneColumnSpacing: CGFloat = 8

    //largest tile on the open iPhone Duo for small and medium fields
    static let largeIPhoneMaxTileWidth: Double = 90

    //tile width for this device. On the iPhone Duo's outer display, tiles only shrink
    //(never grow) if the whole field wouldn't otherwise fit on screen
    func tileWidth(on orientation: OrientationModel) -> Double {
        let standardWidth = UIDevice.isIPhone ? iPhoneWidth : iPadWidth
        guard columnCount > 0, rowCount > 0 else { return standardWidth }
        if orientation.isLargeIPhoneDisplay {
            return openDuoTileWidth(on: orientation, standardWidth: standardWidth)
        }
        guard orientation.usesOuterDisplayLayout else { return standardWidth }
        let space = orientation.outerDisplayFieldSpace
        let spacing = Self.outerDisplayTileSpacing
        let columns = CGFloat(columnCount)
        let rows = CGFloat(rowCount)
        let widthThatFits = (space.width - (columns - 1) * spacing) / columns
        //tiles are 0.8 as tall as they are wide; rows are 1pt apart (see StandardGridView)
        let widthThatFitsHeight = (space.height - (rows - 1)) / rows / 0.8
        return min(standardWidth, floor(min(widthThatFits, widthThatFitsHeight)))
    }

    //open iPhone Duo: square tiles. Small and medium fields grow to fill the bigger screen
    //(up to largeIPhoneMaxTileWidth); big and huge keep the standard width. Either way they
    //shrink if needed so the whole field fits
    private func openDuoTileWidth(on orientation: OrientationModel, standardWidth: Double) -> Double {
        let mediumTileCount = getRowCount(size: .med, isLandscape: false) * getColumnCount(size: .med, isLandscape: false)
        //tile count rather than gridSize, so it stays right if the picker changes mid-game
        let maxWidth = rowCount * columnCount <= mediumTileCount ? Self.largeIPhoneMaxTileWidth : standardWidth
        let space = orientation.largeIPhoneFieldSpace
        let columns = CGFloat(columnCount)
        let rows = CGFloat(rowCount)
        let widthThatFits = (space.width - (columns - 1) * Self.largeIPhoneColumnSpacing) / columns
        //square tiles; rows are 1pt apart (see StandardGridView)
        let widthThatFitsHeight = (space.height - (rows - 1)) / rows
        return min(maxWidth, floor(min(widthThatFits, widthThatFitsHeight)))
    }
    
    //full width of the field's columns on the iPhone Duo's outer display
    func outerDisplayFieldWidth(on orientation: OrientationModel) -> CGFloat {
        let columns = CGFloat(columnCount)
        return columns * tileWidth(on: orientation) + max(columns - 1, 0) * Self.outerDisplayTileSpacing
    }
    
    //true when the current game's field is bigger than a regular iPhone can show.
    //uses the tile count so it stays right even if the picker changes mid-game
    var currentFieldNeedsLargeDisplay: Bool {
        gameTiles.count > getRowCount(size: .big, isLandscape: false) * getColumnCount(size: .big, isLandscape: false)
    }
    
    
    
    func itemMoved(location: CGPoint, textToDrag: String) -> DragState {
        guard let index = tileFrames.firstIndex(where: {
            $0.contains(location) }) else {
            clearDragHover()
            return .notOnTile
        }
        
        let thisTile = gameTiles[index]
        let canPlace: Bool
        
        switch textToDrag {
        case "Flag":
            //a tile that already has a flag can't take another one
            canPlace = !thisTile.isRevealed && !thisTile.isFlagged
        case "Shovel":
            canPlace = !thisTile.isRevealed && thisTile.isFlagged
        default:
            canPlace = false
        }
        let hover = DragHover(index: index, canPlace: canPlace)
        //only update when it changes, since every tile redraws when this does
        if dragHover != hover {
            dragHover = hover
        }
        return canPlace ? .canPlaceOnTile : .cannotPlaceOnTile
    }

    func clearDragHover() {
        if dragHover != nil {
            dragHover = nil
        }
    }

    //spaces out reveal animations by distance from the origin tile, so they spread outward
    private func setRevealDelays(for indices: [Int], from origin: Int, step: Double) {
        let originTile = gameTiles[origin]
        for i in indices {
            let distance = max(abs(gameTiles[i].row - originTile.row), abs(gameTiles[i].column - originTile.column))
            //capped so huge boards don't take forever
            gameTiles[i].revealDelay = min(Double(distance) * step, 0.8)
        }
    }

    //called when the hint alert is dismissed: floats the score change by the score,
    //and shakes the board if points were lost
    func showHintScoreChange() {
        guard let change = pendingHintScoreChange else { return }
        pendingHintScoreChange = nil
        guard change != 0 else { return }
        let pop = ScorePop(amount: change)
        scorePop = pop
        if change < 0 {
            shakeCount += 1
        }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            if self?.scorePop == pop {
                self?.scorePop = nil
            }
        }
    }
    
    
    func itemDropped(location: CGPoint, textToDrop: String) {
        guard let index = tileFrames.firstIndex(where: { $0.contains(location)}) else {return }
        guard !gameTiles[index].isRevealed else {return }
        
        
        switch textToDrop {
        case "Flag":
            setFlag(true, at: index)

        case "Shovel":
            setFlag(false, at: index)

        default:
            break
        }
    }

    //places or removes a flag. Used by the dragged flag/shovel and by VoiceOver's tile actions.
    //does nothing if the tile is already in that state
    func setFlag(_ flagged: Bool, at index: Int) {
        guard gameTiles.indices.contains(index),
              !gameTiles[index].isRevealed,
              gameTiles[index].isFlagged != flagged else { return }
        gameTiles[index].isFlagged = flagged
        checkForMines()
    }

    //what tapping (or double-tapping with VoiceOver) an unrevealed tile does
    func digTile(at index: Int) {
        firstTileRule(at: index)
        handleTileReveal(at: index)
    }

    //VoiceOver

    //speaks a message to VoiceOver users (does nothing when VoiceOver is off).
    //high priority messages aren't cut off by whatever VoiceOver reads next, like an alert
    func announce(_ message: String, highPriority: Bool = false) {
        var announcement = AttributedString(message)
        if highPriority {
            announcement.accessibilitySpeechAnnouncementPriority = .high
        }
        AccessibilityNotification.Announcement(announcement).post()
    }

    //"1 mine nearby" / "3 mines nearby"
    func nearbyMinesDescription(_ count: Int) -> String {
        count == 1 ? "1 mine nearby" : "\(count) mines nearby"
    }

    func setTileFrame(index: Int, frame: CGRect) {
        if tileFrames[index] != frame {
            tileFrames[index] = frame
            if !tileFrames.contains(.zero) {
                framesReady = true
            }
        }
    }
    
    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("There was an error creating the engine \(error.localizedDescription)")
        }
    }
    
    
    //ONLINE

    let classicLeaderboardID = "me.jesse.sheehan.MineFind.classicboard"

    /// Observable mirror of GKLocalPlayer.local.isAuthenticated so views update
    /// when sign-in finishes (authentication completes asynchronously).
    var isGameCenterAuthenticated = GKLocalPlayer.local.isAuthenticated

    func authenticateUser() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            // Game Center hands us a sign-in screen when the player isn't signed in yet.
            if let viewController {
                Self.topViewController()?.present(viewController, animated: true)
                return
            }
            if let error {
                print("[GameCenter] Authentication failed: \(error.localizedDescription)")
            }
            self?.isGameCenterAuthenticated = GKLocalPlayer.local.isAuthenticated
        }
    }

    /// The front-most view controller, used to present the Game Center sign-in screen.
    private static func topViewController() -> UIViewController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
        var top = root
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }

    /// The best score we've successfully sent to Game Center, so we only upload
    /// genuine personal bests. The leaderboard is also configured as BEST_SCORE,
    /// so the server keeps the highest even if a lower one slips through.
    /// Keyed per Game Center player so switching accounts doesn't block submissions.
    private var bestSubmittedScore: Int {
        get { UserDefaults.standard.integer(forKey: bestSubmittedScoreKey) }
        set { UserDefaults.standard.set(newValue, forKey: bestSubmittedScoreKey) }
    }

    private var bestSubmittedScoreKey: String {
        "bestSubmittedScore-\(GKLocalPlayer.local.gamePlayerID)"
    }

    /// Submits the given score to the classic leaderboard, but only when it beats
    /// the best we've already uploaded. Logs each step so uploads can be verified
    /// from the Xcode console.
    func submitScoreToGameCenter(_ score: Int) {
        guard GKLocalPlayer.local.isAuthenticated else {
            print("[GameCenter] Not authenticated — skipping submit of \(score).")
            return
        }

        guard score > bestSubmittedScore else {
            print("[GameCenter] \(score) is not a new best (best is \(bestSubmittedScore)) — skipping submit.")
            return
        }

        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [classicLeaderboardID]
                )
                bestSubmittedScore = score
                print("[GameCenter] ✅ Submitted new best score \(score) to \(classicLeaderboardID).")

                // Read the score back to confirm the round-trip actually landed.
                if let entry = try await loadLocalPlayerEntry() {
                    print("[GameCenter] Server now reports your best as \(entry.score) (rank \(entry.rank)).")
                } else {
                    print("[GameCenter] Submit succeeded but no local player entry came back yet (can take a moment to propagate).")
                }
            } catch {
                print("[GameCenter] ❌ Failed to submit score \(score): \(error.localizedDescription)")
            }
        }
    }

    /// Loads the local player's own entry on the classic leaderboard, or nil if
    /// they don't have one yet. Useful for confirming a submission landed.
    private func loadLocalPlayerEntry() async throws -> GKLeaderboard.Entry? {
        let boards = try await GKLeaderboard.loadLeaderboards(IDs: [classicLeaderboardID])
        guard let board = boards.first else { return nil }
        let (localEntry, _, _) = try await board.loadEntries(
            for: .global,
            timeScope: .allTime,
            range: NSRange(1...1)
        )
        return localEntry
    }

    
    //LABELS
    
    func sizeLabel(for size: GridSize) -> String {
        switch size {
        case .small: return "Small"
        case .med: return "Medium"
        case .big: return "Big"
        case .huge: return "Huge"
        }
    }
    
     func difficultyLabel(for chance: Int) -> String {
        switch chance {
        case 5: return "Beginner"
        case 14: return "Normal"
        case 25: return "Advanced"
        //case 40: return "Impossible"
        default: return "Normal"
        }
    }
    
}

extension UIDevice {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    static var isVision: Bool {
        UIDevice.current.userInterfaceIdiom == .vision
    }

//    static var isOther: Bool {
//        UIDevice.current.userInterfaceIdiom ==
//    }
}
