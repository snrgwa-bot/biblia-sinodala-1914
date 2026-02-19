import Foundation
import Security

@MainActor
class StorageService: ObservableObject {
    static let shared = StorageService()

    @Published var annotations: [Annotation] = []
    @Published var settings: UserSettings

    // Dictionary index for O(1) annotation lookups
    private var highlightIndex: [String: Annotation.HighlightColor] = [:]
    private var noteIndex: [String: String] = [:]

    private let annotationsKey = "bible_annotations"
    private let settingsKey = "user_settings"
    private let keychainService = "com.nexubible.BibliaRomana"
    private let keychainAccount = "gemini_api_key"

    init() {
        // Load settings
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let saved = try? JSONDecoder().decode(UserSettings.self, from: data) {
            self.settings = saved
        } else {
            self.settings = UserSettings()
        }

        // Load API key from Keychain
        self.settings.geminiApiKey = loadKeychain() ?? ""

        // Load annotations
        if let data = UserDefaults.standard.data(forKey: annotationsKey),
           let saved = try? JSONDecoder().decode([Annotation].self, from: data) {
            self.annotations = saved
        }

        rebuildIndex()
        loadVisitedChapters()
    }

    // MARK: - Settings

    func saveSettings() {
        // Save API key to Keychain separately
        if !settings.geminiApiKey.isEmpty {
            saveKeychain(settings.geminiApiKey)
        } else {
            deleteKeychain()
        }

        // Save settings without API key in UserDefaults
        var settingsToSave = settings
        settingsToSave.geminiApiKey = ""
        if let data = try? JSONEncoder().encode(settingsToSave) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    // MARK: - Keychain

    private func saveKeychain(_ value: String) {
        deleteKeychain()
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Annotation Index

    private func rebuildIndex() {
        highlightIndex = [:]
        noteIndex = [:]
        for a in annotations {
            switch a.type {
            case .highlight:
                if let color = a.color {
                    highlightIndex[a.verseId] = color
                }
            case .note:
                if let content = a.content {
                    noteIndex[a.verseId] = content
                }
            }
        }
    }

    // MARK: - Annotations

    func addHighlight(verseId: String, color: Annotation.HighlightColor) {
        annotations.removeAll { $0.verseId == verseId && $0.type == .highlight }
        let annotation = Annotation(
            id: UUID().uuidString,
            verseId: verseId,
            type: .highlight,
            color: color,
            content: nil,
            inkColor: nil,
            timestamp: Date()
        )
        annotations.append(annotation)
        highlightIndex[verseId] = color
        saveAnnotations()
    }

    func addNote(verseId: String, content: String, inkColor: Annotation.NoteInkColor? = nil) {
        let existingInk = annotations.first(where: { $0.verseId == verseId && $0.type == .note })?.inkColor
        annotations.removeAll { $0.verseId == verseId && $0.type == .note }
        let annotation = Annotation(
            id: UUID().uuidString,
            verseId: verseId,
            type: .note,
            color: nil,
            content: content,
            inkColor: inkColor ?? existingInk,
            timestamp: Date()
        )
        annotations.append(annotation)
        noteIndex[verseId] = content
        saveAnnotations()
    }

    func noteInkColor(for verseId: String) -> Annotation.NoteInkColor? {
        annotations.first(where: { $0.verseId == verseId && $0.type == .note })?.inkColor
    }

    func setNoteInkColor(verseId: String, inkColor: Annotation.NoteInkColor?) {
        if let idx = annotations.firstIndex(where: { $0.verseId == verseId && $0.type == .note }) {
            annotations[idx].inkColor = inkColor
            saveAnnotations()
        }
    }

    func removeAnnotation(verseId: String, type: Annotation.AnnotationType) {
        annotations.removeAll { $0.verseId == verseId && $0.type == type }
        switch type {
        case .highlight: highlightIndex.removeValue(forKey: verseId)
        case .note: noteIndex.removeValue(forKey: verseId)
        }
        saveAnnotations()
    }

    // O(1) lookups via index
    func highlightColor(for verseId: String) -> Annotation.HighlightColor? {
        highlightIndex[verseId]
    }

    func note(for verseId: String) -> String? {
        noteIndex[verseId]
    }

    func hasAnnotation(verseId: String) -> Bool {
        highlightIndex[verseId] != nil || noteIndex[verseId] != nil
    }

    private func saveAnnotations() {
        if let data = try? JSONEncoder().encode(annotations) {
            UserDefaults.standard.set(data, forKey: annotationsKey)
        }
    }

    // MARK: - Reading Position

    func saveReadingPosition(bookId: String, chapter: Int) {
        UserDefaults.standard.set(bookId, forKey: "last_book")
        UserDefaults.standard.set(chapter, forKey: "last_chapter")
    }

    func lastReadingPosition() -> (bookId: String, chapter: Int)? {
        guard let bookId = UserDefaults.standard.string(forKey: "last_book") else { return nil }
        let chapter = UserDefaults.standard.integer(forKey: "last_chapter")
        return (bookId, max(chapter, 1))
    }

    // MARK: - Visited Chapters

    @Published var visitedChapters: Set<String> = [] {
        didSet { saveVisitedChapters() }
    }

    func markChapterVisited(bookId: String, chapter: Int) {
        let key = "\(bookId)_\(chapter)"
        if !visitedChapters.contains(key) {
            visitedChapters.insert(key)
        }
    }

    func isChapterVisited(bookId: String, chapter: Int) -> Bool {
        visitedChapters.contains("\(bookId)_\(chapter)")
    }

    func visitedChapterCount(for bookId: String, totalChapters: Int) -> Int {
        (1...totalChapters).filter { visitedChapters.contains("\(bookId)_\($0)") }.count
    }

    private func loadVisitedChapters() {
        if let array = UserDefaults.standard.stringArray(forKey: "visited_chapters") {
            visitedChapters = Set(array)
        }
    }

    private func saveVisitedChapters() {
        UserDefaults.standard.set(Array(visitedChapters), forKey: "visited_chapters")
    }
}
