//
//  FlagView.swift
//  MineSeeker
//
//  Created by Jesse Sheehan on 8/26/25.
//

import SwiftUI

enum DragState {
    case canPlaceOnTile
    case cannotPlaceOnTile
    case notOnTile
}

struct DraggableItemView: View {
    //@Environment(\.modelContext) private var modelContext
    @EnvironmentObject var orientation: OrientationModel

    //@State var standardGridView: StandardGridView
    @State var vm: FieldViewModel
    @State private var dragAmount = CGSize.zero
    @State var dragState: DragState = .notOnTile
    var imageToDrag: String
    
    var onChanged: ((CGPoint, String) -> DragState)?
    var onEnded: ((CGPoint, String) -> Void)?
    //gently sways back and forth (the home screen flag)
    var sways = false
    @Environment(\.reducesMotion) var reducesMotion
    @State private var isSwayedRight = false

    private var swayDegrees: Double {
        guard sways && !reducesMotion else { return 0 }
        return isSwayedRight ? 5 : -5
    }
    
    private var shadowColor: Color {
        if dragAmount == .zero {
           return Color.clear
        }
        
        switch dragState {
        case .canPlaceOnTile:
            return Color.green
        case .cannotPlaceOnTile:
            return Color.red
        case .notOnTile:
            return Color.black
        }
    }
    
    var body: some View {
        
        ZStack {
            Rectangle()
                .fill(Color.secondary)
                .frame(width: orientation.isLandscape ? 55 : 70, height: orientation.isLandscape ? 55 : 70)
                .cornerRadius(20)
                .padding(0)
                
                
            
            Image(imageToDrag)
                .resizable()
                .frame(width: orientation.isLandscape ? 75 : 90, height: orientation.isLandscape ? 75 : 90)
                .rotationEffect(.degrees(swayDegrees), anchor: .bottom)
                //the repeating animation is only started for the swaying flag, so it can't
                //slow down other changes like the resize when the device rotates
                .onAppear {
                    guard sways && !reducesMotion else { return }
                    withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                        isSwayedRight = true
                    }
                }
                .offset(dragAmount)
                .zIndex(dragAmount == .zero ? 0 : 1)
                .shadow(color: shadowColor,
                        radius: dragAmount == .zero ? 0 : 10)
                .padding(0)
                .gesture(
                    DragGesture(coordinateSpace: .global)
                        .onChanged {
                            //print("Changed draggable")
                            self.dragAmount = CGSize(width: $0.translation.width, height: $0.translation.height)
                            
                            self.dragState = self.onChanged?(
                                $0.location,
                                self.imageToDrag
                            ) ?? .notOnTile
                        }
                        .onEnded{value in
                            if self.dragState == .canPlaceOnTile {
                                self.onEnded?(value.location, self.imageToDrag)
                                
                                
                               //vm.checkForMines(modelContext: modelContext)
                            }
                            
                            self.dragAmount = .zero
                            self.dragState = .notOnTile
                            vm.clearDragHover()
                        }
                )
                .sensoryFeedback(.impact(weight: .medium, intensity: 0.7), trigger: dragState == .canPlaceOnTile)
                .sensoryFeedback(.impact(weight: .heavy, intensity: 1.0), trigger: dragAmount == .zero)
                
        }
        .padding(0)
        //dragging doesn't work with VoiceOver; each tile has Flag/Remove Flag actions instead
        .accessibilityHidden(true)
    }
}


#Preview {
    DraggableItemView(vm: FieldViewModel(), imageToDrag: "Flag")
        .environmentObject({
            let mock = OrientationModel()
            mock.current = .landscapeLeft
            return mock
        }())
}


