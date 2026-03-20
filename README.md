# Comic Archiv

A native macOS app for managing your personal comic collection. Catalog your comics with cover images, organize them into custom lists, track what you've read, plan reading orders, and keep a wishlist of comics you want to buy.

## Features

- **Comic Management** — Add, edit, and delete comics with cover images, authors, artists, publishers, release dates, genres, ratings, and read status
- **Series View** — Comics grouped by series with read progress tracking
- **List System** — Organize comics into custom lists; drag & drop between them
- **Reading Orders** — Ordered sequences with position tracking and placeholder support
- **Wishlist** — Track comics you want to buy; convert to real entries when purchased
- **"What to Read Next"** — Smart suggestions based on your collection and reading habits
- **Search & Auto-Fill** — Search multiple APIs to quickly fill in comic details
- **MyAnimeList Import** — Import your MAL manga list with covers, authors, and read status
- **XLSX Import/Export** — Import and export your collection as spreadsheet files
- **Drag & Drop** — Move and copy comics between lists with visual feedback

## Tech Stack

| Component | Technology |
|---|---|
| Language | Swift |
| UI Framework | SwiftUI |
| Architecture | MVVM |
| Persistence | SwiftData |
| Image Storage | FileManager (local) |
| Platform | macOS 13.0+ (Ventura) |

## APIs

Comic Archiv integrates with the following APIs for comic search and import:

- **[Comic Vine](https://comicvine.gamespot.com/api/)** — Search for comic issues and trade volumes (requires API key)
- **[AniList](https://anilist.gitbook.io/anilist-apiv2-docs/)** — Search for manga via GraphQL API
- **[Google Books](https://developers.google.com/books)** — Search for books and comics, including European/German editions (no API key required)
- **[MyAnimeList](https://myanimelist.net/apiconfig/references/api/v2)** — OAuth2 import of your manga reading list

## Building

1. Open `Comic Archiv/Comic Archiv.xcodeproj` in Xcode 15+
2. Build and run (⌘R)

For a standalone app: **Product → Archive → Distribute App → Copy App** and place it in `/Applications`.

## Credits

- App icon from [Freepik](https://www.freepik.com)
- Built with the help of [Claude](https://claude.ai) by Anthropic
