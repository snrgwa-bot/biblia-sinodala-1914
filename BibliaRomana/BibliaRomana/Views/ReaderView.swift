import SwiftUI

struct ReaderView: View {
    @Binding var selectedBook: BibleBook?
    @Binding var selectedChapter: Int
    @Binding var selectedTab: Int
    @Binding var pendingGlowVerseId: String?
    @Binding var pendingSourceTab: Int?

    @EnvironmentObject var bibleService: BibleService
    @EnvironmentObject var storageService: StorageService
    @EnvironmentObject var geminiService: GeminiService
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var annotationVerse: Verse?
    @State private var aiVerse: Verse?
    @State private var showChapterPicker = false
    @State private var noteText = ""
    @State private var returnBook: BibleBook?
    @State private var returnChapter: Int = 0
    @State private var cameFromTab: Int?
    @State private var glowingVerseId: String?
    @State private var glowOpacity: Double = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                chapterNavigationBar

                if bibleService.isLoading {
                    Spacer()
                    ProgressView("Se \u{00EE}ncarc\u{0103}...")
                        .font(.callout)
                    Spacer()
                } else if bibleService.currentVerses.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Selecta\u{021B}i o carte din Bibliotec\u{0103}")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else {
                    versesScrollView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button {
                        showChapterPicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedBook?.name ?? "Citire")
                                .font(.headline)
                            Image(systemName: "chevron.down")
                                .font(.caption2.bold())
                        }
                        .foregroundStyle(verseTextColor)
                    }
                }
            }
            .toolbarBackground(readerBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(storageService.settings.theme == .dark ? .dark : .light, for: .navigationBar)
            .sheet(item: $annotationVerse) { verse in
                AnnotationSheet(
                    verse: verse,
                    bookName: selectedBook?.name ?? "",
                    noteText: storageService.note(for: verse.id) ?? "",
                    onDismiss: { annotationVerse = nil }
                )
                .environmentObject(storageService)
                .environmentObject(SubscriptionService.shared)
            }
            .sheet(item: $aiVerse) { verse in
                VerseAISheet(
                    verse: verse,
                    bookName: selectedBook?.name ?? "",
                    selectedBook: $selectedBook,
                    selectedChapter: $selectedChapter,
                    returnBook: $returnBook,
                    returnChapter: $returnChapter,
                    onDismiss: { aiVerse = nil },
                    onGlowVerse: { verseId in glowVerse(id: verseId) }
                )
                .environmentObject(bibleService)
                .environmentObject(storageService)
                .environmentObject(SubscriptionService.shared)
            }
            .sheet(isPresented: $showChapterPicker) {
                if let book = selectedBook {
                    ReaderChapterPickerSheet(
                        book: book,
                        currentChapter: selectedChapter,
                        onSelectChapter: { chapter in
                            selectedChapter = chapter
                            showChapterPicker = false
                        },
                        onShowAllBooks: {
                            showChapterPicker = false
                            selectedTab = 0
                        }
                    )
                    .presentationDetents(horizontalSizeClass == .regular ? [.fraction(0.5), .large] : [.medium])
                }
            }
            .onChange(of: selectedBook) { _, _ in loadVerses() }
            .onChange(of: selectedChapter) { _, _ in loadVerses() }
            .onChange(of: pendingGlowVerseId) { _, newId in
                guard let verseId = newId else { return }
                pendingGlowVerseId = nil
                if let src = pendingSourceTab {
                    cameFromTab = src
                    pendingSourceTab = nil
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    glowVerse(id: verseId)
                }
            }
            .onAppear { loadVerses() }
        }
    }

    // MARK: - Chapter Navigation

    private var chapterNavigationBar: some View {
        HStack {
            Button {
                if selectedChapter > 1 { selectedChapter -= 1 }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.bold())
                    .frame(width: 44, height: 44)
            }
            .disabled(selectedChapter <= 1)

            Spacer()

            Text("Capitolul \(selectedChapter)")
                .font(.headline)

            Spacer()

            Button {
                if let book = selectedBook, selectedChapter < book.chapters {
                    selectedChapter += 1
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.bold())
                    .frame(width: 44, height: 44)
            }
            .disabled(selectedBook.map { selectedChapter >= $0.chapters } ?? true)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .foregroundStyle(verseTextColor)
        .background(readerBackground)
    }

    // MARK: - Verses

    private var versesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                // Back to source tab banner
                if let sourceTab = cameFromTab {
                    HStack {
                        Button {
                            cameFromTab = nil
                            selectedTab = sourceTab
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.uturn.backward")
                                Text("\u{00CE}napoi la \(tabName(sourceTab))")
                                    .font(.caption.bold())
                            }
                        }
                        Spacer()
                        Button {
                            cameFromTab = nil
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption2)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.purple.opacity(0.15))
                    .foregroundStyle(.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal)
                    .padding(.top, 4)
                }

                // Return to previous verse banner
                if returnChapter > 0, let retBook = returnBook {
                    Button {
                        selectedBook = retBook
                        selectedChapter = returnChapter
                        returnBook = nil
                        returnChapter = 0
                    } label: {
                        HStack {
                            Image(systemName: "arrow.uturn.backward")
                            Text("\u{00CE}napoi la \(retBook.name) \(returnChapter)")
                                .font(.caption.bold())
                            Spacer()
                            Image(systemName: "xmark")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundStyle(.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }

                if horizontalSizeClass == .regular && storageService.settings.twoColumnLayout {
                    let verses = bibleService.currentVerses
                    let mid = verses.count / 2
                    HStack(alignment: .top, spacing: 0) {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(verses.prefix(mid)) { verse in
                                verseRow(verse)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.leading)
                        .padding(.trailing, 8)

                        Divider()

                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(verses.suffix(from: mid)) { verse in
                                verseRow(verse)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.trailing)
                        .padding(.leading, 8)
                    }
                    .padding(.vertical)
                } else {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(bibleService.currentVerses) { verse in
                            verseRow(verse)
                        }
                    }
                    .padding()
                }
            }
            .onChange(of: glowingVerseId) { _, newId in
                if let id = newId {
                    withAnimation { proxy.scrollTo(id, anchor: .center) }
                }
            }
        }
        .background(readerBackground.ignoresSafeArea())
    }

    func glowVerse(id: String) {
        glowingVerseId = id
        // Pulse 3 times
        withAnimation(.easeInOut(duration: 0.4)) { glowOpacity = 0.4 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.3)) { glowOpacity = 0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeInOut(duration: 0.4)) { glowOpacity = 0.4 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeInOut(duration: 0.3)) { glowOpacity = 0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeInOut(duration: 0.4)) { glowOpacity = 0.4 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeInOut(duration: 0.3)) { glowOpacity = 0 }
            glowingVerseId = nil
        }
    }

    @ViewBuilder
    private func verseRow(_ verse: Verse) -> some View {
        let highlightColor = storageService.highlightColor(for: verse.id)
        let hasNote = storageService.note(for: verse.id) != nil
        let isGlowing = glowingVerseId == verse.id

        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(verse.verse)")
                    .font(verseFontSize.weight(.bold))
                    .foregroundStyle(verseNumberColor)

                Text(verse.text)
                    .font(verseFontSize)
                    .foregroundStyle(verseTextColor)
                    .lineSpacing(4)

                if hasNote {
                    Image(systemName: "note.text")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(highlightBackground(highlightColor))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentColor.opacity(isGlowing ? glowOpacity : 0))
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .id(verse.id)
            .contentShape(Rectangle())
            .onTapGesture {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                annotationVerse = verse
            }
            .onLongPressGesture {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                aiVerse = verse
            }

            if let note = storageService.note(for: verse.id) {
                Text(note)
                    .font(.custom("Bradley Hand", size: storageService.settings.fontSize.pointSize - 2))
                    .foregroundStyle(inkSwiftColor(storageService.noteInkColor(for: verse.id)))
                    .padding(.leading, 28)
                    .padding(.bottom, 4)
            }
        }
    }

    private var verseFontSize: Font {
        let size = storageService.settings.fontSize
        switch storageService.settings.fontType {
        case .serif: return .system(size: size.pointSize, design: .serif)
        case .mono: return .system(size: size.pointSize, design: .monospaced)
        case .sans: return .system(size: size.pointSize, design: .default)
        }
    }

    // MARK: - Bright Highlight Colors

    @ViewBuilder
    private func highlightBackground(_ color: Annotation.HighlightColor?) -> some View {
        switch color {
        case .yellow: Color(red: 1.0, green: 0.95, blue: 0.3).opacity(0.55)
        case .lime:   Color(red: 0.4, green: 1.0, blue: 0.2).opacity(0.45)
        case .pink:   Color(red: 1.0, green: 0.4, blue: 0.6).opacity(0.45)
        case .blue:   Color(red: 0.3, green: 0.7, blue: 1.0).opacity(0.45)
        case .orange: Color(red: 1.0, green: 0.65, blue: 0.2).opacity(0.5)
        case .none:   Color.clear
        }
    }

    static func markerColor(for color: Annotation.HighlightColor) -> Color {
        switch color {
        case .yellow: return Color(red: 1.0, green: 0.92, blue: 0.15)
        case .lime:   return Color(red: 0.35, green: 0.95, blue: 0.15)
        case .pink:   return Color(red: 1.0, green: 0.35, blue: 0.55)
        case .blue:   return Color(red: 0.25, green: 0.65, blue: 1.0)
        case .orange: return Color(red: 1.0, green: 0.6, blue: 0.1)
        }
    }

    // MARK: - Theme Colors

    private var verseTextColor: Color {
        switch storageService.settings.theme {
        case .light, .system: return .black
        case .dark: return Color(red: 0.92, green: 0.92, blue: 0.96)
        }
    }

    private var verseNumberColor: Color {
        switch storageService.settings.theme {
        case .light, .system: return .black
        case .dark: return Color(red: 0.75, green: 0.82, blue: 1.0)
        }
    }

    private var noteColor: Color {
        switch storageService.settings.theme {
        case .light, .system: return .secondary
        case .dark: return Color(red: 0.7, green: 0.7, blue: 0.75)
        }
    }

    private var readerBackground: Color {
        switch storageService.settings.theme {
        case .light, .system: return .white
        case .dark: return .black
        }
    }

    private func loadVerses() {
        guard let book = selectedBook else { return }
        storageService.saveReadingPosition(bookId: book.id, chapter: selectedChapter)
        storageService.markChapterVisited(bookId: book.id, chapter: selectedChapter)
        bibleService.fetchVerses(bookName: book.name, chapter: selectedChapter)
    }

    private func inkSwiftColor(_ ink: Annotation.NoteInkColor?) -> Color {
        switch ink {
        case .blue: return Color(red: 0.1, green: 0.2, blue: 0.7)
        case .red: return Color(red: 0.7, green: 0.1, blue: 0.1)
        case .gray: return Color.gray
        case .none: return noteColor
        }
    }

    private func tabName(_ tab: Int) -> String {
        switch tab {
        case 0: return "Bibliotec\u{0103}"
        case 2: return "Vizualizare"
        case 3: return "Enciclopedie"
        case 4: return "Set\u{0103}ri"
        default: return "Citire"
        }
    }
}

