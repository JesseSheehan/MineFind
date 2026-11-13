//
//  TileView.swift
//  MineSeeker
//
//  Created by Jesse Sheehan on 8/22/25.
//

import SwiftUI
//import Vortex

struct TileView: View {
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @EnvironmentObject var orientation: OrientationModel
    
    @Binding var tile: Tile
    @State var vm: FieldViewModel
    @State var gameState: GameState = .playing
    var imageCache: ImageCache = ImageCache()

    var width: Double { vm.tileWidth(on: orientation) }
    //square on the open iPhone Duo; slightly shorter than wide everywhere else
    var height: Double { orientation.isLargeIPhoneDisplay ? width : width * 0.8 }
    //on the open iPhone Duo, numbers grow with the bigger small and medium tiles
    var numberFont: Font {
        orientation.isLargeIPhoneDisplay ? .system(size: max(22, width * 0.45), weight: .bold) : Font.title2.bold()
    }
    
    var animationAmount = 0.0
    
    @Environment(\.reducesMotion) var reducesMotion

    var body: some View {
        
        ZStack {
            Rectangle()
                .tileDimensions(fillColor: tile.isMine && tile.isRevealed ? .red : Color(.tileBack), width: width, height: height)
                .cornerRadius(10)
            

            //the cover: shrinks and fades away when the tile is dug
            Rectangle()
                .tileDimensions(fillColor: Color(vm.gameState == .won && tile.isFlagged ? .green : .tileTop), width: width, height: height)
                //winning flags turn green in a wave from the top-left corner
                .animation(winAnimation, value: vm.gameState == .won)
                .scaleEffect(tile.isRevealed && !reducesMotion ? 0.5 : 1)
                .opacity(tile.isRevealed ? 0 : 1)

            tileContent(tile:tile)
                .allowsHitTesting(false)
        }
        //revealing animates first (and wins if both change at once, like digging a flagged tile)
        .animation(revealAnimation, value: tile.isRevealed)
        .animation(flagAnimation, value: tile.isFlagged)
        .contentShape(Rectangle())
        .onTapGesture {
            vm.digTile(at: tile.index)
        }
        //drag highlight: outlines the tile under the flag or shovel
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(vm.dragHover?.canPlace == true ? Color.green : Color.red, lineWidth: 4)
                .opacity(isDragTarget ? 1 : 0)
                .allowsHitTesting(false)
        }
        .scaleEffect(isDragTarget && !reducesMotion ? 1.08 : 1)
        .animation(.snappy(duration: 0.15), value: isDragTarget)
        .frame(width: width, height: height)
        //keeps the highlighted tile above its neighbors
        .zIndex(isDragTarget ? 1 : 0)
        //VOICEOVER: the whole tile is one element. Double-tap digs, and the Flag/Remove Flag
        //actions (swipe up or down) stand in for dragging the flag and shovel
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(canPlay && !tile.isRevealed ? .isButton : [])
        .accessibilityHint(accessibilityHintText)
        .accessibilityAction {
            guard canPlay, !tile.isRevealed else { return }
            //double-tapping a flagged tile takes the flag off instead of digging,
            //so a flagged mine can't be dug up by accident
            if tile.isFlagged {
                vm.setFlag(false, at: tile.index)
                vm.announce("Flag removed")
            } else {
                vm.digTile(at: tile.index)
            }
        }
        .accessibilityActions {
            if canPlay && !tile.isRevealed {
                if tile.isFlagged {
                    Button("Remove Flag") {
                        vm.setFlag(false, at: tile.index)
                        vm.announce("Flag removed")
                    }
                } else {
                    Button("Flag") {
                        vm.setFlag(true, at: tile.index)
                        //a winning flag gets its own announcement from the view model
                        if vm.gameState == .playing {
                            vm.announce("Flagged")
                        }
                    }
                }
            }
        }


    }

    //taps are only allowed mid-game (the grid also turns off hit testing, but
    //VoiceOver actions don't go through hit testing)
    var canPlay: Bool { vm.gameState == .playing }

    //ANIMATIONS (Reduce Motion swaps movement and scaling for quick fades)

    var isDragTarget: Bool { vm.dragHover?.index == tile.index }

    //waits for the tile's turn in a cascade or game-over wave, then springs open
    var revealAnimation: Animation {
        reducesMotion ? .easeOut(duration: 0.15) : .spring(duration: 0.3, bounce: 0.35).delay(tile.revealDelay)
    }

    //a dropped flag lands with a bounce; a dug-up flag hops away
    var flagAnimation: Animation {
        reducesMotion ? .easeOut(duration: 0.15) : .spring(duration: 0.35, bounce: 0.5)
    }

    var winAnimation: Animation {
        .easeInOut(duration: 0.3).delay(reducesMotion ? 0 : Double(tile.row + tile.column) * 0.04)
    }

    //numbers and mines pop in from small
    var popTransition: AnyTransition {
        reducesMotion ? .opacity : .scale(scale: 0.4).combined(with: .opacity)
    }

    var flagTransition: AnyTransition {
        reducesMotion ? .opacity : .asymmetric(
            insertion: .scale(scale: 1.6).combined(with: .opacity),
            removal: .offset(y: -height * 0.6).combined(with: .opacity)
        )
    }

    //tells VoiceOver users what double-tapping will do
    var accessibilityHintText: String {
        guard canPlay && !tile.isRevealed else { return "" }
        return tile.isFlagged
            ? "Double-tap to remove the flag."
            : "Double-tap to dig. Swipe up or down for flag actions."
    }

    //what VoiceOver reads, e.g. "Unrevealed, row 2, column 5" or "3 mines nearby, row 1, column 1"
    var accessibilityDescription: String {
        let state: String
        if tile.isRevealed && tile.isMine {
            state = "Mine"
        } else if tile.isRevealed {
            state = tile.surroundingMineCount == 0 ? "Empty" : vm.nearbyMinesDescription(tile.surroundingMineCount)
        } else if tile.isFlagged {
            state = "Flagged"
        } else {
            state = "Unrevealed"
        }
        return "\(state), row \(tile.row + 1), column \(tile.column + 1)"
    }
    
    @ViewBuilder
    func tileContent(tile: Tile) -> some View {
        if !tile.isRevealed && tile.isFlagged {
            imageCache.image(named: "Flag")
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)
                .transition(flagTransition)
        } else if tile.isMine && tile.isRevealed {
            imageCache.image(named: "BombOutline")
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)
                .transition(popTransition)
        } else if tile.isRevealed && tile.surroundingMineCount > 0 {
            Text("\(tile.surroundingMineCount)")
                .font(numberFont)
                .frame(width: width, height: height)
                .transition(popTransition)
        }
    }
}


extension Rectangle {
    func tileDimensions(fillColor: Color, width: Double, height: Double) -> some View {
        let radius: CGFloat = 10
            return self
            .fill(fillColor)
            .frame(width: width, height: height)
            .cornerRadius(radius)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(.secondary, lineWidth: 3)
                    //.strokeBorder(.black, lineWidth: )
            )
            .aspectRatio(1, contentMode: .fit)

    }
}

#Preview {
    
//    @Previewable @State var myTile = Tile(row: 1, column: 1, isMine: false, surroundingMineCount: 1)
//    @Previewable @State var mineTile = Tile(row: 2, column: 1, isMine: true)
//    
//    TileView(tile: $myTile, vm: FieldViewModel())
//    TileView(tile: $mineTile, vm: FieldViewModel())
    
    FieldView(vm: FieldViewModel())
        .environmentObject({
            let mock = OrientationModel()
            mock.current = .landscapeLeft
            return mock
        }())
}

//        } else if tile.surroundingMineCount == 0 {
//            return AnyView(Text(""))
//        } else {
//            return AnyView(
//                Text(String(tile.surroundingMineCount))
//                    .font(Font.title.bold())
//            )
//        }

