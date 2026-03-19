//
//  XLSXService.swift
//  Comic Archiv
//

import Foundation

// MARK: - Error

enum XLSXError: LocalizedError {
    case zipFailed
    case unzipFailed
    case sheetNotFound

    var errorDescription: String? {
        switch self {
        case .zipFailed:    return "Failed to create XLSX file"
        case .unzipFailed:  return "Failed to read XLSX file — make sure the file is a valid .xlsx"
        case .sheetNotFound: return "Could not find worksheet in XLSX file"
        }
    }
}

// MARK: - Import Row

struct ComicRow {
    var title: String
    var author: String
    var artist: String
    var publisher: String
    var releaseDate: String
    var issueNumber: String
    var readStatus: String
    var priority: String
    var genre: String
    var notes: String
    var series: String
    var seriesLength: String
    var rating: String
    var format: String
    var lastReadAt: String
    var createdAt: String
}

// MARK: - Service

final class XLSXService: @unchecked Sendable {
    static let shared = XLSXService()

    static let columnHeaders = [
        "title", "author", "artist", "publisher", "releaseDate", "issueNumber",
        "readStatus", "priority", "genre", "notes", "series", "seriesLength",
        "rating", "format", "lastReadAt", "createdAt"
    ]

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()

    // MARK: - Export

    func exportData(comics: [Comic]) throws -> Data {
        guard
            let contentTypes = contentTypesXML().data(using: .utf8),
            let dotRels      = dotRelsXML().data(using: .utf8),
            let workbook     = workbookXML().data(using: .utf8),
            let wbRels       = workbookRelsXML().data(using: .utf8),
            let styles       = stylesXML().data(using: .utf8),
            let sheet        = worksheetXML(comics: comics).data(using: .utf8)
        else { throw XLSXError.zipFailed }

        let entries: [(path: String, data: Data)] = [
            ("[Content_Types].xml",         contentTypes),
            ("_rels/.rels",                 dotRels),
            ("xl/workbook.xml",             workbook),
            ("xl/_rels/workbook.xml.rels",  wbRels),
            ("xl/styles.xml",               styles),
            ("xl/worksheets/sheet1.xml",    sheet),
        ]
        return buildZip(entries: entries)
    }

    func export(comics: [Comic]) throws -> URL {
        let stamp = Self.dateFormatter.string(from: Date()).replacingOccurrences(of: "-", with: "")
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ComicArchiv_\(stamp).xlsx")
        try? FileManager.default.removeItem(at: outputURL)

        guard
            let contentTypes = contentTypesXML().data(using: .utf8),
            let dotRels      = dotRelsXML().data(using: .utf8),
            let workbook     = workbookXML().data(using: .utf8),
            let wbRels       = workbookRelsXML().data(using: .utf8),
            let styles       = stylesXML().data(using: .utf8),
            let sheet        = worksheetXML(comics: comics).data(using: .utf8)
        else {
            throw XLSXError.zipFailed
        }

        let entries: [(path: String, data: Data)] = [
            ("[Content_Types].xml",          contentTypes),
            ("_rels/.rels",                  dotRels),
            ("xl/workbook.xml",              workbook),
            ("xl/_rels/workbook.xml.rels",   wbRels),
            ("xl/styles.xml",                styles),
            ("xl/worksheets/sheet1.xml",     sheet),
        ]

        let zipData = buildZip(entries: entries)
        do {
            try zipData.write(to: outputURL)
        } catch {
            throw XLSXError.zipFailed
        }
        return outputURL
    }

    // MARK: - Import

    func importComics(from url: URL) throws -> [ComicRow] {
        guard let zipData = try? Data(contentsOf: url) else {
            throw XLSXError.unzipFailed
        }

        let files = readZip(data: zipData)
        guard !files.isEmpty else { throw XLSXError.unzipFailed }

        // Parse shared strings (Excel-generated files use these)
        var sharedStrings: [String] = []
        if let ssData = files["xl/sharedStrings.xml"] {
            sharedStrings = parseSharedStrings(data: ssData)
        }

        // Parse worksheet
        guard let sheetData = files["xl/worksheets/sheet1.xml"] else {
            throw XLSXError.sheetNotFound
        }

        let rawRows = parseSheet(data: sheetData, sharedStrings: sharedStrings)
        return mapToComicRows(rawRows: rawRows)
    }

    // MARK: - Pure Swift ZIP Writer

