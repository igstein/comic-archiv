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
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Cover - echtes Bild oder Placeholder
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
                    } else {
                        Image(systemName: "book.closed")
                            .font(.system(size: 40))
                            .foregroundStyle(.gray)
                    }
                    
                    // Gelesen-Badge
                    if comic.gelesen {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.white)
                                    .background(
                                        Circle()
                                            .fill(.green)
                                            .padding(-4)
                                    )
                                    .padding(8)
                            }
                            Spacer()
                        }
                    }
                }
                
                // Comic Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(comic.titel)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                    
                    if !comic.autor.isEmpty {
                        Text(comic.autor)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        if !comic.verlag.isEmpty {
                            Text(comic.verlag)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        if !comic.nummer.isEmpty {
                            Text("#\(comic.nummer)")
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
        .onHover { hovering in
            isHovering = hovering
        }
        .onAppear {
            loadCoverImage()
        }
        .onChange(of: comic.coverBildName) { oldValue, newValue in
            loadCoverImage()
        }
        .onDrag {
            isDragging = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isDragging = false
            }
            
            return NSItemProvider(object: comic.id.uuidString as NSString)
        }
        
        .contextMenu {
            Button {
                onTap()
            } label: {
                Label("Bearbeiten", systemImage: "pencil")
            }
            
            Divider()
            
            Button {
                comic.gelesen.toggle()
            } label: {
                if comic.gelesen {
                    Label("Als ungelesen markieren", systemImage: "book")
                } else {
                    Label("Als gelesen markieren", systemImage: "checkmark.circle")
                }
            }
        }
    }
    
    private func loadCoverImage() {
        if let fileName = comic.coverBildName {
            coverImage = ImageManager.shared.loadImage(named: fileName)
        } else {
            coverImage = nil
        }
    }
}
