//
//  FloatingPointsView.swift
//  MineSeeker
//

import SwiftUI

//"+50" or "-25" that drifts up and fades away. With Reduce Motion it fades in place
struct FloatingPointsView: View {
    @Environment(\.reducesMotion) var reducesMotion

    let amount: Int
    //how far it drifts up
    var rise: CGFloat = 30

    @State private var hasRisen = false
    @State private var hasFaded = false

    var body: some View {
        Text(amount > 0 ? "+\(amount)" : "\(amount)")
            .font(.headline.bold())
            .foregroundStyle(amount < 0 ? .red : .yellow)
            //keeps it readable over any tile color
            .shadow(color: .black.opacity(0.7), radius: 2)
            .fixedSize()
            .offset(y: hasRisen && !reducesMotion ? -rise : 0)
            .opacity(hasFaded ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 0.9)) {
                    hasRisen = true
                }
                //stays solid for a moment so it can be read, then fades
                withAnimation(.easeIn(duration: 0.4).delay(0.5)) {
                    hasFaded = true
                }
            }
            .allowsHitTesting(false)
            //VoiceOver users hear results from announcements and the hint alert instead
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 40) {
        FloatingPointsView(amount: 150)
        FloatingPointsView(amount: -25)
    }
}
