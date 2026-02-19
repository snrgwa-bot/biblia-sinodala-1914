import SwiftUI

struct ContentView: View {
    @StateObject private var bibleService = BibleService.shared
    @StateObject private var storageService = StorageService.shared
    @StateObject private var geminiService = GeminiService.shared
    @StateObject private var encyclopediaService = EncyclopediaService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared

    @State private var selectedTab = 1
    @State private var selectedBook: BibleBook?
    @State private var selectedChapter = 1
    @State private var pendingGlowVerseId: String?
    @State private var pendingSourceTab: Int?

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView(
                selectedBook: $selectedBook,
                selectedChapter: $selectedChapter,
                selectedTab: $selectedTab
            )
            .tabItem {
                Label("Bibliotec\u{0103}", systemImage: "books.vertical")
            }
            .tag(0)

            ReaderView(
                selectedBook: $selectedBook,
                selectedChapter: $selectedChapter,
                selectedTab: $selectedTab,
                pendingGlowVerseId: $pendingGlowVerseId,
                pendingSourceTab: $pendingSourceTab
            )
            .tabItem {
                Label("Citire", systemImage: "book")
            }
            .tag(1)

            VisualizerView(
                selectedBook: $selectedBook,
                selectedChapter: $selectedChapter,
                selectedTab: $selectedTab,
                pendingGlowVerseId: $pendingGlowVerseId,
                pendingSourceTab: $pendingSourceTab
            )
            .tabItem {
                Label("Vizualizare", systemImage: "chart.bar.xaxis")
            }
            .tag(2)

            EncyclopediaView(
                selectedBook: $selectedBook,
                selectedChapter: $selectedChapter,
                selectedTab: $selectedTab,
                pendingGlowVerseId: $pendingGlowVerseId,
                pendingSourceTab: $pendingSourceTab
            )
            .tabItem {
                Label("Enciclopedie", systemImage: "text.book.closed")
            }
            .tag(3)

            SettingsView(
                selectedBook: $selectedBook,
                selectedChapter: $selectedChapter,
                selectedTab: $selectedTab
            )
            .tabItem {
                Label("Set\u{0103}ri", systemImage: "gearshape")
            }
            .tag(4)
        }
        .tint(Color(red: 0.4, green: 0.3, blue: 0.2))
        .environmentObject(bibleService)
        .environmentObject(storageService)
        .environmentObject(geminiService)
        .environmentObject(encyclopediaService)
        .environmentObject(subscriptionService)
        .onAppear {
            loadLastPosition()
            configureTabBarAppearance()
        }
    }

    private func loadLastPosition() {
        if let position = storageService.lastReadingPosition(),
           let book = bibleService.bibleBooks.first(where: { $0.id == position.bookId }) {
            selectedBook = book
            selectedChapter = position.chapter
        } else {
            selectedBook = bibleService.bibleBooks.first
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
