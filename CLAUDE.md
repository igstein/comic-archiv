# Comic Archiv — Concept Document

## 1. Vision & Goal

**Comic Archiv** is a native multi-platform app for managing a personal comic collection. It lets you catalog your comics with cover images, organize them into custom lists, track what you've read, plan reading orders, and keep a wishlist of comics you want to buy.

**Core principle:** A private, offline-first collection manager that motivates you to actually read more of your comics — not just collect them. By tracking what you've read and what's still waiting, the app keeps you aware of your unread pile and makes it easy to decide what to pick up next.

**Platforms:**
- **macOS 13.0+ (Ventura)** — primary platform for managing the collection; full drag & drop, sidebar navigation, macOS widgets
- **iPadOS 17+** — planned future companion app; requires a paid Apple Developer account ($99/year) to run on a real device; deferred until then
- One shared Swift/SwiftUI codebase, synced via iCloud

---

## 2. Features

### 2.1 Comic Management
- Add, edit, and delete comics from your collection
- Fields per comic: title, author (Autor), artist (Zeichner), publisher (Verlag), release date (Erscheinungsdatum), issue number (Nummer), cover image, read status
- Cover images stored locally via FileManager
- Placeholder icon when no cover is available

### 2.2 List System
- **Meine Sammlung** — the main archive; contains all comics; cannot be deleted
- **Wishlist** — special list for comics you want to buy (PlaceholderComics)
- **Custom lists** — user-created, named, with optional SF Symbol icon
- **Reading Orders** — ordered sequences of comics with position tracking and placeholder support
- Comics can belong to multiple lists simultaneously (many-to-many)
- Drag & Drop to move/copy comics between lists

### 2.3 Reading Orders
- Ordered list of entries (ReadingOrderEntry) with a position index
- Each entry can be: a real Comic, a PlaceholderComic, or a named placeholder string
- Reading progress tracked automatically: how many entries are read vs. total
- "Zu kaufen" count: entries where no comic exists yet (placeholder)
- Comics can be dragged from any list into a Reading Order (copy mode — comic stays in original list)
- Duplicate handling: alert if comic is already in the Reading Order

### 2.4 Wishlist
- PlaceholderComics with `inWishlist: true` appear in the Wishlist
- When you buy a comic, you convert the placeholder to a real Comic entry
- Placeholders can also appear in Reading Orders to mark gaps in your collection

### 2.5 Drag & Drop
- Comics draggable within and between lists
- Reading Order entries reorderable via drag
- Comics from any list can be dropped into a Reading Order (appended at end)
- Visual drop-zone highlighting and feedback

### 2.6 List Views & Navigation
- Sidebar: system lists (Meine Sammlung, Wishlist) always at top, then custom lists, then Reading Orders in a separate section
- Main area: grid of comic cards or detail view
- Filter within a list, sort by title / date added / read status

### 2.7 iPadOS Companion App (Future — requires paid Apple Developer account)
- Optimized for use while reading — quickly mark the current issue as read
- Browse reading orders and see what's next in a series
- Check the wishlist at a comic shop before buying
- Add new comics or placeholders on the go
- Drag & Drop supported on iPadOS (reorder reading order entries, move comics between lists)
- Layout adapts: sidebar + content on iPad, tab-based navigation on iPhone

### 2.8 macOS Widgets (WidgetKit)
- Small widget: currently reading comic (cover + title + progress in reading order)
- Medium widget: next unread comics across all reading orders
- Reminder nudge: "You haven't marked anything as read in X days"
- Widgets read from the shared iCloud data — always up to date

---

## 3. Tech Stack

| Component | Technology |
|---|---|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| Architecture | MVVM |
| Persistence | SwiftData |
| Image Storage | FileManager (local) + iCloud Drive (synced) |
| Sync | iCloud / CloudKit (via SwiftData) |
| Widgets | WidgetKit (macOS) |
| Platforms | macOS 13.0+ (Ventura), iPadOS 17+ |
| Xcode | 15+ |

