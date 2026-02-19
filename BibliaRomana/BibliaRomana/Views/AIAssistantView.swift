import SwiftUI

struct AIAssistantView: View {
    @EnvironmentObject var geminiService: GeminiService
    @EnvironmentObject var bibleService: BibleService
    @EnvironmentObject var storageService: StorageService
    @EnvironmentObject var subscriptionService: SubscriptionService

    @State private var wordInput = ""
    @State private var showPaywall = false
    @State private var dictionaryResult: DictionaryEntry?
    @State private var summaryResult: String?
    @State private var perspectives: [Perspective] = []
    @State private var selectedFeature: AIFeature = .dictionary
    @State private var verseRefInput = ""

    enum AIFeature: String, CaseIterable {
        case dictionary = "Dicționar"
        case summary = "Rezumat"
        case perspectives = "Perspective"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !geminiService.isConfigured {
                    apiKeyPrompt
                } else {
                    featureContent
                }

                if let error = geminiService.lastError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("Asistent AI")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(subscriptionService)
            }
        }
    }

    // MARK: - API Key Prompt

    private var apiKeyPrompt: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "key")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Configurați cheia API Gemini")
                .font(.headline)

            Text("Mergeți la Setări și introduceți cheia API Gemini pentru a activa funcțiile AI.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Feature Content

    private var featureContent: some View {
        VStack(spacing: 0) {
            // Feature picker
            Picker("Funcție", selection: $selectedFeature) {
                ForEach(AIFeature.allCases, id: \.self) { feature in
                    Text(feature.rawValue).tag(feature)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            ScrollView {
                VStack(spacing: 16) {
                    switch selectedFeature {
                    case .dictionary:
                        dictionaryView
                    case .summary:
                        summaryView
                    case .perspectives:
                        perspectivesView
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Dictionary

    private var dictionaryView: some View {
        VStack(spacing: 16) {
            HStack {
                TextField("Introduceți un cuvânt biblic...", text: $wordInput)
                    .textFieldStyle(.roundedBorder)

                Button {
                    if subscriptionService.isSubscribed {
                        Task { await performWordSearch() }
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .frame(width: 44, height: 44)
                }
                .disabled(wordInput.isEmpty || geminiService.isLoading)
            }

            if geminiService.isLoading {
                ProgressView("Se caută...")
            }

            if let result = dictionaryResult {
                VStack(alignment: .leading, spacing: 12) {
                    Text(result.word)
                        .font(.title2.bold())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Definiție")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(result.definition)
                            .font(.body)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Context Biblic")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(result.biblicalContext)
                            .font(.body)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Summary

    private var summaryView: some View {
        VStack(spacing: 16) {
            if bibleService.currentVerses.isEmpty {
                Text("Deschideți un capitol pentru a obține un rezumat.")
                    .foregroundStyle(.secondary)
            } else {
                let currentRef = "\(bibleService.currentVerses.first?.bookName ?? "") \(bibleService.currentVerses.first?.chapter ?? 0)"

                Text("Capitol curent: \(currentRef)")
                    .font(.headline)

                Button {
                    if subscriptionService.isSubscribed {
                        Task { await getSummary() }
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Label("Obține Rezumat", systemImage: "text.justify.left")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.4, green: 0.3, blue: 0.2))
                .disabled(geminiService.isLoading)

                if geminiService.isLoading {
                    ProgressView("Se generează...")
                }

                if let summary = summaryResult {
                    Text(summary)
                        .font(.body)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Perspectives

    private var perspectivesView: some View {
        VStack(spacing: 16) {
            HStack {
                TextField("Ex: Ioan 3:16 sau un eveniment...", text: $verseRefInput)
                    .textFieldStyle(.roundedBorder)

                Button {
                    if subscriptionService.isSubscribed {
                        Task { await getPerspectives() }
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Image(systemName: "person.3")
                        .frame(width: 44, height: 44)
                }
                .disabled(verseRefInput.isEmpty || geminiService.isLoading)
            }

            if geminiService.isLoading {
                ProgressView("Se generează perspective...")
            }

            ForEach(perspectives) { perspective in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(.blue)
                        Text(perspective.character)
                            .font(.headline)
                    }
                    Text(perspective.insight)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Actions

    @MainActor
    private func performWordSearch() async {
        dictionaryResult = await geminiService.getWordDefinition(word: wordInput)
    }

    @MainActor
    private func getSummary() async {
        let text = bibleService.currentVerses.map { $0.text }.joined(separator: " ")
        summaryResult = await geminiService.getVerseSummary(verseText: String(text.prefix(500)))
    }

    @MainActor
    private func getPerspectives() async {
        perspectives = await geminiService.getEventPerspectives(verseRef: verseRefInput)
    }
}
