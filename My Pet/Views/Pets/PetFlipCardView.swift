
import SwiftUI

struct PetFlipCardView: View {

    let pet: Pet

    @State private var isFlipped = false

    private let cardHeight: CGFloat = 400
    private let cornerRadius: CGFloat = 24

    private var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.30, blue: 0.29),
                Color(red: 0.12, green: 0.43, blue: 0.39)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Back face
                backCard
                    .rotation3DEffect(
                        .degrees(isFlipped ? 0 : -180),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.65
                    )
                    .opacity(isFlipped ? 1 : 0)

                // Front face
                frontCard
                    .rotation3DEffect(
                        .degrees(isFlipped ? 180 : 0),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.65
                    )
                    .opacity(isFlipped ? 0 : 1)
            }
            .frame(height: cardHeight)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
            )
            .contentShape(
                RoundedRectangle(cornerRadius: cornerRadius)
            )
            .shadow(
                color: .black.opacity(0.18),
                radius: 10,
                x: 0,
                y: 6
            )
            .onTapGesture {
                withAnimation(
                    .spring(response: 0.65, dampingFraction: 0.82)
                ) {
                    isFlipped.toggle()
                }
            }
            .accessibilityElement()
            .accessibilityLabel(
                isFlipped
                    ? "Pet care information for \(pet.name)"
                    : "Profile card for \(pet.name)"
            )
            .accessibilityHint("Double tap to flip the card")

            HStack(spacing: 8) {
                Image(
                    systemName: isFlipped
                        ? "arrow.uturn.backward.circle"
                        : "hand.tap"
                )

                Text(
                    isFlipped
                        ? "Tap card to return to profile"
                        : "Tap card to reveal care information"
                )
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Front

    private var frontCard: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                cardGradient

                petPhoto
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .clipped()

                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.25),
                        .black.opacity(0.85)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(
                            "FurryTails",
                            systemImage: "pawprint.fill"
                        )
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())

                        Spacer()

                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.title3.weight(.semibold))
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text(pet.name)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(
                        "\(pet.species) • \(pet.breed ?? "Breed not specified")"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)

                    if let age = pet.age {
                        Text("Age: \(age) \(age == 1 ? "year" : "years")")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    HStack {
                        Image(systemName: "heart.fill")
                        Text("My Pet's Care Card")

                        Spacer()

                        Image(systemName: "hand.tap.fill")
                        Text("Flip")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.top, 10)
                }
                .padding(20)
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
            )
        }
        .frame(height: cardHeight)
    }

    // MARK: - Pet Photo

    private var petPhoto: some View {
        Group {
            if !pet.petImageURL.isEmpty,
               let url = URL(string: pet.petImageURL) {

                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

                    case .failure(_), .empty:
                        imagePlaceholder

                    @unknown default:
                        imagePlaceholder
                    }
                }

            } else {
                imagePlaceholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: cardHeight)
        .clipped()
    }

    private var imagePlaceholder: some View {
        ZStack {
            cardGradient

            Image(systemName: "pawprint.fill")
                .font(.system(size: 75))
                .foregroundStyle(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .frame(height: cardHeight)
    }

    // MARK: - Back

    private var backCard: some View {
        ZStack {
            cardGradient

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 10) {
                        Image(systemName: "heart.text.clipboard.fill")
                            .font(.title2)
                            .foregroundStyle(
                                Color(
                                    red: 0.65,
                                    green: 0.91,
                                    blue: 0.79
                                )
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            Text("PET CARE HUB")
                                .font(.caption.weight(.bold))
                                .tracking(1.5)
                                .foregroundStyle(.white.opacity(0.75))

                            Text(pet.name)
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        }

                        Spacer()
                    }

                    Divider()
                        .overlay(.white.opacity(0.25))

                    careRow(
                        icon: "number",
                        title: "Microchip",
                        value: available(pet.microchipNumber)
                    )

                    careRow(
                        icon: "syringe.fill",
                        title: "Vaccinations",
                        value: "Not recorded"
                    )

                    careRow(
                        icon: "calendar",
                        title: "Vet appointments",
                        value: "Not recorded"
                    )

                    careRow(
                        icon: "pills.fill",
                        title: "Medications & allergies",
                        value: "Not recorded"
                    )

                    careRow(
                        icon: "fork.knife",
                        title: "Food preferences",
                        value: "Not recorded"
                    )

                    careRow(
                        icon: "bell.badge.fill",
                        title: "Care reminders",
                        value: "Not recorded"
                    )

                    if let sex = pet.sex, !sex.isEmpty {
                        careRow(
                            icon: "pawprint.fill",
                            title: "Sex",
                            value: sex
                        )
                    }

                    if let color = pet.color, !color.isEmpty {
                        careRow(
                            icon: "paintpalette.fill",
                            title: "Color",
                            value: color
                        )
                    }

                    Text(
                        "Only saved pet profile details are shown. "
                        + "Veterinary records will appear here once connected."
                    )
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 4)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: cardHeight)
        .clipShape(
            RoundedRectangle(
                cornerRadius: cornerRadius,
                style: .continuous
            )
        )
    }

    // MARK: - Care Row

    private func careRow(
        icon: String,
        title: String,
        value: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(
                    Color(red: 0.65, green: 0.91, blue: 0.79)
                )
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Text(value)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private func available(_ value: String?) -> String {
        guard let value, !value.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {
            return "Not recorded"
        }

        return value
    }
}

