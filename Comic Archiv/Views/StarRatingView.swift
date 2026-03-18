//
//  StarRatingView.swift
//  Comic Archiv
//

import SwiftUI

// MARK: - Display-only star rating

struct StarRatingView: View {
    let rating: Double
    var maxRating: Int = 5
    var starSize: CGFloat = 16

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { index in
                starImage(for: index)
                    .font(.system(size: starSize))
                    .foregroundStyle(rating >= Double(index) - 0.25 ? .yellow : .secondary.opacity(0.3))
            }
        }
    }

    private func starImage(for index: Int) -> Image {
        let value = rating - Double(index - 1)
        if value >= 0.75 {
            return Image(systemName: "star.fill")
        } else if value >= 0.25 {
            return Image(systemName: "star.leadinghalf.filled")
        } else {
            return Image(systemName: "star")
        }
    }
}

// MARK: - Interactive star rating picker

struct StarRatingPicker: View {
    @Binding var rating: Double
    var maxRating: Int = 5
    var starSize: CGFloat = 24

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { index in
                // Each star has two tap zones: left half = .5, right half = full
                GeometryReader { geo in
                    ZStack {
                        starImage(for: index)
                            .font(.system(size: starSize))
                            .foregroundStyle(rating >= Double(index) - 0.25 ? .yellow : .secondary.opacity(0.3))
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                let half = geo.size.width / 2
                                let newRating = value.location.x < half
                                    ? Double(index) - 0.5
                                    : Double(index)
                                // Tap same value again to clear
                                rating = rating == newRating ? 0 : newRating
                            }
                    )
                }
                .frame(width: starSize, height: starSize)
            }

            if rating > 0 {
                Button {
                    rating = 0
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: rating)
    }

    private func starImage(for index: Int) -> Image {
        let value = rating - Double(index - 1)
        if value >= 0.75 {
            return Image(systemName: "star.fill")
        } else if value >= 0.25 {
            return Image(systemName: "star.leadinghalf.filled")
        } else {
            return Image(systemName: "star")
        }
    }
}
