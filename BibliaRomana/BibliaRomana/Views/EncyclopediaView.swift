import SwiftUI

// MARK: - Encyclopedia View

struct EncyclopediaView: View {
    @Binding var selectedBook: BibleBook?
    @Binding var selectedChapter: Int
    @Binding var selectedTab: Int
    @Binding var pendingGlowVerseId: String?
    @Binding var pendingSourceTab: Int?

    @EnvironmentObject var encyclopediaService: EncyclopediaService
    @EnvironmentObject var bibleService: BibleService

    @State private var searchText = ""
    @State private var selectedCategory: EncyclopediaEntry.EntryCategory?
    @State private var showMap = false

    private var filteredEntries: [EncyclopediaEntry] {
        var results: [EncyclopediaEntry]
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            results = encyclopediaService.search(query: searchText)
        } else {
            results = encyclopediaService.entries
        }
        if let cat = selectedCategory {
            results = results.filter { $0.category == cat }
        }
        return results
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        categoryPill(nil, label: "Toate", icon: "list.bullet")
                        ForEach(EncyclopediaEntry.EntryCategory.allCases, id: \.self) { cat in
                            categoryPill(cat, label: cat.displayName, icon: cat.icon)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                List(filteredEntries) { entry in
                    NavigationLink(value: entry) {
                        HStack(spacing: 12) {
                            Image(systemName: entry.category.icon)
                                .font(.title3)
                                .foregroundStyle(categoryColor(entry.category))
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.name)
                                    .font(.body.weight(.medium))

                                Text(entry.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Enciclopedie")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Caut\u{0103} persoane, locuri, evenimente...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showMap = true
                    } label: {
                        Image(systemName: "map")
                    }
                }
            }
            .navigationDestination(for: EncyclopediaEntry.self) { entry in
                EncyclopediaDetailView(
                    entry: entry,
                    selectedBook: $selectedBook,
                    selectedChapter: $selectedChapter,
                    selectedTab: $selectedTab,
                    pendingGlowVerseId: $pendingGlowVerseId,
                    pendingSourceTab: $pendingSourceTab
                )
            }
            .sheet(isPresented: $showMap) {
                NavigationStack {
                    BiblicalMapView(
                        selectedBook: $selectedBook,
                        selectedChapter: $selectedChapter,
                        selectedTab: $selectedTab
                    )
                    .navigationTitle("Harta Biblic\u{0103}")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Gata") { showMap = false }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func categoryPill(_ category: EncyclopediaEntry.EntryCategory?, label: String, icon: String) -> some View {
        let isSelected = selectedCategory == category
        Button {
            selectedCategory = category
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color(red: 0.4, green: 0.3, blue: 0.2) : Color(.systemGray6))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func categoryColor(_ category: EncyclopediaEntry.EntryCategory) -> Color {
        switch category {
        case .person: return .blue
        case .place: return .green
        case .event: return .orange
        case .concept: return .purple
        case .object: return .brown
        }
    }
}

// MARK: - Encyclopedia Detail View

struct EncyclopediaDetailView: View {
    let entry: EncyclopediaEntry
    @Binding var selectedBook: BibleBook?
    @Binding var selectedChapter: Int
    @Binding var selectedTab: Int
    @Binding var pendingGlowVerseId: String?
    @Binding var pendingSourceTab: Int?

    @EnvironmentObject var encyclopediaService: EncyclopediaService
    @EnvironmentObject var bibleService: BibleService
    @EnvironmentObject var subscriptionService: SubscriptionService

    @State private var aiExplanation: String?
    @State private var isLoadingAI = false
    @State private var showFullMap = false
    @State private var showPaywall = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: entry.category.icon)
                        .font(.title)
                        .foregroundStyle(categoryColor(entry.category))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.name)
                            .font(.title.bold())
                        HStack(spacing: 8) {
                            Text(entry.category.displayName)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(categoryColor(entry.category).opacity(0.15))
                                .clipShape(Capsule())
                            if let timeline = entry.timeline {
                                Text(timeline)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Aliases
                if !entry.aliases.isEmpty {
                    HStack(spacing: 6) {
                        Text("Alte denumiri:")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(entry.aliases.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }

                Divider()

                // Description
                VStack(alignment: .leading, spacing: 4) {
                    Text("Descriere")
                        .font(.subheadline.bold())
                    Text(entry.description)
                        .font(.body)
                }
                .padding(.horizontal)

                // Significance
                VStack(alignment: .leading, spacing: 4) {
                    Text("Semnifica\u{021B}ie")
                        .font(.subheadline.bold())
                    Text(entry.significance)
                        .font(.body)
                }
                .padding(.horizontal)

                // Map preview for places
                if let coords = entry.coordinates {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Loca\u{021B}ie")
                                .font(.subheadline.bold())
                            Spacer()
                            Button {
                                showFullMap = true
                            } label: {
                                Label("Hart\u{0103} complet\u{0103}", systemImage: "arrow.up.left.and.arrow.down.right")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal)

                        BiblicalMapView(
                            filterLocationId: entry.id,
                            selectedBook: $selectedBook,
                            selectedChapter: $selectedChapter,
                            selectedTab: $selectedTab,
                            initialLatitude: coords.latitude,
                            initialLongitude: coords.longitude,
                            initialSpan: 2.0
                        )
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                }

                // Related Verses
                if !entry.relatedVerses.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Versete biblice")
                            .font(.subheadline.bold())

                        ForEach(entry.relatedVerses, id: \.self) { ref in
                            Button {
                                navigateToVerse(ref)
                            } label: {
                                HStack {
                                    Image(systemName: "book.fill")
                                        .font(.caption)
                                        .foregroundStyle(.accent)
                                    Text(ref.display)
                                        .font(.callout)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.right.circle")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(8)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }

                // Related Entries
                if !entry.relatedEntries.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Articole \u{00EE}nrudite")
                            .font(.subheadline.bold())

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(entry.relatedEntries, id: \.self) { entryId in
                                    if let related = encyclopediaService.entry(byId: entryId) {
                                        NavigationLink(value: related) {
                                            HStack(spacing: 4) {
                                                Image(systemName: related.category.icon)
                                                    .font(.caption2)
                                                Text(related.name)
                                                    .font(.caption.weight(.medium))
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color(.systemGray6))
                                            .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // AI Deep Dive
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    if isLoadingAI {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Se genereaz\u{0103}...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    } else if let text = aiExplanation {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(.orange)
                                Text("Aprofundare AI")
                                    .font(.subheadline.bold())
                                Spacer()
                                Text("AI")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                            Text(text)
                                .font(.callout)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                    } else if GeminiService.shared.isConfigured {
                        Button {
                            if subscriptionService.isSubscribed {
                                loadAIExplanation()
                            } else {
                                showPaywall = true
                            }
                        } label: {
                            Label("Aprofundeaz\u{0103} cu AI", systemImage: "sparkles")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 0.4, green: 0.3, blue: 0.2))
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(entry.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if aiExplanation == nil {
                aiExplanation = EncyclopediaAICache.shared.get(entryId: entry.id)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscriptionService)
        }
        .fullScreenCover(isPresented: $showFullMap) {
            if let coords = entry.coordinates {
                NavigationStack {
                    BiblicalMapView(
                        filterLocationId: entry.id,
                        selectedBook: $selectedBook,
                        selectedChapter: $selectedChapter,
                        selectedTab: $selectedTab,
                        initialLatitude: coords.latitude,
                        initialLongitude: coords.longitude,
                        initialSpan: 4.0
                    )
                    .navigationTitle(entry.name)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("\u{00CE}nchide") { showFullMap = false }
                        }
                    }
                }
            }
        }
    }

    private func loadAIExplanation() {
        isLoadingAI = true
        Task {
            let result = await GeminiService.shared.getEncyclopediaDetails(
                name: entry.name,
                category: entry.category.displayName,
                description: entry.description
            )
            aiExplanation = result
            if let text = result {
                EncyclopediaAICache.shared.save(entryId: entry.id, text: text)
            }
            isLoadingAI = false
        }
    }

    private func navigateToVerse(_ ref: VerseReference) {
        guard let book = bibleService.bibleBooks.first(where: { $0.name == ref.book }) else { return }
        let verseId = "\(book.id)_\(ref.chapter)_\(ref.verse)"
        pendingSourceTab = 3
        selectedBook = book
        selectedChapter = ref.chapter
        selectedTab = 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            pendingGlowVerseId = verseId
        }
    }

    private func categoryColor(_ category: EncyclopediaEntry.EntryCategory) -> Color {
        switch category {
        case .person: return .blue
        case .place: return .green
        case .event: return .orange
        case .concept: return .purple
        case .object: return .brown
        }
    }
}