### Why This Stack?
- **SwiftUI:** Shared codebase across macOS and iPadOS with platform-adaptive layouts (`NavigationSplitView` on iPad/Mac, `TabView` on iPhone)
- **SwiftData + CloudKit:** Automatic iCloud sync with minimal boilerplate — one container, all devices
- **WidgetKit:** Native macOS widgets that read from the same SwiftData store
- **MVVM:** Clean separation of data logic (ComicViewModel) from views

---

## 4. Data Model (SwiftData)

### Comic
```swift
@Model final class Comic {
    var id: UUID
    var titel: String
    var autor: String
    var zeichner: String
    var verlag: String
    var erscheinungsdatum: Date
    var nummer: String
    var coverBildName: String?          // Filename in Documents folder
    var gelesen: Bool
    var erstelltAm: Date

    @Relationship(deleteRule: .nullify, inverse: \ComicListe.comics)
    var listen: [ComicListe]?

    @Relationship(deleteRule: .nullify)
    var readingOrderEntries: [ReadingOrderEntry]?
}
```

### ComicListe
```swift
@Model final class ComicListe {
    var id: UUID
    var name: String
    var icon: String?                   // SF Symbol name
    var istHauptliste: Bool             // "Meine Sammlung" — cannot be deleted
    var istWishlist: Bool               // Wishlist — cannot be deleted
    var istReadingOrder: Bool           // Reading Order type
    var erstelltAm: Date

    @Relationship(deleteRule: .nullify)
    var comics: [Comic]                 // Many-to-many

    @Relationship(deleteRule: .cascade)
    var readingOrderEntries: [ReadingOrderEntry]

    // Computed
    var isSystemList: Bool              // istHauptliste || istWishlist
    var readingProgress: (gelesen: Int, gesamt: Int, zuKaufen: Int)?
    var sortedReadingOrderEntries: [ReadingOrderEntry]
}
```

### ReadingOrderEntry
```swift
@Model final class ReadingOrderEntry {
    var id: UUID
    var position: Int
    var comic: Comic?                   // Real comic (optional)
    var placeholder: PlaceholderComic?  // Placeholder comic (optional)
    var placeholderName: String?        // Simple string placeholder (optional)
    var notiz: String?
    var erstelltAm: Date

    @Relationship(inverse: \ComicListe.readingOrderEntries)
    var liste: ComicListe?

    // Computed
    var isPlaceholder: Bool
    var displayName: String             // comic?.titel ?? placeholder?.name ?? placeholderName
}
```

### PlaceholderComic
```swift
@Model final class PlaceholderComic {
    var id: UUID
    var name: String
    var inWishlist: Bool                // true = show in Wishlist
    var erstelltAm: Date

    @Relationship(deleteRule: .nullify)
    var readingOrderEntries: [ReadingOrderEntry]
}
```

---

## 5. Project File Structure

```
Comic Archiv/                        (Xcode project root)
├── App/
│   └── ComicArchivApp.swift
├── Models/
│   ├── Comic.swift
│   ├── ComicListe.swift
│   ├── ReadingOrderEntry.swift
│   ├── PlaceholderComic.swift
│   └── TestData.swift
├── ViewModels/
│   └── ComicViewModel.swift          (central data logic, ObservableObject)
├── Views/
│   ├── MainView.swift
│   ├── ContentView.swift
│   ├── SidebarView.swift
│   ├── ComicGridView.swift
│   ├── ComicCardView.swift
│   ├── ComicDetailView.swift
│   ├── WishlistContentView.swift
│   ├── ReadingOrderContentView.swift
│   ├── AddComicSheet.swift
│   ├── AddComicSheetForPlaceholder.swift
│   ├── AddListeSheet.swift
│   ├── EditListeSheet.swift
│   ├── AddReadingOrderSheet.swift
│   ├── AddReadingOrderEntrySheet.swift
│   └── EditReadingOrderEntrySheet.swift
├── Services/
│   └── ImageManager.swift            (cover image load/save/delete)
├── Helpers/
└── Resources/
    └── Assets.xcassets
```

---

## 6. UI Concept

