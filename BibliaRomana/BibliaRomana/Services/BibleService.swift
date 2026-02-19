import Foundation

// MARK: - Bible JSON Data Model

struct BibleJSON: Codable {
    let name: String
    let edition: String
    let year: Int
    let language: String
    let source: String
    let license: String
    let books: [BibleJSONBook]
}

struct BibleJSONBook: Codable {
    let name: String
    let fullName: String
    let testament: String
    let chapters: [String: [BibleJSONVerse]]
    let chapterCount: Int
}

struct BibleJSONVerse: Codable {
    let verse: Int
    let text: String
}

// MARK: - Bible Service

@MainActor
class BibleService: ObservableObject {
    static let shared = BibleService()

    @Published var currentVerses: [Verse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var bibleBooks: [BibleBook] = []

    private var bibleData: BibleJSON?

    init() {
        loadBundledBible()
    }

    // MARK: - Load Bundled JSON

    private func loadBundledBible() {
        guard let url = Bundle.main.url(forResource: "biblia_1914", withExtension: "json") else {
            errorMessage = "Fișierul Bibliei nu a fost găsit în aplicație."
            loadFallbackBooks()
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let bible = try JSONDecoder().decode(BibleJSON.self, from: data)
            self.bibleData = bible

            // Build BibleBook list from JSON
            self.bibleBooks = bible.books.map { jsonBook in
                let testament: BibleBook.Testament
                switch jsonBook.testament {
                case "new":
                    testament = .new
                case "deuterocanonical":
                    testament = .deuterocanonical
                default:
                    testament = .old
                }
                return BibleBook(
                    id: jsonBook.name,
                    name: jsonBook.name,
                    chapters: jsonBook.chapterCount,
                    testament: testament
                )
            }
        } catch {
            errorMessage = "Eroare la citirea Bibliei: \(error.localizedDescription)"
            loadFallbackBooks()
        }
    }

    private func loadFallbackBooks() {
        self.bibleBooks = [
            BibleBook(id: "Facerea", name: "Facerea", chapters: 50, testament: .old),
            BibleBook(id: "Psalmii", name: "Psalmii", chapters: 150, testament: .old),
            BibleBook(id: "Matei", name: "Matei", chapters: 28, testament: .new),
        ]
    }

    // MARK: - Fetch Verses

    func fetchVerses(bookName: String, chapter: Int) {
        isLoading = true
        errorMessage = nil

        guard let bible = bibleData else {
            isLoading = false
            errorMessage = "Biblia nu este disponibilă."
            return
        }

        guard let book = bible.books.first(where: { $0.name == bookName }) else {
            isLoading = false
            errorMessage = "Cartea '\(bookName)' nu a fost găsită."
            return
        }

        let chapterKey = String(chapter)
        guard let jsonVerses = book.chapters[chapterKey] else {
            isLoading = false
            errorMessage = "Capitolul \(chapter) nu a fost găsit."
            return
        }

        self.currentVerses = jsonVerses.map { jv in
            Verse(
                bookId: bookName,
                bookName: bookName,
                chapter: chapter,
                verse: jv.verse,
                text: jv.text
            )
        }

        isLoading = false
    }

    // MARK: - Word Search

    struct SearchResult: Identifiable {
        let id = UUID()
        let bookName: String
        let chapter: Int
        let verse: Int
        let text: String

        var reference: String { "\(bookName) \(chapter):\(verse)" }
    }

    func searchVerses(containing word: String) -> [SearchResult] {
        guard let bible = bibleData else { return [] }
        let lowered = word.lowercased()
        var results: [SearchResult] = []

        for book in bible.books {
            for (chapterKey, verses) in book.chapters.sorted(by: { (Int($0.key) ?? 0) < (Int($1.key) ?? 0) }) {
                for jv in verses {
                    if jv.text.lowercased().contains(lowered) {
                        results.append(SearchResult(
                            bookName: book.name,
                            chapter: Int(chapterKey) ?? 0,
                            verse: jv.verse,
                            text: jv.text
                        ))
                    }
                }
            }
        }
        return results
    }

    // MARK: - Source Info

    static let sourceAttribution = "Biblia Ortodox\u{0103} Sinodal\u{0103}, Edi\u{021B}ia Sf\u{00E2}ntului Sinod, 1914"
    static let sourceURL = "https://archive.org/details/biblia-1914-v123"
    static let sourceLicense = "Domeniu Public"
}
