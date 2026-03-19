//
//  ComicCardView.swift
//  Comic Archiv
//

import SwiftUI
import UniformTypeIdentifiers

struct ComicCardView: View {
    let comic: Comic
    let onTap: () -> Void

    @State private var isDragging = false
    @State private var isHovering = false
    @State private var coverImage: NSImage?

    var body: some View {
        Button { onTap() } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    // Cover
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(2/3, contentMode: .fit)

                        if let image = coverImage {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .aspectRatio(2/3, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .brightness(comic.readStatus == .finished ? -0.3 : comic.readStatus == .abandoned ? -0.45 : 0)
                                .saturation(comic.readStatus == .finished ? 0.5 : comic.readStatus == .abandoned ? 0.2 : 1)
                        } else {
                            Image(systemName: "book.closed")
                                .font(.system(size: 40))
                                .foregroundStyle(.gray)
                        }
                    }

                    // Priority badge (top-left)
                    priorityBadge.padding(6)

                    // Read status badge (top-right)
                    VStack {
                        HStack {
                            Spacer()
                            statusBadge.padding(6)
                        }
                        Spacer()
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(comic.title)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundStyle(.primary)

                    if !comic.author.isEmpty {
                        Text(comic.author)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    HStack {
                        if !comic.publisher.isEmpty {
                            Text(comic.publisher)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                        Spacer()
                        if !comic.issueNumber.isEmpty {
                            Text("#\(comic.issueNumber)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .padding(8)
            .background(Color(.windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(borderColor, lineWidth: comic.readStatus == .unread || comic.readStatus == .reading ? 0 : 2)
            )
            .shadow(
                color: .black.opacity(isDragging ? 0.3 : (isHovering ? 0.15 : 0.1)),
                radius: isDragging ? 12 : (isHovering ? 8 : 4),
                y: isDragging ? 8 : (isHovering ? 4 : 2)
            )
            .opacity(isDragging ? 0.5 : 1.0)
            .scaleEffect(isHovering && !isDragging ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .onAppear { loadCoverImage() }
        .onChange(of: comic.coverImageName) { _, _ in loadCoverImage() }
        .onDrag {
            isDragging = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isDragging = false }
            return NSItemProvider(object: comic.id.uuidString as NSString)
        }
        .contextMenu {
            Button { onTap() } label: { Label("Edit", systemImage: "pencil") }
            Divider()
            Menu("Set Status") {
                Button { setStatus(.unread) }    label: { Label("Unread",    systemImage: "book.closed") }
                Button { setStatus(.reading) }   label: { Label("Reading",   systemImage: "book") }
                Button { setStatus(.paused) }    label: { Label("Paused",    systemImage: "pause.circle") }
                Button { setStatus(.finished) }  label: { Label("Finished",  systemImage: "checkmark.circle") }
                Button { setStatus(.abandoned) } label: { Label("Abandoned", systemImage: "xmark.circle") }
            }
        }
    }

    @ViewBuilder
    private var priorityBadge: some View {
        switch comic.priority {
        case .mustRead:
            Image(systemName: "star.fill")
                .font(.caption2).foregroundStyle(.white).padding(4)
                .background(Circle().fill(Color.yellow))
        case .high:
            Image(systemName: "circle.fill")
                .font(.caption2).foregroundStyle(.white).padding(4)
                .background(Circle().fill(Color.orange))
        case .medium, .low:
            EmptyView()
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch comic.readStatus {
        case .finished:
            statusPill(label: "✓ Finished", color: .green)
        case .abandoned:
            statusPill(label: "✗ Abandoned", color: .gray)
        case .reading:
            statusPill(label: "Reading", color: .blue)
        case .paused:
            statusPill(label: "Paused", color: .orange)
        case .unread:
            EmptyView()
        }
    }

    private func statusPill(label: String, color: Color) -> some View {
        Text(label)
            .font(.system(size: 9, weight: .bold))
            .textCase(.uppercase)
            .foregroundStyle(.white)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(Capsule().fill(color))
    }

    private var borderColor: Color {
        switch comic.readStatus {
        case .finished:  return .green
        case .abandoned: return .gray
        case .paused:    return .orange
        default:         return .clear
        }
    }

    private func setStatus(_ status: ReadStatus) {
        if status == .finished { comic.lastReadAt = Date() }
        comic.readStatus = status
    }

    private func loadCoverImage() {
        if let fileName = comic.coverImageName {
            coverImage = ImageManager.shared.loadImage(named: fileName)
        } else {
            coverImage = nil
        }
    }
}