// MARK: - Annotation Sheet (Short Tap)

struct AnnotationSheet: View {
    let verse: Verse
    let bookName: String
    let noteText: String
    let onDismiss: () -> Void

    @EnvironmentObject var storageService: StorageService
    @EnvironmentObject var subscriptionService: SubscriptionService
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var editedNote: String = ""
    @State private var explanation: String?
    @State private var isLoadingExplanation = false
    @State private var explanationError: String?
    @State private var explanationSaved = false
    @State private var selectedInk: Annotation.NoteInkColor?
    @State private var showPaywall = false

    private var isAIConfigured: Bool { GeminiService.shared.isConfigured }

    private var shareText: String {
        "\u{201E}\(verse.text.trimmingCharacters(in: .whitespacesAndNewlines))\u{201D}\n\u{2014} \(bookName) \(verse.chapter):\(verse.verse)\n\nBiblia Sinodal\u{0103} 1914"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Verse text
                    Text("\(verse.verse). \(verse.text)")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Highlight colors
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Eviden\u{021B}iere")
                            .font(.subheadline.bold())

                        HStack(spacing: 12) {
                            ForEach(Annotation.HighlightColor.allCases, id: \.self) { color in
                                Button {
                                    storageService.addHighlight(verseId: verse.id, color: color)
                                } label: {
                                    Circle()
                                        .fill(ReaderView.markerColor(for: color))
                                        .frame(width: 36, height: 36)
                                        .overlay {
                                            if storageService.highlightColor(for: verse.id) == color {
                                                Image(systemName: "checkmark")
                                                    .font(.caption.bold())
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        .shadow(color: ReaderView.markerColor(for: color).opacity(0.5), radius: 3)
                                }
                            }

                            Button {
                                storageService.removeAnnotation(verseId: verse.id, type: .highlight)
                            } label: {
                                Circle()
                                    .strokeBorder(Color.secondary, lineWidth: 1)
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        Image(systemName: "xmark")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                            }
                        }
                    }
                    .padding(.horizontal)

                    Divider()

                    // AI Explain verse
                    VStack(alignment: .leading, spacing: 8) {
                        if isLoadingExplanation {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Se genereaz\u{0103} explica\u{021B}ia...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                        } else if let text = explanation {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(text)
                                    .font(.callout)

                                Button {
                                    let prefix = editedNote.isEmpty ? "" : editedNote + "\n\n"
                                    editedNote = prefix + "\u{2728} AI: " + text
                                    explanationSaved = true
                                } label: {
                                    Label(
                                        explanationSaved ? "Salvat \u{00EE}n not\u{0103}" : "Salveaz\u{0103} \u{00EE}n not\u{0103}",
                                        systemImage: explanationSaved ? "checkmark.circle.fill" : "square.and.arrow.down"
                                    )
                                    .font(.caption.bold())
                                }
                                .tint(explanationSaved ? .green : Color(red: 0.4, green: 0.3, blue: 0.2))
                                .disabled(explanationSaved)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal)
                        } else if let error = explanationError {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundStyle(.red)
                                    Text("Eroare")
                                        .font(.subheadline.bold())
                                }
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Button {
                                    explanationError = nil
                                } label: {
                                    Text("\u{00CE}ncearc\u{0103} din nou")
                                        .font(.caption)
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal)
                        } else if isAIConfigured {
                            Button {
                                if subscriptionService.isSubscribed {
                                    isLoadingExplanation = true
                                    explanationError = nil
                                    let ref = "\(bookName) \(verse.chapter):\(verse.verse)"
                                    Task {
                                        let result = await GeminiService.shared.getVerseExplanation(
                                            verseText: verse.text,
                                            verseRef: ref
                                        )
                                        if let result {
                                            explanation = result
                                        } else {
                                            explanationError = GeminiService.shared.lastError ?? "R\u{0103}spuns gol de la AI."
                                        }
                                        isLoadingExplanation = false
                                    }
                                } else {
                                    showPaywall = true
                                }
                            } label: {
                                Label("Explic\u{0103} versetul", systemImage: "sparkles")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(red: 0.4, green: 0.3, blue: 0.2))
                            .padding(.horizontal)
                        }
                    }