    private func buildZip(entries: [(path: String, data: Data)]) -> Data {
        // DOS time/date for "now"
        let comps = Calendar(identifier: .gregorian)
            .dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        let h: Int = comps.hour ?? 0
        let m: Int = comps.minute ?? 0
        let s: Int = comps.second ?? 0
        let dosTime = UInt16((h << 11) | (m << 5) | (s / 2))
        let yr: Int = (comps.year ?? 1980) - 1980
        let mo: Int = comps.month ?? 1
        let dy: Int = comps.day ?? 1
        let dosDate = UInt16((yr << 9) | (mo << 5) | dy)

        var localSection   = Data()
        var centralDir     = Data()
        var localOffsets   = [UInt32]()

        for (path, data) in entries {
            let pathBytes  = Data(path.utf8)
            let checksum   = crc32(data)
            let size       = UInt32(data.count)
            let pathLen    = UInt16(pathBytes.count)
            let offset     = UInt32(localSection.count)
            localOffsets.append(offset)

            // Local file header
            localSection += u32(0x04034b50)
            localSection += u16(20)          // version needed
            localSection += u16(0)           // flags
            localSection += u16(0)           // STORED
            localSection += u16(dosTime)
            localSection += u16(dosDate)
            localSection += u32(checksum)
            localSection += u32(size)        // compressed = uncompressed for STORED
            localSection += u32(size)
            localSection += u16(pathLen)
            localSection += u16(0)           // extra field length
            localSection += pathBytes
            localSection += data

            // Central directory entry
            centralDir += u32(0x02014b50)
            centralDir += u16(20)            // version made by
            centralDir += u16(20)            // version needed
            centralDir += u16(0)             // flags
            centralDir += u16(0)             // STORED
            centralDir += u16(dosTime)
            centralDir += u16(dosDate)
            centralDir += u32(checksum)
            centralDir += u32(size)
            centralDir += u32(size)
            centralDir += u16(pathLen)
            centralDir += u16(0)             // extra field length
            centralDir += u16(0)             // comment length
            centralDir += u16(0)             // disk number
            centralDir += u16(0)             // internal attributes
            centralDir += u32(0)             // external attributes
            centralDir += u32(offset)
            centralDir += pathBytes
        }

        let cdOffset = UInt32(localSection.count)
        let cdSize   = UInt32(centralDir.count)
        let count    = UInt16(entries.count)

        var eocd = Data()
        eocd += u32(0x06054b50)
        eocd += u16(0)      // disk
        eocd += u16(0)      // disk with CD
        eocd += u16(count)
        eocd += u16(count)
        eocd += u32(cdSize)
        eocd += u32(cdOffset)
        eocd += u16(0)      // comment length

        return localSection + centralDir + eocd
    }

    // MARK: - Pure Swift ZIP Reader (STORED entries only)
    //
    // Reads the central directory to enumerate files and their data offsets.
    // Handles compression method 0 (STORED). DEFLATE (method 8) files return nil
    // data; parsing still succeeds for STORED worksheets exported from this app.

    private func readZip(data: Data) -> [String: Data] {
        var result: [String: Data] = [:]

        // Locate End of Central Directory signature (search backwards)
        let eocdSig: [UInt8] = [0x50, 0x4B, 0x05, 0x06]
        guard let eocdPos = lastIndex(of: eocdSig, in: data) else { return result }

        guard eocdPos + 22 <= data.count else { return result }
        let entryCount  = Int(data.leUInt16(at: eocdPos + 8))
        let cdOffset    = Int(data.leUInt32(at: eocdPos + 16))

        var pos = cdOffset
        for _ in 0..<entryCount {
            guard pos + 46 <= data.count else { break }
            guard data.leUInt32(at: pos) == 0x02014b50 else { break }

            let compression  = data.leUInt16(at: pos + 10)
            let compSize     = Int(data.leUInt32(at: pos + 20))
            let fileNameLen  = Int(data.leUInt16(at: pos + 28))
            let extraLen     = Int(data.leUInt16(at: pos + 30))
            let commentLen   = Int(data.leUInt16(at: pos + 32))
            let localOffset  = Int(data.leUInt32(at: pos + 42))

            let nameStart    = pos + 46
            let nameEnd      = nameStart + fileNameLen
            guard nameEnd <= data.count else { break }
            let fileName = String(data: data[nameStart..<nameEnd], encoding: .utf8) ?? ""

            // Read from local file header
            if compression == 0, localOffset + 30 <= data.count,
               data.leUInt32(at: localOffset) == 0x04034b50 {
                let localFNLen    = Int(data.leUInt16(at: localOffset + 26))
                let localExtraLen = Int(data.leUInt16(at: localOffset + 28))
                let dataStart     = localOffset + 30 + localFNLen + localExtraLen
                let dataEnd       = dataStart + compSize
                if dataEnd <= data.count {
                    result[fileName] = data[dataStart..<dataEnd]
                }
            }

            pos = nameEnd + extraLen + commentLen
        }

        return result
    }