### Main Layout
```
+------------------+------------------------------------------+
|  Sidebar         |  Main Content                            |
|                  |                                          |
|  Meine Sammlung  |  [Grid of comic cards]                  |
|  Wishlist        |                                          |
|                  |  +------+  +------+  +------+           |
|  Meine Listen    |  |Cover |  |Cover |  |Cover |           |
|  > Marvel        |  |      |  |      |  |      |           |
|  > DC            |  |Titel |  |Titel |  |Titel |           |
|  > Favoriten     |  | [v]  |  |      |  | [v]  |           |
|                  |  +------+  +------+  +------+           |
|  Reading Orders  |                                          |
|  > DC Rebirth    |                                          |
|  > X-Men Classic |                                          |
|                  |                                          |
|  [+ Neue Liste]  |                                          |
+------------------+------------------------------------------+
```

### Comic Card
- Cover image (or placeholder icon)
- Title
- Issue number
- Green checkmark badge when `gelesen == true`

### Comic Detail View
- Large cover image with option to change/remove
- All fields editable inline
- Gelesen toggle
- List membership shown
- Delete button (destructive, with confirmation)

### Reading Order View
- Ordered list of entries with position numbers
- Each row: position, cover thumbnail, title, read indicator
- Placeholder entries shown with different styling (greyed out / "zu kaufen" badge)
- Progress bar: gelesen / gesamt
- Drag to reorder entries

---

## 7. Code Conventions

### Language
- **Variable and property names:** German (e.g., `titel`, `gelesen`, `erstelltAm`, `istHauptliste`)
- **Type names and Swift keywords:** English / Swift conventions (e.g., `ComicViewModel`, `@Model`, `ObservableObject`)
- **Comments:** German for business logic explanations
- **Swift naming conventions:** camelCase for properties/functions, PascalCase for types

### Architecture
- `ComicViewModel` is the single source of truth — all mutations go through it
- Views observe `ComicViewModel` via `@StateObject` / `@EnvironmentObject`
- SwiftData `@Model` classes are the persistence layer; ViewModels wrap queries and mutations
- `ImageManager` handles all file system operations for cover images

### Patterns
- Always provide SwiftUI previews for views
- Use `.sheet` for add/edit modals
- Context menus on sidebar list rows for rename/delete
- Confirmations (`.confirmationDialog` or `Alert`) before destructive actions
- System lists (`istHauptliste`, `istWishlist`) are protected — no delete, no rename

---

## 8. Development Roadmap

### Phase 1: Foundation — DONE
- [x] Xcode project setup
- [x] Data models: Comic, ComicListe, ReadingOrderEntry, PlaceholderComic
- [x] SwiftData persistence
- [x] MVVM with ComicViewModel
- [x] Sidebar + grid main layout
- [x] Add / edit / delete comics
- [x] List management (create, rename, delete)
- [x] Cover image upload and local storage
- [x] Drag & Drop between lists
- [x] Gelesen status toggle

### Phase 2: Reading Orders & Wishlist — DONE
- [x] Reading Order list type with ordered entries
- [x] PlaceholderComic model for wishlist and reading order gaps
- [x] Wishlist view (PlaceholderComics with inWishlist)
- [x] Reading progress tracking (gelesen / gesamt / zuKaufen)
- [x] Add comics to reading order via drag & drop
- [x] Reorder reading order entries

### Phase 3: Polish — IN PROGRESS
- [ ] Default Erscheinungsdatum: 01.01.1900 instead of today
- [ ] System lists always pinned at top of sidebar
- [ ] No test data on first launch — only Meine Sammlung + Wishlist
- [ ] Delete button styling (destructive red, centered)
- [ ] Icon picker: visual SF Symbol grid, filtered by list type
- [ ] Padding fix in "Neue Reading Order" sheet
- [ ] Drag & Drop from list into Reading Order (copy mode, duplicate alert)

### Phase 4: iCloud Sync
- [ ] Enable CloudKit container in Xcode project
- [ ] Configure SwiftData model container for iCloud sync
- [ ] Handle many-to-many relationship sync edge cases (Comic ↔ ComicListe)
- [ ] Image sync: store cover images in iCloud Drive alongside the database
- [ ] Test sync between Mac and iPad (add on Mac → appears on iPad, mark read on iPad → reflects on Mac)
- [ ] Conflict handling: last-write-wins (sufficient for single-user)