                    Divider()

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Not\u{0103}")
                                .font(.subheadline.bold())
                            Spacer()
                            // Ink color picker
                            HStack(spacing: 8) {
                                inkButton(nil, label: "Cerneala", systemColor: .secondary)
                                inkButton(.blue, label: "Albastru", systemColor: Color(red: 0.1, green: 0.2, blue: 0.7))
                                inkButton(.red, label: "Ro\u{0219}u", systemColor: Color(red: 0.7, green: 0.1, blue: 0.1))
                                inkButton(.gray, label: "Gri", systemColor: .gray)
                            }
                        }

                        TextEditor(text: $editedNote)
                            .frame(height: 70)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        HStack {
                            Button("Salveaz\u{0103}") {
                                let trimmed = editedNote.trimmingCharacters(in: .whitespacesAndNewlines)
                                if trimmed.isEmpty {
                                    storageService.removeAnnotation(verseId: verse.id, type: .note)
                                } else {
                                    storageService.addNote(verseId: verse.id, content: editedNote, inkColor: selectedInk)
                                }
                                onDismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(red: 0.4, green: 0.3, blue: 0.2))

                            if storageService.note(for: verse.id) != nil {
                                Button("\u{0218}terge", role: .destructive) {
                                    storageService.removeAnnotation(verseId: verse.id, type: .note)
                                    editedNote = ""
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .padding(.horizontal)

                }
                .padding(.bottom)
            }
            .navigationTitle("\(bookName) \(verse.chapter):\(verse.verse)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Gata") { onDismiss() }
                }
            }
        }
        .presentationDetents(horizontalSizeClass == .regular ? [.large] : [.medium, .large])
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscriptionService)
        }
        .onAppear {
            editedNote = noteText
            selectedInk = storageService.noteInkColor(for: verse.id)
        }
    }

    @ViewBuilder
    private func inkButton(_ ink: Annotation.NoteInkColor?, label: String, systemColor: Color) -> some View {
        Button {
            selectedInk = ink
        } label: {
            Circle()
                .fill(systemColor)
                .frame(width: 20, height: 20)
                .overlay {
                    if selectedInk == ink {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
        }
    }
}

// MARK: - Verse AI Sheet (Long Press)

struct VerseAISheet: View {
    let verse: Verse
    let bookName: String
    @Binding var selectedBook: BibleBook?
    @Binding var selectedChapter: Int
    @Binding var returnBook: BibleBook?
    @Binding var returnChapter: Int
    let onDismiss: () -> Void
    var onGlowVerse: ((String) -> Void)?

    @EnvironmentObject var bibleService: BibleService
    @EnvironmentObject var storageService: StorageService
    @EnvironmentObject var subscriptionService: SubscriptionService
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var explanation: String?
    @State private var isLoading = false
    @State private var searchWord = ""
    @State private var bibleMentions: [BibleService.SearchResult] = []
    @State private var errorMessage: String?
    @State private var explanationSaved = false
    @State private var showPaywall = false

    private var isAIConfigured: Bool { GeminiService.shared.isConfigured }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Full verse text (selectable)
                    Text("\(verse.verse). \(verse.text)")
                        .font(.body)
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Word chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(uniqueWords(from: verse.text), id: \.self) { word in
                                let hasEncMatch = EncyclopediaService.shared.lookup(word: word) != nil
                                Button {
                                    searchWord = word
                                    performSearch()
                                } label: {
                                    Text(word)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(hasEncMatch ? Color.orange.opacity(0.15) : Color(.systemGray6))
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule().strokeBorder(
                                                hasEncMatch ? Color.orange.opacity(0.5) : Color.clear,
                                                lineWidth: 1
                                            )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Explain full verse button
                    if isLoading {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Se genereaz\u{0103} explica\u{021B}ia...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    } else if let text = explanation {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(.orange)
                                Text("Explica\u{021B}ie AI")
                                    .font(.subheadline.bold())
                            }
                            Text(text)
                                .font(.callout)

                            Button {
                                let existing = storageService.note(for: verse.id) ?? ""
                                let prefix = existing.isEmpty ? "" : existing + "\n\n"
                                storageService.addNote(verseId: verse.id, content: prefix + "\u{2728} AI: " + text)
                                explanationSaved = true
                            } label: {
                                Label(
                                    explanationSaved ? "Salvat \u{00EE}n not\u{0103}" : "Salveaz\u{0103} \u{00EE}n not\u{0103}",
                                    systemImage: explanationSaved ? "checkmark.circle.fill" : "square.and.arrow.down"
                                )
                                .font(.caption.bold())
                            }
                            .tint(explanationSaved ? .green : Color(red: 0.4, green: 0.3, blue: 0.2))
                            .disabled(explanationSaved)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                    } else if let error = errorMessage {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(.red)
                                Text("Eroare")
                                    .font(.subheadline.bold())
                            }
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button {
                                errorMessage = nil
                            } label: {
                                Text("\u{00CE}ncearc\u{0103} din nou")
                                    .font(.caption)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                    } else if isAIConfigured {
                        Button {
                            if subscriptionService.isSubscribed {
                                isLoading = true
                                errorMessage = nil
                                let ref = "\(bookName) \(verse.chapter):\(verse.verse)"
                                Task {
                                    let result = await GeminiService.shared.getVerseExplanation(
                                        verseText: verse.text,
                                        verseRef: ref
                                    )
                                    if let result {
                                        explanation = result
                                    } else {
                                        errorMessage = GeminiService.shared.lastError ?? "R\u{0103}spuns gol de la AI."
                                    }
                                    isLoading = false
                                }
                            } else {
                                showPaywall = true
                            }
                        } label: {
                            Label("Explic\u{0103} versetul cu AI", systemImage: "sparkles")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 0.4, green: 0.3, blue: 0.2))
                        .padding(.horizontal)
                    }

                    Divider()

                    // Search word in Bible
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Caut\u{0103} \u{00EE}n Biblie")
                            .font(.subheadline.bold())
                            .padding(.horizontal)

                        HStack {
                            TextField("Scrie un cuv\u{00E2}nt...", text: $searchWord)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .onSubmit { performSearch() }

                            Button { performSearch() } label: {
                                Image(systemName: "magnifyingglass")
                                    .frame(width: 44, height: 44)
                            }
                            .disabled(searchWord.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(.horizontal)

                        if !bibleMentions.isEmpty {
                            Text("\(bibleMentions.count) versete g\u{0103}site")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)

                            ForEach(bibleMentions) { result in
                                Button {
                                    navigateToMention(result)
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(result.reference)
                                                .font(.caption.bold())
                                                .foregroundStyle(.accent)
                                            Spacer()
                                            Image(systemName: "arrow.right.circle")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Text(result.text)
                                            .font(.caption)
                                            .foregroundStyle(.primary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                    }
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                            }
                        } else if errorMessage != nil {
                            Text("Nu s-au g\u{0103}sit rezultate.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("\(bookName) \(verse.chapter):\(verse.verse)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Gata") { onDismiss() }
                }
            }
        }
        .presentationDetents(horizontalSizeClass == .regular ? [.large] : [.medium, .large])
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscriptionService)
        }
    }

    private func performSearch() {
        let query = searchWord.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }
        let results = bibleService.searchVerses(containing: query)
        bibleMentions = results.filter {
            $0.bookName != verse.bookName || $0.chapter != verse.chapter || $0.verse != verse.verse
        }
        errorMessage = bibleMentions.isEmpty ? "empty" : nil
    }

    private func uniqueWords(from text: String) -> [String] {
        let cleaned = text.replacingOccurrences(of: "[.,;:!?\"'()\\[\\]]", with: "", options: .regularExpression)
        let words = cleaned.components(separatedBy: .whitespaces).filter { $0.count >= 3 }
        var seen = Set<String>()
        return words.filter { word in
            let lowered = word.lowercased()
            guard !seen.contains(lowered) else { return false }
            seen.insert(lowered)
            return true
        }
    }

    private func navigateToMention(_ result: BibleService.SearchResult) {
        guard let book = bibleService.bibleBooks.first(where: { $0.name == result.bookName }) else { return }
        returnBook = selectedBook
        returnChapter = selectedChapter
        let targetVerseId = "\(book.id)_\(result.chapter)_\(result.verse)"
        onDismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            selectedBook = book
            selectedChapter = result.chapter
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onGlowVerse?(targetVerseId)
            }
        }
    }
}

// MARK: - Reader Chapter Picker Sheet

struct ReaderChapterPickerSheet: View {
    let book: BibleBook
    let currentChapter: Int
    let onSelectChapter: (Int) -> Void
    let onShowAllBooks: () -> Void
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(1...book.chapters, id: \.self) { chapter in
                        Button {
                            onSelectChapter(chapter)
                        } label: {
                            Text("\(chapter)")
                                .font(.body.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(chapter == currentChapter ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(chapter == currentChapter ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle(book.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuleaz\u{0103}") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onShowAllBooks()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "books.vertical")
                                .font(.caption)
                            Text("Toate c\u{0103}r\u{021B}ile")
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
    }
}