    private func lastIndex(of pattern: [UInt8], in data: Data) -> Int? {
        guard data.count >= pattern.count else { return nil }
        let lastPossible = data.count - pattern.count
        for i in stride(from: lastPossible, through: 0, by: -1) {
            if data[i..<(i + pattern.count)].elementsEqual(pattern) {
                return i
            }
        }
        return nil
    }

    // MARK: - XML Generation

    private func contentTypesXML() -> String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
          <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
          <Default Extension="xml" ContentType="application/xml"/>
          <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
          <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
          <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
        </Types>
        """
    }

    private func dotRelsXML() -> String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
        </Relationships>
        """
    }

    private func workbookXML() -> String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
          <sheets>
            <sheet name="Comics" sheetId="1" r:id="rId1"/>
          </sheets>
        </workbook>
        """
    }

    private func workbookRelsXML() -> String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
          <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
        </Relationships>
        """
    }

    private func stylesXML() -> String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
          <fonts count="2">
            <font><sz val="11"/><name val="Calibri"/></font>
            <font><b/><sz val="11"/><name val="Calibri"/></font>
          </fonts>
          <fills count="2">
            <fill><patternFill patternType="none"/></fill>
            <fill><patternFill patternType="gray125"/></fill>
          </fills>
          <borders count="1">
            <border><left/><right/><top/><bottom/><diagonal/></border>
          </borders>
          <cellStyleXfs count="1">
            <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
          </cellStyleXfs>
          <cellXfs count="2">
            <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
            <xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0"/>
          </cellXfs>
        </styleSheet>
        """
    }

    private func worksheetXML(comics: [Comic]) -> String {
        var parts: [String] = [
            """
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <sheetData>
            """
        ]

        // Header row (bold, style index 1)
        var headerCells = ""
        for (i, header) in Self.columnHeaders.enumerated() {
            headerCells += "<c r=\"\(col(i))1\" t=\"inlineStr\" s=\"1\"><is><t>\(esc(header))</t></is></c>"
        }
        parts.append("    <row r=\"1\">\(headerCells)</row>")

        // Data rows
        for (rowIdx, comic) in comics.enumerated() {
            let rowNum = rowIdx + 2
            var cells = ""
            for (colIdx, value) in comicToValues(comic).enumerated() {
                guard !value.isEmpty else { continue }
                let ref = "\(col(colIdx))\(rowNum)"
                // seriesLength (11) and rating (12) as plain numbers
                if colIdx == 11 || colIdx == 12 {
                    cells += "<c r=\"\(ref)\"><v>\(esc(value))</v></c>"
                } else {
                    cells += "<c r=\"\(ref)\" t=\"inlineStr\"><is><t>\(esc(value))</t></is></c>"
                }
            }
            parts.append("    <row r=\"\(rowNum)\">\(cells)</row>")
        }

        parts.append("  </sheetData>\n</worksheet>")
        return parts.joined(separator: "\n")
    }

    // MARK: - Data Conversion

    private func comicToValues(_ comic: Comic) -> [String] {
        [
            comic.title,
            comic.author,
            comic.artist,
            comic.publisher,
            Self.dateFormatter.string(from: comic.releaseDate),
            comic.issueNumber,
            comic.readStatus.rawValue,
            comic.priority.rawValue,
            comic.genre,
            comic.notes,
            comic.series,
            comic.seriesLength.map { String($0) } ?? "",
            String(comic.rating),
            comic.format.rawValue,
            comic.lastReadAt.map { Self.dateFormatter.string(from: $0) } ?? "",
            Self.dateFormatter.string(from: comic.createdAt),
        ]
    }

    private func mapToComicRows(rawRows: [[String: String]]) -> [ComicRow] {
        guard !rawRows.isEmpty else { return [] }

        // First row: column letter → header name; build reverse map
        var headerToCol: [String: String] = [:]
        for (col, name) in rawRows[0] { headerToCol[name] = col }

        return rawRows.dropFirst().compactMap { row in
            func val(_ h: String) -> String { row[headerToCol[h] ?? ""] ?? "" }
            let title = val("title")
            guard !title.isEmpty else { return nil }
            return ComicRow(
                title: title, author: val("author"), artist: val("artist"),
                publisher: val("publisher"), releaseDate: val("releaseDate"),
                issueNumber: val("issueNumber"), readStatus: val("readStatus"),
                priority: val("priority"), genre: val("genre"), notes: val("notes"),
                series: val("series"), seriesLength: val("seriesLength"),
                rating: val("rating"), format: val("format"),
                lastReadAt: val("lastReadAt"), createdAt: val("createdAt")
            )
        }
    }

    // MARK: - XML Parsing

    private func parseSharedStrings(data: Data) -> [String] {
        let delegate = SharedStringsParser()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.strings
    }

    private func parseSheet(data: Data, sharedStrings: [String]) -> [[String: String]] {
        let delegate = SheetParser(sharedStrings: sharedStrings)
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.rows
    }

    // MARK: - Helpers

    /// Convert 0-based column index to spreadsheet letter (0→"A", 25→"Z", 26→"AA"…)
    private func col(_ index: Int) -> String {
        var result = ""
        var n = index
        repeat {
            result = String(UnicodeScalar(65 + (n % 26))!) + result
            n = n / 26 - 1
        } while n >= 0
        return result
    }

    private func esc(_ str: String) -> String {
        str
            .replacingOccurrences(of: "&",  with: "&amp;")
            .replacingOccurrences(of: "<",  with: "&lt;")
            .replacingOccurrences(of: ">",  with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    // MARK: - ZIP binary helpers

    private func u16(_ v: UInt16) -> Data {
        var x = v.littleEndian; return withUnsafeBytes(of: &x) { Data($0) }
    }
    private func u32(_ v: UInt32) -> Data {
        var x = v.littleEndian; return withUnsafeBytes(of: &x) { Data($0) }
    }

    private func crc32(_ data: Data) -> UInt32 {
        let table: [UInt32] = (0..<256).map { i -> UInt32 in
            var c = UInt32(i)
            for _ in 0..<8 { c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1 }
            return c
        }
        return data.reduce(UInt32(0xFFFFFFFF)) { crc, byte in
            table[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8)
        } ^ 0xFFFFFFFF
    }
}

// MARK: - Data helpers for little-endian reads

private extension Data {
    func leUInt16(at offset: Int) -> UInt16 {
        guard offset + 2 <= count else { return 0 }
        return UInt16(self[offset]) | (UInt16(self[offset + 1]) << 8)
    }
    func leUInt32(at offset: Int) -> UInt32 {
        guard offset + 4 <= count else { return 0 }
        return UInt32(self[offset])
            | (UInt32(self[offset + 1]) << 8)
            | (UInt32(self[offset + 2]) << 16)
            | (UInt32(self[offset + 3]) << 24)
    }
}

// MARK: - XML Parser Delegates

private final class SharedStringsParser: NSObject, XMLParserDelegate {
    var strings: [String] = []
    private var currentText = ""
    private var inSI = false
    private var inT  = false

    func parser(_ parser: XMLParser, didStartElement el: String, namespaceURI: String?,
                qualifiedName: String?, attributes: [String: String] = [:]) {
        if el == "si"            { inSI = true; currentText = "" }
        else if inSI && el == "t" { inT = true }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inT { currentText += string }
    }

    func parser(_ parser: XMLParser, didEndElement el: String, namespaceURI: String?,
                qualifiedName: String?) {
        if      el == "si" { strings.append(currentText); inSI = false; inT = false }
        else if el == "t"  { inT = false }
    }
}

private final class SheetParser: NSObject, XMLParserDelegate {
    let sharedStrings: [String]
    var rows: [[String: String]] = []

    private var currentRow: [String: String] = [:]
    private var inRow  = false
    private var cRef   = ""
    private var cType  = ""
    private var cVal   = ""
    private var inV    = false
    private var inT    = false
    private var inIS   = false

    init(sharedStrings: [String]) { self.sharedStrings = sharedStrings }

    func parser(_ parser: XMLParser, didStartElement el: String, namespaceURI: String?,
                qualifiedName: String?, attributes attrs: [String: String] = [:]) {
        switch el {
        case "row":
            currentRow = [:]; inRow = true
        case "c" where inRow:
            cRef = attrs["r"] ?? ""; cType = attrs["t"] ?? ""; cVal = ""
            inV = false; inT = false; inIS = false
        case "v"  where inRow: inV  = true
        case "is" where inRow: inIS = true
        case "t"  where inIS:  inT  = true
        default: break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inV { cVal += string }
        if inT { cVal += string }
    }

    func parser(_ parser: XMLParser, didEndElement el: String, namespaceURI: String?,
                qualifiedName: String?) {
        switch el {
        case "c" where inRow:
            let value: String
            if cType == "s" {
                let idx = Int(cVal.trimmingCharacters(in: .whitespaces)) ?? 0
                value = idx < sharedStrings.count ? sharedStrings[idx] : ""
            } else {
                value = cVal
            }
            let letters = String(cRef.prefix(while: { $0.isLetter }))
            if !letters.isEmpty { currentRow[letters] = value }
            inV = false; inT = false; inIS = false
        case "row": rows.append(currentRow); inRow = false
        case "v":   inV  = false
        case "is":  inIS = false
        case "t":   inT  = false
        default:    break
        }
    }
}
