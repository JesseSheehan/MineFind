//
//  StandardGridView.swift
//  MineSeeker
//
//  Created by Jesse Sheehan on 9/6/25.

import SwiftUI

struct StandardGridView: View {
    @State var vm: FieldViewModel
    @EnvironmentObject var orientation: OrientationModel
    @Environment(\.reducesMotion) var reducesMotion

    var width: Double { vm.tileWidth(on: orientation) }

    //iPhone Duo: fixed spacing so tile sizes can be worked out to fit; system default elsewhere
    var columnSpacing: CGFloat? {
        if orientation.usesOuterDisplayLayout { return FieldViewModel.outerDisplayTileSpacing }
        if orientation.isLargeIPhoneDisplay { return FieldViewModel.largeIPhoneColumnSpacing }
        return nil
    }
    
    
    var body: some View {
        if vm.gameStarted {
            LazyVGrid(columns: Array(
                        repeating: GridItem(.fixed(width), spacing: columnSpacing),
                        count:vm.columnCount
                    ),
                    alignment: .center,
                      spacing: 1
                      
            ) {
                ForEach(vm.gameTiles.indices, id: \.self) { i in
                    TileView(tile: $vm.gameTiles[i], vm: vm)
                        .overlay(GeometryReader {geo in
                            Color.clear
                                .onAppear {
                                    //print("appeared")
                                    let frame = geo.frame(in: .global)
                                    vm.setTileFrame(index: i, frame: frame)
                                }
                                .onChange(of: geo.frame(in: .global)) {_, newFrame in
                                    //print("changed frame")
                                    vm.setTileFrame(index: i, frame: newFrame)
                                }
                                .onChange(of: vm.gameTiles) {_, newFrame in
                                    //print("chagned gameTiles")
                                    let frame = geo.frame(in: .global)
                                    vm.setTileFrame(index: i, frame: frame)
                                }
                                
                        })
                }
            }
        
            .padding(0)
            //groups the tiles so VoiceOver users can jump in and out of the field
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Minefield, \(vm.rowCount) rows by \(vm.columnCount) columns")
            //a quick side-to-side shake when a hint costs points (none with Reduce Motion)
            .keyframeAnimator(initialValue: 0.0, trigger: vm.shakeCount) { content, offset in
                content.offset(x: offset)
            } keyframes: { _ in
                let amount: CGFloat = reducesMotion ? 0 : 8
                KeyframeTrack {
                    LinearKeyframe(amount, duration: 0.05)
                    LinearKeyframe(-amount, duration: 0.08)
                    LinearKeyframe(amount * 0.6, duration: 0.08)
                    LinearKeyframe(-amount * 0.6, duration: 0.08)
                    SpringKeyframe(0, duration: 0.15)
                }
            }

        }
    }
}


#Preview {
    FieldView(vm: FieldViewModel())
        .environmentObject({
            let mock = OrientationModel()
            mock.current = .landscapeLeft
            return mock
        }())
}
