import Foundation

// MARK: - Encyclopedia Service

@MainActor
class EncyclopediaService: ObservableObject {
    static let shared = EncyclopediaService()

    @Published var entries: [EncyclopediaEntry] = []
    @Published var locations: [BiblicalLocation] = []

    private var nameIndex: [String: EncyclopediaEntry] = [:]
    private var aliasIndex: [String: EncyclopediaEntry] = [:]
    private var idIndex: [String: EncyclopediaEntry] = [:]

    init() {
        loadEncyclopedia()
        loadLocations()
    }

    // MARK: - Load Data

    private func loadEncyclopedia() {
        guard let url = Bundle.main.url(forResource: "encyclopedia_ro", withExtension: "json") else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(EncyclopediaData.self, from: data)
            entries = decoded.entries
            buildIndex()
        } catch {
            print("Encyclopedia load error: \(error)")
        }
    }

    private func loadLocations() {
        guard let url = Bundle.main.url(forResource: "biblical_locations", withExtension: "json") else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(BiblicalLocationsData.self, from: data)
            locations = decoded.locations
        } catch {
            print("Locations load error: \(error)")
        }
    }

    private func buildIndex() {
        for entry in entries {
            idIndex[entry.id] = entry
            nameIndex[entry.name.lowercased()] = entry
            for alias in entry.aliases {
                aliasIndex[alias.lowercased()] = entry
            }
        }
    }

    // MARK: - Search & Filter

    func search(query: String) -> [EncyclopediaEntry] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return entries }
        return entries.filter { entry in
            entry.name.lowercased().contains(q) ||
            entry.aliases.contains(where: { $0.lowercased().contains(q) }) ||
            entry.description.lowercased().contains(q)
        }
    }

    func filter(category: EncyclopediaEntry.EntryCategory) -> [EncyclopediaEntry] {
        entries.filter { $0.category == category }
    }

    func entry(byId id: String) -> EncyclopediaEntry? {
        idIndex[id]
    }

    func lookup(word: String) -> EncyclopediaEntry? {
        let lowered = word.lowercased()
        return nameIndex[lowered] ?? aliasIndex[lowered]
    }

    func entriesWithCoordinates() -> [EncyclopediaEntry] {
        entries.filter { $0.coordinates != nil }
    }
}

// MARK: - AI Cache for Encyclopedia

class EncyclopediaAICache {
    static let shared = EncyclopediaAICache()
    private let key = "encyclopedia_ai_cache"

    func get(entryId: String) -> String? {
        let dict = UserDefaults.standard.dictionary(forKey: key) as? [String: String] ?? [:]
        return dict[entryId]
    }

    func save(entryId: String, text: String) {
        var dict = UserDefaults.standard.dictionary(forKey: key) as? [String: String] ?? [:]
        dict[entryId] = text
        UserDefaults.standard.set(dict, forKey: key)
    }
}
