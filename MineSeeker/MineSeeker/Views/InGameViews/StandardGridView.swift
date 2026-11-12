//
//  StandardGridView.swift
//  MineSeeker
//
//  Created by Jesse Sheehan on 9/6/25.

import SwiftUI

struct StandardGridView: View {
    @State var vm: FieldViewModel
    @EnvironmentObject var orientation: OrientationModel

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
