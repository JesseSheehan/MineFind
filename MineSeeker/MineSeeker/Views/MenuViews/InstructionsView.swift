//
//  InstructionsView.swift
//  MineSeeker
//
//  Created by Jesse Sheehan on 9/2/25.
//

import SwiftUI

struct InstructionsView: View {
    @EnvironmentObject var orientation: OrientationModel
    @State var vm: FieldViewModel
    @Environment(\.reducesMotion) var reducesMotion
    @Environment(\.accessibilityVoiceOverEnabled) var voiceOverEnabled

    @State private var demoTileBomb = Tile(row: 1, column: 1, isMine: true, isRevealed: true)
    @State private var demoTileReveal = Tile(row: 1, column: 1, isMine: false, surroundingMineCount: 1)

    //CARD DECK
    @State private var currentCard = 0
    @State private var dragOffset: CGFloat = 0
    private let cardCount = 7
    //how far a card has to be dragged before it counts as a swipe
    private let swipeThreshold: CGFloat = 80
    //how many cards show in the stack at once (the top card plus the ones peeking out)
    private let visibleCards = 3

    var body: some View {
        VStack(spacing: orientation.isLandscape ? 8 : 16) {
            Text("How to Play")
                .font(orientation.isLandscape ? .title.bold() : .largeTitle.bold())

            cardDeck
                .frame(maxWidth: 380, maxHeight: 480)
                .padding(.horizontal, 24)

            controls
        }
        .padding(.vertical, 10)
    }

    //A stack of cards. The top card follows the finger; the next ones peek out behind it
    private var cardDeck: some View {
        ZStack {
            //drawn back to front so the current card ends up on top
            ForEach((0..<cardCount).reversed(), id: \.self) { index in
                let position = index - currentCard
                if position >= 0 && position < visibleCards {
                    InstructionCard(number: index + 1, total: cardCount) {
                        cardContent(index)
                    }
                    .offset(x: position == 0 ? topCardOffset : 0, y: CGFloat(position) * 10)
                    .scaleEffect(1 - CGFloat(position) * 0.04)
                    .rotationEffect(.degrees(position == 0 ? Double(topCardOffset / 25) : stackTilt(for: index)))
                    .allowsHitTesting(position == 0)
                    //the top card slides off (or back on) from the left; cards joining or
                    //leaving the back of the stack just fade
                    .transition(position == 0 && !reducesMotion ? .move(edge: .leading).combined(with: .opacity) : .opacity)
                    .zIndex(Double(-position))
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    let distance = value.translation.width
                    if distance < -swipeThreshold {
                        showNextCard()
                    } else if distance > swipeThreshold {
                        showPreviousCard()
                    } else {
                        withAnimation(.spring(duration: 0.3)) { dragOffset = 0 }
                    }
                }
        )
    }

    //Swiping left flings the top card away. Swiping right brings the previous card back,
    //so the top card only budges a little in that direction, like it's held by the stack
    private var topCardOffset: CGFloat {
        let atLastCard = currentCard == cardCount - 1
        if dragOffset < 0 && !atLastCard { return dragOffset }
        return dragOffset / 4
    }

    //Gives the cards underneath a slightly uneven, hand-stacked look
    private func stackTilt(for index: Int) -> Double {
        index.isMultiple(of: 2) ? 2.5 : -2
    }

    private func showNextCard() {
        withAnimation(.spring(duration: 0.4)) {
            if currentCard < cardCount - 1 {
                currentCard += 1
            }
            dragOffset = 0
        }
    }

    private func showPreviousCard() {
        withAnimation(.spring(duration: 0.4)) {
            if currentCard > 0 {
                currentCard -= 1
            }
            dragOffset = 0
        }
    }

    //Page count, arrows for tapping through the cards, and the way back out
    private var controls: some View {
        VStack(spacing: orientation.isLandscape ? 4 : 10) {
            HStack(spacing: 24) {
                Button {
                    showPreviousCard()
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title)
                }
                .disabled(currentCard == 0)
                .accessibilityLabel("Previous card")

                Text("\(currentCard + 1) of \(cardCount)")
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)

                Button {
                    showNextCard()
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title)
                }
                .disabled(currentCard == cardCount - 1)
                .accessibilityLabel("Next card")
            }

