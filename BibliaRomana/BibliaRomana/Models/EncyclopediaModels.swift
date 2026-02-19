import Foundation
import CoreLocation

// MARK: - Encyclopedia Data Models

struct EncyclopediaData: Codable {
    let version: Int
    let entries: [EncyclopediaEntry]
}

struct EncyclopediaEntry: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let aliases: [String]
    let category: EntryCategory
    let subcategory: String?
    let description: String
    let significance: String
    let relatedVerses: [VerseReference]
    let relatedEntries: [String]
    let coordinates: EntryCoordinates?
    let timeline: String?

    enum EntryCategory: String, Codable, CaseIterable {
        case person
        case place
        case event
        case concept
        case object

        var displayName: String {
            switch self {
            case .person: return "Persoane"
            case .place: return "Locuri"
            case .event: return "Evenimente"
            case .concept: return "Concepte"
            case .object: return "Obiecte"
            }
        }

        var icon: String {
            switch self {
            case .person: return "person.fill"
            case .place: return "mappin.and.ellipse"
            case .event: return "calendar"
            case .concept: return "lightbulb.fill"
            case .object: return "archivebox.fill"
            }
        }
    }
}

struct VerseReference: Codable, Hashable {
    let book: String
    let chapter: Int
    let verse: Int

    var display: String { "\(book) \(chapter):\(verse)" }
}

struct EntryCoordinates: Codable, Hashable {
    let latitude: Double
    let longitude: Double
}

// MARK: - Map Location Model

struct BiblicalLocation: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let category: String
    let description: String
    let keyEvents: [String]
    let encyclopediaId: String?
}

struct BiblicalLocationsData: Codable {
    let locations: [BiblicalLocation]
}
