import Foundation

// MARK: - Bible Data Models

struct Verse: Codable, Identifiable, Hashable {
    var id: String { "\(bookId)_\(chapter)_\(verse)" }
    let bookId: String
    let bookName: String
    let chapter: Int
    let verse: Int
    let text: String

    enum CodingKeys: String, CodingKey {
        case bookId = "book_id"
        case bookName = "book_name"
        case chapter, verse, text
    }
}

struct BibleBook: Identifiable, Hashable {
    let id: String
    let name: String
    let chapters: Int
    let testament: Testament

    enum Testament: String {
        case old = "Vechiul Testament"
        case new = "Noul Testament"
        case deuterocanonical = "Cărți Deuterocanonice"
    }
}

struct Annotation: Codable, Identifiable {
    let id: String
    let verseId: String
    var type: AnnotationType
    var color: HighlightColor?
    var content: String?
    var inkColor: NoteInkColor?
    var timestamp: Date

    enum AnnotationType: String, Codable {
        case highlight
        case note
    }

    enum HighlightColor: String, Codable, CaseIterable {
        case yellow, lime, pink, blue, orange
    }

    enum NoteInkColor: String, Codable, CaseIterable {
        case blue, red, gray
    }
}

struct DictionaryEntry: Codable {
    let word: String
    let definition: String
    let biblicalContext: String
}

struct WordExplanation: Codable {
    let word: String
    let meaning: String
    let originalLanguage: String
    let explanation: String
}

struct Perspective: Codable, Identifiable {
    var id: String { character }
    let character: String
    let insight: String
}

// MARK: - User Settings

enum ThemeMode: String, Codable, CaseIterable {
    case light = "Luminos"
    case dark = "\u{00CE}ntunecat"
    case system = "Sistem"
}

enum FontSizeOption: String, Codable, CaseIterable {
    case sm = "Mic"
    case base = "Normal"
    case lg = "Mare"
    case xl = "Foarte Mare"
    case xxl = "Enorm"

    var pointSize: CGFloat {
        switch self {
        case .sm: return 14
        case .base: return 17
        case .lg: return 20
        case .xl: return 24
        case .xxl: return 28
        }
    }
}

enum FontType: String, Codable, CaseIterable {
    case sans = "Sans Serif"
    case serif = "Serif"
    case mono = "Monospaced"

    var fontDesign: String {
        switch self {
        case .sans: return "default"
        case .serif: return "serif"
        case .mono: return "monospaced"
        }
    }
}

struct UserSettings: Codable, Equatable {
    var theme: ThemeMode = .system
    var fontSize: FontSizeOption = .base
    var fontType: FontType = .serif
    var geminiApiKey: String = ""
    var preferStaticMap: Bool = false
    var twoColumnLayout: Bool = true
}