### Phase 5: iPadOS App (Future — requires paid Apple Developer account)
- [ ] Subscribe to Apple Developer Program ($99/year)
- [ ] Add iPadOS target to Xcode project
- [ ] `NavigationSplitView` layout for iPad (sidebar + content, same as macOS)
- [ ] Adapt Comic Detail view for touch (larger tap targets, swipe gestures)
- [ ] "Mark as read" quick action — prominent button for the primary use case
- [ ] Reading Order view optimized for touch (tap to advance through series)
- [ ] Drag & Drop on iPadOS (reorder reading order, move comics between lists)
- [ ] Wishlist quick-add from iPad (at a comic shop)
- [ ] App icon for iPadOS

### Phase 6: macOS Widgets (WidgetKit)
- [ ] WidgetKit extension target in Xcode project
- [ ] Small widget: currently reading comic (cover + title)
- [ ] Medium widget: next unread comics in active reading orders
- [ ] Widget data reads from shared iCloud SwiftData store
- [ ] Configurable widget: choose which reading order to display

### Phase 7: Future Features
- [ ] Search (by title, author, publisher)
- [ ] Filter by publisher, read status, list membership
- [ ] Sort options (title, date added, issue number)
- [ ] Star ratings per comic
- [ ] Notes / journal per comic
- [ ] CSV export / import
- [ ] Duplicate detection
- [ ] Statistics (read count, collection size over time)
- [ ] App icons (macOS + iPadOS)

---

## 9. Technical Notes

### Cover Images
- Currently stored in the app's Documents directory via `ImageManager`
- `Comic.coverBildName` holds the filename (not a full path)
- On delete, the image file must also be removed by `ImageManager`
- For iCloud sync: images will be stored in the iCloud Drive app container so they sync alongside the database — not in Supabase or any external service

### iCloud Sync (CloudKit)
- SwiftData supports CloudKit sync via `ModelContainer` with a CloudKit container identifier
- Many-to-many relationships (Comic ↔ ComicListe) require careful testing — CloudKit handles them differently than local SwiftData
- Sync is automatic once the CloudKit container is configured — no manual sync logic needed
- All devices must be signed in to the same iCloud account
- Offline changes are queued and synced when connectivity is restored
- Single-user app: no conflict resolution strategy needed beyond last-write-wins

### Platform-Specific UI Notes
- **macOS:** `NavigationSplitView` with sidebar + detail, full drag & drop, toolbar buttons, context menus
- **iPadOS:** Same `NavigationSplitView` layout in landscape; sidebar collapses in portrait; touch-optimized detail view
- Use `#if os(macOS)` / `#if os(iOS)` sparingly — prefer adaptive SwiftUI where possible
- WidgetKit extension runs as a separate process; reads from the shared CloudKit SwiftData store via an App Group or shared container

### SwiftData Relationships
- Comic ↔ ComicListe: many-to-many via `@Relationship(inverse:)`
- ComicListe → ReadingOrderEntry: one-to-many, cascade delete
- ReadingOrderEntry → Comic: optional, nullify on delete
- ReadingOrderEntry → PlaceholderComic: optional, nullify on delete

### System Lists
- `istHauptliste == true`: "Meine Sammlung" — all comics always appear here
- `istWishlist == true`: "Wishlist" — shows PlaceholderComics with `inWishlist == true`
- Both are created on first launch and cannot be deleted or renamed
- `isSystemList` computed property: `istHauptliste || istWishlist`

### Reading Order Entry Types
Three mutually exclusive entry types in one model:
1. `comic != nil` — linked to a real owned comic
2. `placeholder != nil` — linked to a PlaceholderComic (in wishlist)
3. `placeholderName != nil` — simple string, comic not tracked at all

---

*Created: January 2026*
*Last Updated: March 2026*
*Project: Comic Archiv — Native macOS + iPadOS App*
*Stack: Swift / SwiftUI / SwiftData / CloudKit / WidgetKit*
