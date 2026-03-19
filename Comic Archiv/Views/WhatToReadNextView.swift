//
//  WhatToReadNextView.swift
//  Comic Archiv
//

import SwiftUI

struct WhatToReadNextView: View {
    let comics: [Comic]
    let onComicTapped: (Comic) -> Void
    
    @State private var coverImages: [UUID: NSImage] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("What to Read Next", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(comics) { comic in
                        SuggestionCard(
                            comic: comic,
                            coverImage: coverImages[comic.id],
                            onTap: { onComicTapped(comic) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .background(Color(.controlBackgroundColor).opacity(0.5))
        .onAppear {
            loadAllCoverImages()
        }
        .onChange(of: comics) { _, _ in
            loadAllCoverImages()
        }
    }
    
    private func loadAllCoverImages() {
        for comic in comics {
            if let fileName = comic.coverImageName {
                coverImages[comic.id] = ImageManager.shared.loadImage(named: fileName)
            }
        }
    }
}

// MARK: - Suggestion Card

private struct SuggestionCard: View {
    let comic: Comic
    let coverImage: NSImage?
    let onTap: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Cover Image
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 90)
                    
                    if let image = coverImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Image(systemName: "book.closed")
                            .font(.system(size: 24))
                            .foregroundStyle(.gray)
                    }
                }
                .overlay(alignment: .topLeading) {
                    priorityBadge
                        .padding(4)
                }
                
                // Comic Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(comic.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if !comic.author.isEmpty {
                        Text(comic.author)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 4) {
                        if !comic.issueNumber.isEmpty {
                            Text("#\(comic.issueNumber)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if !comic.publisher.isEmpty {
                            if !comic.issueNumber.isEmpty {
                                Text("•")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            Text(comic.publisher)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }
                    
                    // Read status indicator
                    HStack(spacing: 4) {
                        Image(systemName: comic.readStatus.icon)
                            .font(.caption2)
                        Text(comic.readStatus.label)
                            .font(.caption2)
                    }
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.15))
                    )
                }
                .frame(width: 180, alignment: .leading)
                
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(width: 280)
            .background(Color(.windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(
                color: .black.opacity(isHovering ? 0.15 : 0.08),
                radius: isHovering ? 8 : 4,
                y: isHovering ? 4 : 2
            )
            .scaleEffect(isHovering ? 1.03 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
    
    @ViewBuilder
    private var priorityBadge: some View {
        switch comic.priority {
        case .mustRead:
            Image(systemName: "star.fill")
                .font(.caption2)
                .foregroundStyle(.white)
                .padding(3)
                .background(Circle().fill(Color.yellow))
        case .high:
            Image(systemName: "circle.fill")
                .font(.caption2)
                .foregroundStyle(.white)
                .padding(3)
                .background(Circle().fill(Color.orange))
        case .medium, .low:
            EmptyView()
        }
    }
    
    private var statusColor: Color {
        switch comic.readStatus {
        case .unread:    return .gray
        case .reading:   return .blue
        case .paused:    return .orange
        case .finished:  return .green
        case .abandoned: return .red
        }
    }
}

#Preview {
    let comic1 = Comic(
        title: "The Amazing Spider-Man",
        author: "Stan Lee",
        publisher: "Marvel",
        issueNumber: "1",
        readStatus: .reading,
        priority: .mustRead,
        series: "The Amazing Spider-Man"
    )

    let comic2 = Comic(
        title: "Batman: The Killing Joke",
        author: "Alan Moore",
        publisher: "DC Comics",
        issueNumber: "1",
        readStatus: .unread,
        priority: .high,
        series: "Batman: The Killing Joke"
    )

    let comic3 = Comic(
        title: "Watchmen",
        author: "Alan Moore",
        publisher: "DC Comics",
        issueNumber: "1",
        readStatus: .unread,
        priority: .medium,
        series: "Watchmen"
    )
    
    return WhatToReadNextView(comics: [comic1, comic2, comic3]) { comic in
        print("Tapped: \(comic.title)")
    }
    .frame(height: 160)
}
