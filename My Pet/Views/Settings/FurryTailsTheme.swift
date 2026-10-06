//
//  FurryTailsTheme.swift
//  My Pets
//
//  FurryTails App Theme
//

import SwiftUI

enum FurryTailsTheme {

    // MARK: - Primary Colors

    static let orange = Color(
        red: 0.95,
        green: 0.45,
        blue: 0.18
    )

    static let orangeLight = Color(
        red: 1.00,
        green: 0.65,
        blue: 0.32
    )

    static let orangeSoft = Color(
        red: 1.00,
        green: 0.82,
        blue: 0.58
    )

    static let brown = Color(
        red: 0.45,
        green: 0.23,
        blue: 0.10
    )

    // MARK: - Background

    static let background = Color(
        red: 1.00,
        green: 0.97,
        blue: 0.93
    )

    static let cardBackground = Color.white

    // MARK: - Text

    static let primaryText = Color(
        red: 0.20,
        green: 0.14,
        blue: 0.10
    )

    static let secondaryText = Color(
        red: 0.45,
        green: 0.40,
        blue: 0.36
    )

    // MARK: - Gradients

    static let primaryGradient = LinearGradient(
        colors: [
            orangeLight,
            orange
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let backgroundGradient = LinearGradient(
        colors: [
            Color.white,
            background,
            orangeSoft.opacity(0.65)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let heroGradient = LinearGradient(
        colors: [
            orange.opacity(0.95),
            orangeLight.opacity(0.75),
            Color(
                red: 0.95,
                green: 0.45,
                blue: 0.18
            )
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
