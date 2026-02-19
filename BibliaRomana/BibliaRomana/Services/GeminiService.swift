import Foundation

// MARK: - Gemini AI Service

@MainActor
class GeminiService: ObservableObject {
    static let shared = GeminiService()

    @Published var isLoading = false
    @Published var lastError: String?

    private static let _k: [UInt8] = [
        0xE6, 0xEE, 0xDD, 0xC6, 0xF4, 0xDE, 0xE4, 0xC9,
        0xC1, 0xDF, 0xCE, 0xD4, 0xEF, 0xD6, 0xDF, 0xF0,
        0x9F, 0xCF, 0x9E, 0xF2, 0x9E, 0xF8, 0xC4, 0x91,
        0x97, 0x93, 0x91, 0xF6, 0xD0, 0xF3, 0xD5, 0xD6,
        0xFD, 0xD4, 0x8A, 0xD0, 0xF1, 0xF6, 0xE6
    ]
    private static let _m: UInt8 = 0xA7

    private static func _dk() -> String {
        String(_k.map { Character(UnicodeScalar($0 ^ _m)) })
    }

    private var apiKey: String {
        let userKey = StorageService.shared.settings.geminiApiKey
        if !userKey.isEmpty && userKey != "PLACEHOLDER_API_KEY" {
            return userKey
        }
        return Self._dk()
    }

    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 45
        return URLSession(configuration: config)
    }()

    var isConfigured: Bool {
        !apiKey.isEmpty
    }

    // MARK: - Word Definition

    func getWordDefinition(word: String) async -> DictionaryEntry? {
        guard isConfigured else { return nil }
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        let safeWord = sanitize(word)
        let prompt = """
        Explic\u{0103} cuv\u{00E2}ntul biblic "\(safeWord)" \u{00EE}n limba rom\u{00E2}n\u{0103}. R\u{0103}spunde doar cu JSON valid \u{00EE}n formatul:
        {"word": "\(safeWord)", "definition": "defini\u{021B}ia aici", "biblicalContext": "context biblic aici"}
        """

        guard let text = await callGemini(model: "gemini-2.5-flash", prompt: prompt) else { return nil }
        let cleaned = extractJSON(from: text)
        guard let data = cleaned.data(using: .utf8) else {
            lastError = "R\u{0103}spuns invalid de la AI."
            return nil
        }
        do {
            return try JSONDecoder().decode(DictionaryEntry.self, from: data)
        } catch {
            lastError = "Nu s-a putut procesa r\u{0103}spunsul AI."
            return nil
        }
    }

    // MARK: - Word in Context

    func getWordInContext(word: String, verseText: String, verseRef: String) async -> WordExplanation? {
        guard isConfigured else { return nil }
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        let safeWord = sanitize(word)
        let safeVerse = sanitize(String(verseText.prefix(300)))
        let safeRef = sanitize(verseRef)

        let prompt = """
        Explic\u{0103} cuv\u{00E2}ntul "\(safeWord)" a\u{0219}a cum apare \u{00EE}n versetul biblic: "\(safeVerse)" (\(safeRef)).
        R\u{0103}spunde \u{00EE}n limba rom\u{00E2}n\u{0103} doar cu JSON valid:
        {"word": "\(safeWord)", "meaning": "sensul cuv\u{00E2}ntului \u{00EE}n context", "originalLanguage": "cuv\u{00E2}ntul original \u{00EE}n greac\u{0103}/ebraic\u{0103} dac\u{0103} se cunoa\u{0219}te, altfel gol", "explanation": "explica\u{021B}ie mai detaliat\u{0103} a cuv\u{00E2}ntului \u{00EE}n contextul biblic"}
        """

        guard let text = await callGemini(model: "gemini-2.5-flash", prompt: prompt) else { return nil }
        let cleaned = extractJSON(from: text)
        guard let data = cleaned.data(using: .utf8) else {
            lastError = "R\u{0103}spuns invalid de la AI."
            return nil
        }
        do {
            return try JSONDecoder().decode(WordExplanation.self, from: data)
        } catch {
            lastError = "Nu s-a putut procesa r\u{0103}spunsul AI."
            return nil
        }
    }

    // MARK: - Verse Explanation (does not use shared isLoading to avoid sheet re-render)

    func getVerseExplanation(verseText: String, verseRef: String) async -> String? {
        guard isConfigured else { return nil }

        let safeText = sanitize(String(verseText.prefix(500)))
        let safeRef = sanitize(verseRef)
        let prompt = """
        Explic\u{0103} pe scurt versetul biblic \(safeRef): "\(safeText)".
        Scrie \u{00EE}n limba rom\u{00E2}n\u{0103}, maxim 3-4 propozi\u{021B}ii. Include contextul biblic \u{0219}i semnifica\u{021B}ia spiritual\u{0103}. Nu folosi format JSON, scrie doar text simplu.
        """
        return await callGemini(model: "gemini-2.5-flash", prompt: prompt)
    }

    // MARK: - Encyclopedia Deep Dive (does not use shared isLoading)

    func getEncyclopediaDetails(name: String, category: String, description: String) async -> String? {
        guard isConfigured else { return nil }
        let safeName = sanitize(name)
        let safeDesc = sanitize(String(description.prefix(300)))
        let prompt = """
        Ofer\u{0103} informa\u{021B}ii detaliate despre \"\(safeName)\" din perspectiv\u{0103} biblic\u{0103}.
        Categorie: \(category). Context: \(safeDesc).
        Scrie \u{00EE}n limba rom\u{00E2}n\u{0103}, 4-6 propozi\u{021B}ii. Include detalii istorice, teologice \u{0219}i semnifica\u{021B}ia spiritual\u{0103}.
        Nu folosi format JSON, scrie doar text simplu.
        """
        return await callGemini(model: "gemini-2.5-flash", prompt: prompt)
    }

    // MARK: - Verse Summary

    func getVerseSummary(verseText: String) async -> String? {
        guard isConfigured else { return nil }
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        let safeText = sanitize(String(verseText.prefix(500)))
        let prompt = "F\u{0103} un rezumat scurt (max 2 propozi\u{021B}ii) \u{00EE}n limba rom\u{00E2}n\u{0103} pentru acest verset biblic: \"\(safeText)\""
        return await callGemini(model: "gemini-2.5-flash", prompt: prompt)
    }

    // MARK: - Event Perspectives

    func getEventPerspectives(verseRef: String) async -> [Perspective] {
        guard isConfigured else { return [] }
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        let safeRef = sanitize(verseRef)
        let prompt = """
        Pentru versetul sau evenimentul biblic "\(safeRef)", ofer\u{0103} 3 perspective diferite de la personaje implicate. Scrie totul \u{00EE}n limba rom\u{00E2}n\u{0103}. R\u{0103}spunde doar cu JSON valid:
        [{"character": "nume personaj", "insight": "perspectiva aici"}, ...]
        """

        guard let text = await callGemini(model: "gemini-2.5-flash", prompt: prompt) else { return [] }
        let cleaned = extractJSON(from: text)
        guard let data = cleaned.data(using: .utf8) else {
            lastError = "R\u{0103}spuns invalid de la AI."
            return []
        }
        do {
            return try JSONDecoder().decode([Perspective].self, from: data)
        } catch {
            lastError = "Nu s-a putut procesa r\u{0103}spunsul AI."
            return []
        }
    }

    // MARK: - Private API Call

    private func callGemini(model: String, prompt: String) async -> String? {
        let urlString = "\(baseURL)/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            lastError = "URL invalid."
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ]
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            lastError = "Eroare la preg\u{0103}tirea cererii."
            return nil
        }
        request.httpBody = httpBody

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                lastError = "R\u{0103}spuns invalid de la server."
                return nil
            }

            guard httpResponse.statusCode == 200 else {
                let errorBody = String(data: data, encoding: .utf8) ?? ""
                switch httpResponse.statusCode {
                case 401, 403:
                    lastError = "Cheie API invalid\u{0103}. Verifica\u{021B}i \u{00EE}n Set\u{0103}ri."
                case 429:
                    if errorBody.contains("RESOURCE_EXHAUSTED") || errorBody.contains("RATE_LIMIT_EXCEEDED") {
                        lastError = "Limita API dep\u{0103}\u{0219}it\u{0103}. \u{00CE}ncerca\u{021B}i din nou \u{00EE}n c\u{00E2}teva minute."
                    } else {
                        lastError = "Prea multe cereri (429). Detalii: \(errorBody.prefix(200))"
                    }
                case 500...599:
                    lastError = "Serverul Gemini nu este disponibil."
                default:
                    lastError = "Eroare server: \(httpResponse.statusCode)"
                }
                return nil
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let text = parts.first?["text"] as? String else {
                lastError = "Format de r\u{0103}spuns nea\u{0219}teptat."
                return nil
            }

            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch let error as URLError where error.code == .timedOut {
            lastError = "Conexiunea a expirat. \u{00CE}ncerca\u{021B}i din nou."
            return nil
        } catch let error as URLError where error.code == .notConnectedToInternet {
            lastError = "F\u{0103}r\u{0103} conexiune la internet."
            return nil
        } catch {
            lastError = "Eroare de re\u{021B}ea."
            return nil
        }
    }

    private func extractJSON(from text: String) -> String {
        var cleaned = text
        if cleaned.contains("```json") {
            cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
        }
        if cleaned.contains("```") {
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func sanitize(_ input: String) -> String {
        input
            .replacingOccurrences(of: "\\", with: "")
            .replacingOccurrences(of: "\"", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
