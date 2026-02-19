import SwiftUI

struct SettingsView: View {
    @Binding var selectedBook: BibleBook?
    @Binding var selectedChapter: Int
    @Binding var selectedTab: Int

    @EnvironmentObject var storageService: StorageService
    @EnvironmentObject var bibleService: BibleService
    @EnvironmentObject var subscriptionService: SubscriptionService

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var showHighlightsList = false
    @State private var showNotesList = false
    @State private var showPaywall = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Appearance
                Section("Aspect") {
                    Picker("Tem\u{0103}", selection: $storageService.settings.theme) {
                        ForEach(ThemeMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }

                    Picker("Dimensiune font", selection: $storageService.settings.fontSize) {
                        ForEach(FontSizeOption.allCases, id: \.self) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }

                    Picker("Tip font", selection: $storageService.settings.fontType) {
                        ForEach(FontType.allCases, id: \.self) { font in
                            Text(font.rawValue).tag(font)
                        }
                    }

                    if horizontalSizeClass == .regular {
                        Toggle("Dou\u{0103} coloane (iPad)", isOn: $storageService.settings.twoColumnLayout)
                    }

                    // Preview
                    Text("Previzualizare text biblic")
                        .font(previewFont)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                }

                // MARK: - Gemini AI
                Section {
                    SecureField("Cheie API Gemini", text: $storageService.settings.geminiApiKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Gemini AI")
                } footer: {
                    Text("Cheia API este necesar\u{0103} pentru func\u{021B}iile Dic\u{021B}ionar, Rezumat \u{0219}i Perspective. Ob\u{021B}ine\u{021B}i una de pe ai.google.dev.")
                }

                // MARK: - AI Subscription
                Section {
                    if subscriptionService.isSubscribed {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                            Text("Stare")
                            Spacer()
                            Text("Activ")
                                .foregroundStyle(.green)
                        }

                        Button {
                            Task { await subscriptionService.manageSubscription() }
                        } label: {
                            HStack {
                                Image(systemName: "gear")
                                    .foregroundStyle(Color(red: 0.4, green: 0.3, blue: 0.2))
                                Text("Gestioneaz\u{0103} abonamentul")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            VStack(spacing: 12) {
                                HStack(spacing: 10) {
                                    Image(systemName: "sparkles")
                                        .font(.title2)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.orange, Color(red: 0.4, green: 0.3, blue: 0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Upgrade la Premium")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text("Explica\u{021B}ii AI, dic\u{021B}ionar, rezumate, vizualizare")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Text("\u{00CE}ncepe cu 3 zile gratuit")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color(red: 0.4, green: 0.3, blue: 0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        Task { await subscriptionService.restorePurchases() }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(Color(red: 0.4, green: 0.3, blue: 0.2))
                            Text("Restaureaz\u{0103} achizi\u{021B}iile")
                                .foregroundStyle(.primary)
                        }
                    }

                    if let error = subscriptionService.purchaseError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Abonament AI")
                } footer: {
                    Text("Abonamentul deblocheaz\u{0103} explica\u{021B}ii AI, rezumate, perspective \u{0219}i vizualizare avansat\u{0103}.")
                }

                // MARK: - Map
                Section {
                    Toggle("Hart\u{0103} static\u{0103}", isOn: $storageService.settings.preferStaticMap)
                } header: {
                    Text("Hart\u{0103}")
                } footer: {
                    Text("Folosi\u{021B}i harta static\u{0103} ilustrat\u{0103} \u{00EE}n loc de Apple Maps.")
                }

                // MARK: - Source
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(BibleService.sourceAttribution)
                            .font(.subheadline)
                        Text(BibleService.sourceLicense)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let url = URL(string: BibleService.sourceURL) {
                            Link(destination: url) {
                                HStack {
                                    Image(systemName: "link")
                                        .font(.caption)
                                    Text("archive.org")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Sursa Bibliei")
                }

                // MARK: - Annotations Stats
                Section("Adnot\u{0103}ri") {
                    let highlightCount = storageService.annotations.filter { $0.type == .highlight }.count
                    let noteCount = storageService.annotations.filter { $0.type == .note }.count

                    Button {
                        showHighlightsList = true
                    } label: {
                        HStack {
                            Image(systemName: "highlighter")
                                .foregroundStyle(.yellow)
                            Text("Eviden\u{021B}ieri")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(highlightCount)")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(highlightCount == 0)

                    Button {
                        showNotesList = true
                    } label: {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundStyle(.orange)
                            Text("Note")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(noteCount)")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(noteCount == 0)
                }

                // MARK: - Dev Tools
                #if DEBUG
                Section {
                    Toggle("Premium activat (DEV)", isOn: Binding(
                        get: { subscriptionService.isDevOverrideEnabled },
                        set: { subscriptionService.isDevOverrideEnabled = $0 }
                    ))
                } header: {
                    Text("Dezvoltator")
                } footer: {
                    Text("Toggle pentru testare. Se elimina inainte de publicare.")
                }
                #endif

                // MARK: - About
                Section("Despre") {
                    HStack {
                        Text("Versiune")
                        Spacer()
                        Text("2.1.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Aplica\u{021B}ie")
                        Spacer()
                        Text("Biblia Sinodal\u{0103} 1914")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Edi\u{021B}ie")
                        Spacer()
                        Text("Sinodal\u{0103} 1914")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Set\u{0103}ri")
            .onChange(of: storageService.settings) { _, _ in storageService.saveSettings() }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(subscriptionService)
            }
            .sheet(isPresented: $showHighlightsList) {
                AnnotationListView(
                    annotationType: .highlight,
                    selectedBook: $selectedBook,
                    selectedChapter: $selectedChapter,
                    selectedTab: $selectedTab,
                    showSheet: $showHighlightsList
                )
                .environmentObject(storageService)
                .environmentObject(bibleService)
            }
            .sheet(isPresented: $showNotesList) {
                AnnotationListView(
                    annotationType: .note,
                    selectedBook: $selectedBook,
                    selectedChapter: $selectedChapter,
                    selectedTab: $selectedTab,
                    showSheet: $showNotesList
                )
                .environmentObject(storageService)
                .environmentObject(bibleService)
            }
        }
    }

    private var previewFont: Font {
        let size = storageService.settings.fontSize
        switch storageService.settings.fontType {
        case .serif:
            return .system(size: size.pointSize, design: .serif)
        case .mono:
            return .system(size: size.pointSize, design: .monospaced)
        case .sans:
            return .system(size: size.pointSize, design: .default)
        }
    }
}

// MARK: - Annotation List View

struct AnnotationListView: View {
    let annotationType: Annotation.AnnotationType
    @Binding var selectedBook: BibleBook?
    @Binding var selectedChapter: Int
    @Binding var selectedTab: Int
    @Binding var showSheet: Bool

    @EnvironmentObject var storageService: StorageService
    @EnvironmentObject var bibleService: BibleService
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredAnnotations: [Annotation] {
        let typed = storageService.annotations.filter { $0.type == annotationType }
        if searchText.isEmpty { return typed }
        return typed.filter { ann in
            ann.verseId.localizedCaseInsensitiveContains(searchText) ||
            (ann.content ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredAnnotations) { ann in
                    Button {
                        navigateToAnnotation(ann)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(formatVerseId(ann.verseId))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "arrow.right.circle")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if let color = ann.color {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(ReaderView.markerColor(for: color))
                                        .frame(width: 12, height: 12)
                                    Text(color.rawValue.capitalized)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            if let content = ann.content {
                                Text(content)
                                    .font(.custom("Bradley Hand", size: 14))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                            }

                            Text(ann.timestamp, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { indices in
                    let toDelete = indices.map { filteredAnnotations[$0] }
                    for ann in toDelete {
                        storageService.removeAnnotation(verseId: ann.verseId, type: ann.type)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Caut\u{0103}...")
            .navigationTitle(annotationType == .highlight ? "Eviden\u{021B}ieri" : "Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Gata") { dismiss() }
                }
            }
        }
    }

    private func navigateToAnnotation(_ ann: Annotation) {
        let parts = ann.verseId.components(separatedBy: "_")
        guard parts.count >= 2,
              let book = bibleService.bibleBooks.first(where: { $0.name == parts[0] }),
              let chapter = Int(parts[1]) else { return }

        selectedBook = book
        selectedChapter = chapter
        showSheet = false
        selectedTab = 1 // Switch to Reader tab
    }

    private func formatVerseId(_ verseId: String) -> String {
        let parts = verseId.components(separatedBy: "_")
        if parts.count >= 3 {
            return "\(parts[0]) \(parts[1]):\(parts[2])"
        }
        return verseId
    }
}