            if vm.gameStarted {
                Button{
                    vm.gameState = .playing
                    vm.playSFX("buttondown1")
                } label: {
                    Label("Back", systemImage: "arrow.left")
                }
                .padding(.top, 4)

            } else {
                HomeButtonView(vm: vm)
            }
        }
    }

    //What goes on each card
    @ViewBuilder
    private func cardContent(_ index: Int) -> some View {
        switch index {
        case 0:
            CardPage(title: "Objective", message: "Find all the mines and mark each one with a flag.") {
                Image("Flag")
                    .resizable()
                    .frame(width: 90, height: 90)
                    .accessibilityHidden(true)
            }
        case 1:
            CardPage(title: "Reveal Tiles", message: "Tap on a tile to reveal what's underneath. The number shows how many of the surrounding tiles are mines.") {
                TileView(tile: $demoTileReveal, vm: vm)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        case 2:
            CardPage(title: "Watch Out", message: "If you tap on a mine tile, it explodes.\n(Which means you lose!)") {
                TileView(tile: $demoTileBomb, vm: vm)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        case 3:
            //VoiceOver can't drag, so explain the tile actions instead
            CardPage(title: "Flag the Mines", message: voiceOverEnabled
                     ? "Mark each mine with a flag. Select a tile, swipe up or down to the Flag action, then double-tap."
                     : "Mark each mine by dragging a flag over to the tile.") {
                toolIcon("Flag")
            }
        case 4:
            CardPage(title: "Dig Up a Flag", message: voiceOverEnabled
                     ? "To remove a flag, select the flagged tile and double-tap."
                     : "To remove a flag from a tile, drag and drop the shovel over the flag.") {
                toolIcon("Shovel")
            }
        case 5:
            CardPage(title: "Need a Hint?", message: "Tap the hint button to find out where you might have an issue.", footnote: "But be careful: tapping on it will cost you points!") {
                Label("Hint", systemImage: "lightbulb.fill")
                    .symbolRenderingMode(.multicolor)
                    .font(.title3.bold())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.tint, in: Capsule())
                    .foregroundStyle(.white)
            }
        default:
            CardPage(title: "Points") {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.yellow)
            } details: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("• Tapped tiles earn 50 points times the number of mines surrounding it")
                    Text("• Earn 25 points per additional tile revealed")
                    Text("• At end of game, earn 500 points + 200/mine")
                    Text("• Lose points when tapping the \"Hint\" button")
                }
                .font(.callout)
            }
        }
    }

    private func toolIcon(_ name: String) -> some View {
        ZStack {
            Circle()
                .fill(Color("tileBack"))
                .frame(width: 70, height: 70)
            Image(name)
                .resizable()
                .frame(width: 90, height: 90)
        }
        .accessibilityHidden(true)
    }
}

//A single instruction card, styled like a physical playing card
private struct InstructionCard<Content: View>: View {
    let number: Int
    let total: Int
    @ViewBuilder var content: Content

    var body: some View {
        VStack {
            content
            Spacer(minLength: 0)
            Text("\(number) / \(total)")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay {
                    //an inset border, like the printed edge on a playing card
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1.5)
                        .padding(8)
                }
                .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
        }
    }
}

//The layout inside a card: a picture, a title, and the explanation
private struct CardPage<Illustration: View, Details: View>: View {
    let title: String
    var message: String? = nil
    var footnote: String? = nil
    @ViewBuilder var illustration: Illustration
    @ViewBuilder var details: Details

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)
            illustration
            Text(title)
                .font(.title2.bold())
            if let message {
                Text(message)
                    .font(.body)
                    .multilineTextAlignment(.center)
            }
            details
            if let footnote {
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer(minLength: 0)
        }
        .minimumScaleFactor(0.7)
    }
}

extension CardPage where Details == EmptyView {
    init(title: String, message: String? = nil, footnote: String? = nil, @ViewBuilder illustration: () -> Illustration) {
        self.title = title
        self.message = message
        self.footnote = footnote
        self.illustration = illustration()
        self.details = EmptyView()
    }
}

#Preview {
    InstructionsView(vm: FieldViewModel())
        .environmentObject({
            let mock = OrientationModel()
            mock.current = .portrait
            return mock
        }())
}
