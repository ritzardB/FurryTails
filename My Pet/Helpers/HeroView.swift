//  HeroView.swift
//  My Pet
//
//  Created by Richard Balabarcon on 06/10/2026.
//

import SwiftUI

struct HeroView: View {

    let onFinished: () -> Void

    var body: some View {
        ZStack {
            // Background
            FurryTailsTheme.heroGradient
                .ignoresSafeArea()

            // Hero image
            Image("heropet")
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()
                .overlay {
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.05),
                            Color.black.opacity(0.08),
                            Color.black.opacity(0.45)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

            // Branding
            VStack(spacing: 8) {

                Spacer()

                Text("WELCOME TO")
                    .font(
                        .system(
                            size: 14,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.9))

                Text("FurryTails")
                    .font(
                        .system(
                            size: 36,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundColor(.white)

                Text(
                    "Where every pet has a story,\nand every tail has a happy ending."
                )
                .font(
                    .system(
                        size: 16,
                        weight: .medium,
                        design: .rounded
                    )
                )
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.92))
                .lineSpacing(4)

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .task {
            try? await Task.sleep(for: .seconds(5))

            guard !Task.isCancelled else {
                return
            }

            withAnimation(.easeInOut(duration: 0.5)) {
                onFinished()
            }
        }
    }
}

#Preview {
    HeroView(
        onFinished: {
            print("🐾 Hero finished")
        }
    )
}
