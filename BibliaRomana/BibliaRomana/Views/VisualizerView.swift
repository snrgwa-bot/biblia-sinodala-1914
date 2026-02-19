import SwiftUI

struct VisualizerView: View {
    @Binding var selectedBook: BibleBook?
    @Binding var selectedChapter: Int
    @Binding var selectedTab: Int
    @Binding var pendingGlowVerseId: String?
    @Binding var pendingSourceTab: Int?

    @EnvironmentObject var storageService: StorageService
    @EnvironmentObject var bibleService: BibleService
    @EnvironmentObject var subscriptionService: SubscriptionService

    @State private var selectedSection: Section = .progress
    @State private var showPaywall = false

    enum Section: String, CaseIterable {
        case progress = "Progres"
        case annotations = "Adnot\u{0103}ri"
        case heatmap = "Hart\u{0103}"
        case timeline = "Cronologie"
    }

    var body: some View {
        NavigationStack {
            if subscriptionService.isSubscribed {
                VStack(spacing: 0) {
                    Picker("Sec\u{021B}iune", selection: $selectedSection) {
                        ForEach(Section.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    ScrollView {
                        switch selectedSection {
                        case .progress:
                            progressView
                        case .annotations:
                            annotationsListView
                        case .heatmap:
                            heatmapView
                        case .timeline:
                            timelineView
                        }
                    }
                }
            } else {
                lockedView
            }
        }
        .navigationTitle("Vizualizare")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscriptionService)
        }
    }

    // MARK: - Locked View (Paywall Prompt)

    private var lockedView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color(red: 0.4, green: 0.3, blue: 0.2).opacity(0.6))

            Text("Vizualizare Premium")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 10) {
                lockedFeatureRow(icon: "chart.bar.fill", text: "Progresul lecturii tale")
                lockedFeatureRow(icon: "bookmark.fill", text: "Toate adnot\u{0103}rile \u{0219}i eviden\u{021B}ierile")
                lockedFeatureRow(icon: "square.grid.3x3.fill", text: "Harta capitolelor citite")
                lockedFeatureRow(icon: "clock.fill", text: "Cronologia biblic\u{0103} interactiv\u{0103}")
            }
            .padding(.horizontal, 40)

            Button {
                showPaywall = true
            } label: {
                Label("Deblocheaz\u{0103} Vizualizare", systemImage: "crown")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.4, green: 0.3, blue: 0.2))
            .padding(.horizontal, 40)

            Button("Restaureaz\u{0103} achizi\u{021B}iile") {
                Task { await subscriptionService.restorePurchases() }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()
        }
    }

    @ViewBuilder
    private func lockedFeatureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color(red: 0.4, green: 0.3, blue: 0.2))
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }

    // MARK: - Reading Progress

    private var totalChapters: Int {
        bibleService.bibleBooks.reduce(0) { $0 + $1.chapters }
    }

    private var totalVisited: Int {
        storageService.visitedChapters.count
    }

    private var progressView: some View {
        VStack(spacing: 20) {
            // Overall progress circle
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: totalChapters > 0 ? Double(totalVisited) / Double(totalChapters) : 0)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: totalVisited)

                VStack(spacing: 4) {
                    Text("\(totalChapters > 0 ? Int(Double(totalVisited) / Double(totalChapters) * 100) : 0)%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("\(totalVisited) / \(totalChapters)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("capitole citite")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 180, height: 180)
            .padding(.top)

            // Stats row
            HStack(spacing: 24) {
                statCard(
                    value: "\(bibleService.bibleBooks.filter { storageService.visitedChapterCount(for: $0.id, totalChapters: $0.chapters) == $0.chapters && $0.chapters > 0 }.count)",
                    label: "C\u{0103}r\u{021B}i complete",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                statCard(
                    value: "\(storageService.annotations.filter { $0.type == .highlight }.count)",
                    label: "Eviden\u{021B}ieri",
                    icon: "highlighter",
                    color: .yellow
                )
                statCard(
                    value: "\(storageService.annotations.filter { $0.type == .note }.count)",
                    label: "Note",
                    icon: "note.text",
                    color: .orange
                )
            }
            .padding(.horizontal)

            Divider().padding(.horizontal)

            // Per-testament progress
            testamentProgress(title: "Vechiul Testament", testament: .old)
            testamentProgress(title: "Noul Testament", testament: .new)
            testamentProgress(title: "Deuterocanonice", testament: .deuterocanonical)

            Divider().padding(.horizontal)

            // Per-book progress
            VStack(alignment: .leading, spacing: 4) {
                Text("Progres per carte")
                    .font(.headline)
                    .padding(.horizontal)

                ForEach(bibleService.bibleBooks) { book in
                    let visited = storageService.visitedChapterCount(for: book.id, totalChapters: book.chapters)
                    let pct = book.chapters > 0 ? Double(visited) / Double(book.chapters) : 0

                    HStack(spacing: 8) {
                        Text(book.name)
                            .font(.caption)
                            .frame(width: 100, alignment: .leading)
                            .lineLimit(1)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(.systemGray5))
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(pct >= 1.0 ? Color.green : Color.blue.opacity(0.7))
                                    .frame(width: geo.size.width * pct)
                            }
                        }
                        .frame(height: 8)

                        Text("\(visited)/\(book.chapters)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 44, alignment: .trailing)
                    }
                    .padding(.horizontal)
                }
            }

            Spacer(minLength: 20)
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func testamentProgress(title: String, testament: BibleBook.Testament) -> some View {
        let books = bibleService.bibleBooks.filter { $0.testament == testament }
        let total = books.reduce(0) { $0 + $1.chapters }
        let visited = books.reduce(0) { $0 + storageService.visitedChapterCount(for: $1.id, totalChapters: $1.chapters) }
        let pct = total > 0 ? Double(visited) / Double(total) : 0

        return HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text("\(Int(pct * 100))%")
                .font(.subheadline.bold())
                .foregroundStyle(pct >= 1.0 ? .green : .primary)
        }
        .padding(.horizontal)
    }

    // MARK: - Annotations List (Tappable)

    private var annotationsListView: some View {
        let grouped = Dictionary(grouping: storageService.annotations, by: { extractBookName(from: $0.verseId) })

        return VStack(alignment: .leading, spacing: 12) {
            // Summary
            HStack(spacing: 16) {
                let highlights = storageService.annotations.filter { $0.type == .highlight }.count
                let notes = storageService.annotations.filter { $0.type == .note }.count

                Label("\(highlights) eviden\u{021B}ieri", systemImage: "highlighter")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("\(notes) note", systemImage: "note.text")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            if grouped.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Nicio adnotare \u{00EE}nc\u{0103}")
                        .foregroundStyle(.secondary)
                    Text("Atinge un verset \u{00EE}n Citire pentru a ad\u{0103}uga eviden\u{021B}ieri sau note.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                ForEach(bibleService.bibleBooks.filter { grouped[$0.name] != nil }) { book in
                    let bookAnnotations = (grouped[book.name] ?? []).sorted { a, b in
                        parseChapter(from: a.verseId) < parseChapter(from: b.verseId)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        // Book header
                        HStack {
                            Text(book.name)
                                .font(.subheadline.bold())
                            Spacer()
                            Text("\(bookAnnotations.count)")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(red: 0.4, green: 0.3, blue: 0.2))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))

                        // Individual annotations
                        ForEach(bookAnnotations) { ann in
                            Button {
                                navigateToAnnotation(ann, book: book)
                            } label: {
                                annotationRow(ann)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color(.systemGray5), lineWidth: 0.5)
                    )
                    .padding(.horizontal)
                }
            }

            Spacer(minLength: 20)
        }
        .padding(.top)
    }

    private func annotationRow(_ ann: Annotation) -> some View {
        let parts = ann.verseId.components(separatedBy: "_")
        let chapter = parts.count > 1 ? parts[1] : "?"
        let verse = parts.count > 2 ? parts[2] : "?"
        let refText = "\(chapter):\(verse)"

        return HStack(spacing: 10) {
            // Type indicator
            if ann.type == .highlight {
                Circle()
                    .fill(highlightDotColor(ann.color))
                    .frame(width: 14, height: 14)
            } else {
                Image(systemName: "note.text")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .frame(width: 14)
            }

            // Verse reference
            Text(refText)
                .font(.callout.monospaced().bold())
                .foregroundStyle(Color(red: 0.4, green: 0.3, blue: 0.2))
                .frame(width: 50, alignment: .leading)

            // Content preview
            if ann.type == .note, let content = ann.content, !content.isEmpty {
                Text(content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else if ann.type == .highlight {
                Text("Eviden\u{021B}iat")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private func navigateToAnnotation(_ ann: Annotation, book: BibleBook) {
        let chapter = parseChapter(from: ann.verseId)
        pendingSourceTab = 2
        selectedBook = book
        selectedChapter = max(1, chapter)
        selectedTab = 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            pendingGlowVerseId = ann.verseId
        }
    }

    private func parseChapter(from verseId: String) -> Int {
        let parts = verseId.components(separatedBy: "_")
        guard parts.count > 1 else { return 1 }
        return Int(parts[1]) ?? 1
    }

    private func highlightDotColor(_ color: Annotation.HighlightColor?) -> Color {
        guard let color = color else { return .gray }
        return ReaderView.markerColor(for: color)
    }

    private func extractBookName(from verseId: String) -> String {
        // verseId format: "BookName_chapter_verse"
        let parts = verseId.components(separatedBy: "_")
        return parts.first ?? ""
    }

    // MARK: - Chapter Heatmap

    private var heatmapView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Legend
            HStack(spacing: 12) {
                legendItem(color: Color(.systemGray4), label: "Necitit")
                legendItem(color: .green.opacity(0.5), label: "Citit")
                legendItem(color: .blue.opacity(0.7), label: "Adnotat")
            }
            .padding(.horizontal)

            ForEach(bibleService.bibleBooks) { book in
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.name)
                        .font(.caption.bold())

                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(14), spacing: 2), count: 20), spacing: 2) {
                        ForEach(1...book.chapters, id: \.self) { ch in
                            let visited = storageService.isChapterVisited(bookId: book.id, chapter: ch)
                            let hasAnn = chapterHasAnnotation(bookId: book.id, chapter: ch)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(hasAnn ? Color.blue.opacity(0.7) : (visited ? Color.green.opacity(0.5) : Color(.systemGray4)))
                                .frame(width: 14, height: 14)
                        }
                    }
                }
                .padding(.horizontal)
            }

            Spacer(minLength: 20)
        }
        .padding(.top)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func chapterHasAnnotation(bookId: String, chapter: Int) -> Bool {
        storageService.annotations.contains { ann in
            ann.verseId.hasPrefix("\(bookId)_\(chapter)_")
        }
    }

    // MARK: - Bible Timeline

    private var timelineView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(timelineEvents.enumerated()), id: \.offset) { index, event in
                HStack(alignment: .top, spacing: 12) {
                    // Timeline line + dot
                    VStack(spacing: 0) {
                        Circle()
                            .fill(event.color)
                            .frame(width: 12, height: 12)
                        if index < timelineEvents.count - 1 {
                            Rectangle()
                                .fill(Color(.systemGray4))
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: 12)

                    // Event card
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.period)
                            .font(.caption2.bold())
                            .foregroundStyle(event.color)

                        Text(event.title)
                            .font(.subheadline.bold())

                        Text(event.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        timelineReferencesView(event.reference)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }

            Spacer(minLength: 20)
        }
        .padding(.top)
    }

    // MARK: - Timeline Reference Navigation

    private static let bookNameAliases: [String: String] = [
        "Ie\u{0219}irea": "E\u{0219}irea",
        "Deuteronomul": "A Doua Lege",
        "Iosua": "Isus Navi",
        "1 Regi": "1 \u{00CE}mp\u{0103}ra\u{021B}i",
        "2 Regi": "2 \u{00CE}mp\u{0103}ra\u{021B}i",
        "3 Regi": "3 \u{00CE}mp\u{0103}ra\u{021B}i",
        "4 Regi": "4 \u{00CE}mp\u{0103}ra\u{021B}i",
        "Daniel": "Daniil",
        "Ezdra": "Esdra",
        "Maleahi": "Malahia",
    ]

    private func parseTimelineReferences(_ reference: String) -> [TimelineReference] {
        let segments = reference.components(separatedBy: ";")
        var results: [TimelineReference] = []

        // Build sorted list of all known names + aliases (longest first)
        let allNames: [String] = bibleService.bibleBooks.map { $0.name } + Array(Self.bookNameAliases.keys)
        let sortedNames = allNames.sorted { $0.count > $1.count }

        for segment in segments {
            let trimmed = segment.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            var matchedBook: BibleBook?
            var remaining = ""

            for name in sortedNames {
                if trimmed.hasPrefix(name) {
                    let afterBook = String(trimmed.dropFirst(name.count)).trimmingCharacters(in: .whitespaces)
                    if afterBook.isEmpty || afterBook.first?.isNumber == true {
                        let resolvedName = Self.bookNameAliases[name] ?? name
                        matchedBook = bibleService.bibleBooks.first(where: { $0.name == resolvedName })
                        remaining = afterBook
                        break
                    }
                }
            }

            guard let book = matchedBook else { continue }

            var chapter = 1
            if !remaining.isEmpty {
                let digits = String(remaining.prefix(while: { $0.isNumber }))
                if let ch = Int(digits) {
                    chapter = ch
                }
            }

            results.append(TimelineReference(displayText: trimmed, bookName: book.name, chapter: chapter))
        }

        return results
    }

    @ViewBuilder
    private func timelineReferencesView(_ reference: String) -> some View {
        let refs = parseTimelineReferences(reference)
        if refs.isEmpty {
            Text(reference)
                .font(.caption2)
                .foregroundStyle(.secondary)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(refs) { ref in
                        Button {
                            navigateToChapter(bookName: ref.bookName, chapter: ref.chapter)
                        } label: {
                            HStack(spacing: 2) {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 8))
                                Text(ref.displayText)
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func navigateToChapter(bookName: String, chapter: Int) {
        guard let book = bibleService.bibleBooks.first(where: { $0.name == bookName }) else { return }
        pendingSourceTab = 2
        selectedBook = book
        selectedChapter = chapter
        selectedTab = 1
    }

    private var timelineEvents: [TimelineEvent] {
        [
            // Geneza
            TimelineEvent(period: "La \u{00EE}nceput", title: "Crea\u{021B}ia lumii", description: "Dumnezeu creeaz\u{0103} cerurile \u{0219}i p\u{0103}m\u{00E2}ntul \u{00EE}n \u{0219}ase zile: lumina, cerul, uscatul, astrele, vie\u{021B}uitoarele \u{0219}i omul. Ziua a \u{0219}aptea \u{2013} odihna.", reference: "Facerea 1\u{2013}2", color: .green),
            TimelineEvent(period: "Dup\u{0103} Crea\u{021B}ie", title: "C\u{0103}derea \u{00EE}n p\u{0103}cat", description: "Adam \u{0219}i Eva m\u{0103}n\u{00E2}nc\u{0103} din pomul oprit, ispiti\u{021B}i de \u{0219}arpe. Sunt alunga\u{021B}i din Gr\u{0103}dina Edenului. Moartea intr\u{0103} \u{00EE}n lume.", reference: "Facerea 3", color: .red),
            TimelineEvent(period: "Dup\u{0103} C\u{0103}dere", title: "Cain \u{0219}i Abel", description: "Cain, primul n\u{0103}scut, \u{00EE}l ucide pe fratele s\u{0103}u Abel din invidie. Primul omor din istoria omenirii.", reference: "Facerea 4", color: .red),
            TimelineEvent(period: "~3000 \u{00EE}.Hr.", title: "Enoh \u{2013} r\u{0103}pit la cer", description: "Enoh a umblat cu Dumnezeu \u{0219}i a fost luat la cer f\u{0103}r\u{0103} s\u{0103} cunoasc\u{0103} moartea. A tr\u{0103}it 365 de ani.", reference: "Facerea 5:24", color: .blue),
            TimelineEvent(period: "~2500 \u{00EE}.Hr.", title: "Potopul lui Noe", description: "Dumnezeu trimite potopul asupra p\u{0103}m\u{00E2}ntului din cauza r\u{0103}ut\u{0103}\u{021B}ii oamenilor. Noe construie\u{0219}te corabia \u{0219}i salveaz\u{0103} familia sa \u{0219}i animalele. Curcubeul \u{2013} semn al leg\u{0103}m\u{00E2}ntului.", reference: "Facerea 6\u{2013}9", color: .blue),
            TimelineEvent(period: "~2200 \u{00EE}.Hr.", title: "Turnul Babel", description: "Oamenii \u{00EE}ncearc\u{0103} s\u{0103} construiasc\u{0103} un turn p\u{00E2}n\u{0103} la cer. Dumnezeu le amestec\u{0103} limbile \u{0219}i \u{00EE}i \u{00EE}mpr\u{0103}\u{0219}tie pe fa\u{021B}a p\u{0103}m\u{00E2}ntului.", reference: "Facerea 11:1\u{2013}9", color: .orange),

            // Patriarhii
            TimelineEvent(period: "~2000 \u{00EE}.Hr.", title: "Chemarea lui Avraam", description: "Dumnezeu \u{00EE}l cheam\u{0103} pe Avram din Ur al Caldeilor. Face leg\u{0103}m\u{00E2}nt cu el: \u{00EE}i promite o na\u{021B}iune mare, un p\u{0103}m\u{00E2}nt \u{0219}i binecuv\u{00E2}ntare pentru toate neamurile.", reference: "Facerea 12\u{2013}17", color: .orange),
            TimelineEvent(period: "~1900 \u{00EE}.Hr.", title: "Distrugerea Sodomei", description: "Dumnezeu distruge Sodoma \u{0219}i Gomora prin foc \u{0219}i pucioaz\u{0103}. Lot \u{0219}i fiicele sale sunt salva\u{021B}i. So\u{021B}ia lui Lot se preface \u{00EE}n st\u{00E2}lp de sare.", reference: "Facerea 19", color: .red),
            TimelineEvent(period: "~1900 \u{00EE}.Hr.", title: "Jertfa lui Isaac", description: "Dumnezeu \u{00EE}l \u{00EE}ncearc\u{0103} pe Avraam cer\u{00E2}ndu-i s\u{0103}-l jertfeasc\u{0103} pe Isaac. Un \u{00EE}nger \u{00EE}l opre\u{0219}te. Proorocie a jertfei lui Hristos.", reference: "Facerea 22", color: .purple),
            TimelineEvent(period: "~1850 \u{00EE}.Hr.", title: "Iacov \u{0219}i Esau", description: "Iacov prime\u{0219}te binecuv\u{00E2}ntarea. Se lupt\u{0103} cu \u{00EE}ngerul la Peniel \u{0219}i prime\u{0219}te numele Israel. Cei 12 fii vor forma cele 12 semin\u{021B}ii.", reference: "Facerea 25\u{2013}35", color: .blue),
            TimelineEvent(period: "~1800 \u{00EE}.Hr.", title: "Iosif \u{00EE}n Egipt", description: "V\u{00E2}ndut de fra\u{021B}ii s\u{0103}i ca sclav, Iosif ajunge guvernatorul Egiptului prin \u{00EE}n\u{021B}elepciunea dat\u{0103} de Dumnezeu. T\u{00E2}lcuie\u{0219}te visele lui Faraon. \u{00CE}\u{0219}i iart\u{0103} fra\u{021B}ii.", reference: "Facerea 37\u{2013}50", color: .purple),

            // Ie\u{0219}irea \u{0219}i Legea
            TimelineEvent(period: "~1500 \u{00EE}.Hr.", title: "Robia \u{00EE}n Egipt", description: "Poporul Israel cre\u{0219}te \u{00EE}n Egipt dar este asupritor robit. Moise se na\u{0219}te \u{0219}i este salvat din ape de fiica lui Faraon.", reference: "Ie\u{0219}irea 1\u{2013}2", color: .red),
            TimelineEvent(period: "~1450 \u{00EE}.Hr.", title: "Rugul aprins", description: "Dumnezeu i Se arat\u{0103} lui Moise \u{00EE}n rugul care ardea f\u{0103}r\u{0103} s\u{0103} se mistuie. \u{00CE}i descoper\u{0103} Numele: \u{201E}EU SUNT CEL CE SUNT\u{201D}.", reference: "Ie\u{0219}irea 3", color: .yellow),
            TimelineEvent(period: "~1450 \u{00EE}.Hr.", title: "Cele 10 Pedepse", description: "Dumnezeu trimite zece urgii asupra Egiptului: s\u{00E2}ngele, broa\u{0219}tele, t\u{00E2}n\u{021B}arii, mu\u{0219}tele, ciuma, bubele, grindina, l\u{0103}custele, \u{00EE}ntunericul \u{0219}i moartea \u{00EE}nt\u{00E2}ilor-n\u{0103}scu\u{021B}i.", reference: "Ie\u{0219}irea 7\u{2013}12", color: .red),
            TimelineEvent(period: "~1450 \u{00EE}.Hr.", title: "Ie\u{0219}irea din Egipt", description: "Moise conduce poporul Israel din robia egiptean\u{0103}. Trecerea miraculoas\u{0103} a M\u{0103}rii Ro\u{0219}ii. Pa\u{0219}tile \u{2013} s\u{0103}rb\u{0103}toarea eliber\u{0103}rii.", reference: "Ie\u{0219}irea 12\u{2013}15", color: .green),
            TimelineEvent(period: "~1450 \u{00EE}.Hr.", title: "Cele 10 Porunci", description: "Pe Muntele Sinai, Dumnezeu d\u{0103} Legea lui Moise: cele zece porunci gravate pe table de piatr\u{0103}. Fundamentul moral al credin\u{021B}ei.", reference: "Ie\u{0219}irea 20", color: .yellow),
            TimelineEvent(period: "~1450 \u{00EE}.Hr.", title: "Vi\u{021B}elul de aur", description: "C\u{00E2}t Moise era pe munte, poporul a f\u{0103}cut un idol de aur. Moise sparge tablele Legii. 3000 de oameni pier.", reference: "Ie\u{0219}irea 32", color: .red),
            TimelineEvent(period: "~1450\u{2013}1410 \u{00EE}.Hr.", title: "40 de ani \u{00EE}n pustie", description: "Din cauza necredin\u{021B}ei, poporul r\u{0103}t\u{0103}ce\u{0219}te 40 de ani prin pustie. Mana din cer, apa din st\u{00E2}nc\u{0103}, \u{0219}arpele de aram\u{0103}.", reference: "Numerii 14; Deuteronomul 8", color: .orange),

            // Cucerirea \u{0219}i Judec\u{0103}torii
            TimelineEvent(period: "~1410 \u{00EE}.Hr.", title: "Moartea lui Moise", description: "Moise vede P\u{0103}m\u{00E2}ntul F\u{0103}g\u{0103}duin\u{021B}ei de pe Muntele Nebo dar nu intr\u{0103} \u{00EE}n el. Moare la 120 de ani. Iosua \u{00EE}i urmeaz\u{0103}.", reference: "Deuteronomul 34", color: .purple),
            TimelineEvent(period: "~1400 \u{00EE}.Hr.", title: "Intrarea \u{00EE}n Canaan", description: "Iosua conduce poporul peste Iordan \u{00EE}n P\u{0103}m\u{00E2}ntul F\u{0103}g\u{0103}duin\u{021B}ei. Zidurile Ierihonului cad miraculos la sunetul tr\u{00E2}mbi\u{021B}elor.", reference: "Iosua 1\u{2013}6", color: .green),
            TimelineEvent(period: "~1350\u{2013}1050 \u{00EE}.Hr.", title: "Epoca Judec\u{0103}torilor", description: "Perioada de instabilitate. Dumnezeu ridic\u{0103} judec\u{0103}tori: Ghedeon, Samson, Debora, Samuel. Cicluri de p\u{0103}cat, pedeaps\u{0103}, poc\u{0103}in\u{021B}\u{0103} \u{0219}i eliberare.", reference: "Judec\u{0103}torii 1\u{2013}21", color: .blue),
            TimelineEvent(period: "~1100 \u{00EE}.Hr.", title: "Rut \u{0219}i Boaz", description: "Rut moabiteanca urmeaz\u{0103} pe soacra sa Naomi \u{00EE}n Israel. Se c\u{0103}s\u{0103}tore\u{0219}te cu Boaz. Str\u{0103}moasa regelui David \u{0219}i a lui Iisus.", reference: "Rut 1\u{2013}4", color: .green),

            // Regi
            TimelineEvent(period: "~1050 \u{00EE}.Hr.", title: "Primul rege \u{2013} Saul", description: "Poporul cere un rege. Samuel \u{00EE}l unge pe Saul. \u{00CE}nceput promit\u{0103}tor, dar neascultarea \u{00EE}l \u{00EE}ndep\u{0103}rteaz\u{0103} de Dumnezeu.", reference: "1 Regi 8\u{2013}15", color: .blue),
            TimelineEvent(period: "~1010 \u{00EE}.Hr.", title: "David \u{0219}i Goliat", description: "T\u{00E2}n\u{0103}rul p\u{0103}stor David \u{00EE}l \u{00EE}nvinge pe uria\u{0219}ul Goliat cu o piatr\u{0103} \u{0219}i o pra\u{0219}tie. Credin\u{021B}a biruie for\u{021B}a.", reference: "1 Regi 17", color: .orange),
            TimelineEvent(period: "~1000 \u{00EE}.Hr.", title: "Regele David", description: "David cucere\u{0219}te Ierusalimul \u{0219}i \u{00EE}l face capital\u{0103}. Aduce Chivotul Leg\u{0103}m\u{00E2}ntului. Compune Psalmii. Proorocie mesianc\u{0103} \u{2013} tronul ve\u{0219}nic.", reference: "2 Regi 5\u{2013}7", color: .blue),
            TimelineEvent(period: "~970 \u{00EE}.Hr.", title: "Templul lui Solomon", description: "Solomon construie\u{0219}te primul Templu \u{00EE}n Ierusalim \u{00EE}n 7 ani. Slava lui Dumnezeu umple Templul. Epoca de aur a Israelului.", reference: "3 Regi 6\u{2013}8", color: .orange),
            TimelineEvent(period: "~930 \u{00EE}.Hr.", title: "\u{00CE}mp\u{0103}r\u{021B}irea Regatului", description: "Dup\u{0103} Solomon, regatul se divide: Israel (\u{00EE}n nord, 10 semin\u{021B}ii) \u{0219}i Iuda (\u{00EE}n sud, 2 semin\u{021B}ii). Conflict \u{0219}i declin spiritual.", reference: "3 Regi 12", color: .red),

            // Prooroci \u{0219}i Robie
            TimelineEvent(period: "~870 \u{00EE}.Hr.", title: "Proorocul Ilie", description: "Ilie se lupt\u{0103} \u{00EE}mpotriva idolatriei. Confruntarea de pe Muntele Carmel cu profe\u{021B}ii lui Baal. Este r\u{0103}pit la cer \u{00EE}ntr-un car de foc.", reference: "3 Regi 17\u{2013}19; 4 Regi 2", color: .orange),
            TimelineEvent(period: "~850 \u{00EE}.Hr.", title: "Proorocul Elisei", description: "Ucenicul lui Ilie. Face multe minuni: vindec\u{0103} ape, \u{00EE}nmul\u{021B}e\u{0219}te uleiul v\u{0103}duvei, \u{00EE}nvie pe fiul sunamitencei.", reference: "4 Regi 2\u{2013}13", color: .blue),
            TimelineEvent(period: "~760 \u{00EE}.Hr.", title: "Iona \u{0219}i Ninive", description: "Iona fuge de misiunea sa, este \u{00EE}nghi\u{021B}it de un pe\u{0219}te mare 3 zile. Se poc\u{0103}ie\u{0219}te \u{0219}i predic\u{0103} \u{00EE}n Ninive. Proorocie a \u{00CE}nvierii.", reference: "Iona 1\u{2013}4", color: .purple),
            TimelineEvent(period: "~740 \u{00EE}.Hr.", title: "Proorocul Isaia", description: "Marele prooroc al lui Mesia. Prooroce\u{0219}te na\u{0219}terea din fecioar\u{0103}, patimile \u{0219}i slava lui Hristos. \u{201E}Iat\u{0103}, Fecioara va lua \u{00EE}n p\u{00E2}ntece.\u{201D}", reference: "Isaia 7:14; 9:6; 53", color: .purple),
            TimelineEvent(period: "~722 \u{00EE}.Hr.", title: "C\u{0103}derea Israelului (Nord)", description: "Regatul de Nord (Israel) este cucerit de Imperiul Asirian. Cele 10 semin\u{021B}ii sunt deportate. Samaritenii se a\u{0219}eaz\u{0103} \u{00EE}n \u{021B}ar\u{0103}.", reference: "4 Regi 17", color: .red),
            TimelineEvent(period: "~620 \u{00EE}.Hr.", title: "Proorocul Ieremia", description: "Proorocul lacrimilor. Avertizeaz\u{0103} Iuda despre distrugerea care vine. Prooroce\u{0219}te un Leg\u{0103}m\u{00E2}nt Nou scris \u{00EE}n inimi.", reference: "Ieremia 31:31\u{2013}34", color: .blue),
            TimelineEvent(period: "~586 \u{00EE}.Hr.", title: "Distrugerea Ierusalimului", description: "Nabucodonosor cucere\u{0219}te Ierusalimul, distruge Templul lui Solomon. Poporul Iuda este dus \u{00EE}n captivitate la Babilon. \u{00CE}nceputul Robiei.", reference: "4 Regi 25; Ieremia 52", color: .red),
            TimelineEvent(period: "~580 \u{00EE}.Hr.", title: "Daniel \u{00EE}n Babilon", description: "Daniel \u{0219}i cei trei tineri refuz\u{0103} idolatria. Groapa cu lei, cuptorul de foc. Visele profetice despre \u{00EE}mp\u{0103}r\u{0103}\u{021B}iile lumii.", reference: "Daniel 1\u{2013}12", color: .orange),
            TimelineEvent(period: "~538 \u{00EE}.Hr.", title: "\u{00CE}ntoarcerea din robie", description: "Cirus Persanul elibereaz\u{0103} evreii. Sub Zorobabel, poporul se \u{00EE}ntoarce \u{0219}i reconstruie\u{0219}te Templul (al doilea Templu, sfin\u{021B}it \u{00EE}n 516 \u{00EE}.Hr.).", reference: "Ezdra 1\u{2013}6", color: .green),
            TimelineEvent(period: "~445 \u{00EE}.Hr.", title: "Neemia \u{2013} Zidurile Ierusalimului", description: "Neemia reconstruie\u{0219}te zidurile Ierusalimului \u{00EE}n 52 de zile, \u{00EE}n ciuda opozi\u{021B}iei. Ezdra cite\u{0219}te Legea poporului.", reference: "Neemia 1\u{2013}13", color: .green),
            TimelineEvent(period: "~400 \u{00EE}.Hr.", title: "Ultimii Prooroci", description: "Maleahi, ultimul prooroc al Vechiului Testament. Prooroce\u{0219}te venirea lui Ilie \u{00EE}nainte de Mesia. Urmeaz\u{0103} 400 de ani de t\u{0103}cere profetic\u{0103}.", reference: "Maleahi 3\u{2013}4", color: .purple),

            // Noul Testament
            TimelineEvent(period: "~5 \u{00EE}.Hr.", title: "Bunavestire", description: "Arhanghelul Gavriil \u{00EE}i vesteste Fecioarei Maria c\u{0103} va na\u{0219}te pe Fiul lui Dumnezeu. \u{201E}Bucur\u{0103}-te, ceea ce e\u{0219}ti plin\u{0103} de har!\u{201D}", reference: "Luca 1:26\u{2013}38", color: .yellow),
            TimelineEvent(period: "~5 \u{00EE}.Hr.", title: "Na\u{0219}terea lui Iisus", description: "Iisus Hristos Se na\u{0219}te \u{00EE}n Betleem, \u{00EE}ntr-o ie\u{0219}le. Magii de la R\u{0103}s\u{0103}rit \u{00EE}i aduc daruri. P\u{0103}storii sunt vesti\u{021B}i de \u{00EE}ngeri. Steaua c\u{0103}l\u{0103}uzitoare.", reference: "Matei 1\u{2013}2; Luca 2", color: .yellow),
            TimelineEvent(period: "~27 d.Hr.", title: "Botezul Domnului", description: "Iisus este botezat de Ioan \u{00EE}n Iordan. Duhul Sf\u{00E2}nt coboar\u{0103} ca un porumbel. Glasul Tat\u{0103}lui: \u{201E}Acesta este Fiul Meu cel iubit.\u{201D}", reference: "Matei 3:13\u{2013}17", color: .blue),
            TimelineEvent(period: "~27 d.Hr.", title: "Ispitirea \u{00EE}n pustie", description: "Iisus poste\u{0219}te 40 de zile \u{0219}i este ispitit de diavol de trei ori. Biruie\u{0219}te prin Cuv\u{00E2}ntul lui Dumnezeu.", reference: "Matei 4:1\u{2013}11", color: .orange),
            TimelineEvent(period: "~27 d.Hr.", title: "Alegerea Apostolilor", description: "Iisus \u{00EE}i alege pe cei 12 Apostoli: Petru, Andrei, Iacov, Ioan, Filip, Bartolomeu, Matei, Toma, Iacov al lui Alfeu, Tadeu, Simon \u{0219}i Iuda.", reference: "Matei 10:1\u{2013}4; Luca 6:12\u{2013}16", color: .blue),
            TimelineEvent(period: "~28 d.Hr.", title: "Nunta din Cana", description: "Prima minune: Iisus preface apa \u{00EE}n vin la nunta din Cana Galileii. \u{00CE}\u{0219}i arat\u{0103} slava Sa.", reference: "Ioan 2:1\u{2013}11", color: .green),
            TimelineEvent(period: "~28\u{2013}30 d.Hr.", title: "Minunile lui Iisus", description: "Vindec\u{0103}ri, \u{00EE}nmul\u{021B}irea p\u{00E2}inilor, umblarea pe ap\u{0103}, \u{00EE}nvierea lui Laz\u{0103}r, potolirea furtunii. Semne ale \u{00CE}mp\u{0103}r\u{0103}\u{021B}iei lui Dumnezeu.", reference: "Matei\u{2013}Ioan (multiple)", color: .green),
            TimelineEvent(period: "~29 d.Hr.", title: "Predica de pe Munte", description: "Fericirile, Tat\u{0103}l nostru, \u{00EE}nv\u{0103}\u{021B}\u{0103}turi despre iubirea vr\u{0103}jma\u{0219}ilor, milostenie, post \u{0219}i rug\u{0103}ciune. Carta Magna a cre\u{0219}tinismului.", reference: "Matei 5\u{2013}7", color: .purple),
            TimelineEvent(period: "~29 d.Hr.", title: "Schimbarea la Fa\u{021B}\u{0103}", description: "Pe Muntele Tabor, Iisus Se schimb\u{0103} la fa\u{021B}\u{0103} \u{00EE}naintea lui Petru, Iacov \u{0219}i Ioan. Fa\u{021B}a Sa str\u{0103}luce\u{0219}te ca soarele. Apar Moise \u{0219}i Ilie.", reference: "Matei 17:1\u{2013}9", color: .yellow),
            TimelineEvent(period: "~29 d.Hr.", title: "\u{00CE}nvierea lui Laz\u{0103}r", description: "Iisus \u{00EE}l \u{00EE}nvie pe Laz\u{0103}r din Betania dup\u{0103} patru zile de la moarte. \u{201E}Eu sunt \u{00CE}nvierea \u{0219}i Via\u{021B}a.\u{201D}", reference: "Ioan 11:1\u{2013}44", color: .green),

            // Patimile \u{0219}i \u{00CE}nvierea
            TimelineEvent(period: "~30 d.Hr.", title: "Intrarea \u{00EE}n Ierusalim", description: "Iisus intr\u{0103} triumfal \u{00EE}n Ierusalim pe un m\u{00E2}nz de asin\u{0103}. Mul\u{021B}imile strig\u{0103} \u{201E}Osana!\u{201D} \u{0219}i a\u{0219}tern haine \u{0219}i ramuri de finic.", reference: "Matei 21:1\u{2013}11", color: .green),
            TimelineEvent(period: "~30 d.Hr.", title: "Cina cea de Tain\u{0103}", description: "Iisus spal\u{0103} picioarele ucenicilor. Instituie Sfintele Taine \u{2013} P\u{00E2}inea \u{0219}i Vinul: Trupul \u{0219}i S\u{00E2}ngele S\u{0103}u. Porunca nou\u{0103}: \u{201E}S\u{0103} v\u{0103} iubi\u{021B}i unii pe al\u{021B}ii.\u{201D}", reference: "Matei 26; Ioan 13\u{2013}17", color: .orange),
            TimelineEvent(period: "~30 d.Hr.", title: "Rug\u{0103}ciunea din Ghetsimani", description: "Iisus Se roag\u{0103} cu sudoare de s\u{00E2}nge. \u{201E}P\u{0103}rinte, de este cu putin\u{021B}\u{0103}, treac\u{0103} de la Mine paharul acesta; \u{00EE}ns\u{0103} nu cum voiesc Eu, ci cum voie\u{0219}ti Tu.\u{201D}", reference: "Matei 26:36\u{2013}46", color: .purple),
            TimelineEvent(period: "~30 d.Hr.", title: "R\u{0103}stignirea", description: "Iisus este judecat, batjocorit, biciuit \u{0219}i r\u{0103}stignit pe Golgota \u{00EE}ntre doi t\u{00E2}lhari. \u{201E}P\u{0103}rinte, iart\u{0103}-le lor, c\u{0103} nu \u{0219}tiu ce fac.\u{201D} Moare la Ceasul al 9-lea.", reference: "Matei 27; Marcu 15; Luca 23; Ioan 19", color: .red),
            TimelineEvent(period: "~30 d.Hr.", title: "\u{00CE}nvierea Domnului", description: "A treia zi, Iisus \u{00EE}nvie din mor\u{021B}i. Mormntul gol. Se arat\u{0103} Mariei Magdalena, apoi ucenicilor. Biruie moartea \u{0219}i iadul.", reference: "Matei 28; Marcu 16; Luca 24; Ioan 20", color: .green),
            TimelineEvent(period: "~30 d.Hr.", title: "Ar\u{0103}t\u{0103}rile dup\u{0103} \u{00CE}nviere", description: "Iisus Se arat\u{0103} timp de 40 de zile: ucenicilor din Emaus, Apostolilor, lui Toma cel necredincios, la Marea Tiberiadei. Peste 500 de martori.", reference: "1 Corinteni 15:3\u{2013}8; Ioan 20\u{2013}21", color: .blue),
            TimelineEvent(period: "~30 d.Hr.", title: "\u{00CE}n\u{0103}l\u{021B}area la cer", description: "Dup\u{0103} 40 de zile, Iisus Se \u{00EE}nal\u{021B}\u{0103} la cer de pe Muntele M\u{0103}slinilor, \u{00EE}n prezen\u{021B}a Apostolilor. Doi \u{00EE}ngeri vestesc a doua venire.", reference: "Faptele Apostolilor 1:1\u{2013}11", color: .blue),
            TimelineEvent(period: "~30 d.Hr.", title: "Pogor\u{00E2}rea Sf\u{00E2}ntului Duh", description: "La Cincizecime, Duhul Sf\u{00E2}nt coboar\u{0103} ca limbi de foc peste Apostoli. Vorbesc \u{00EE}n limbi. Petru predic\u{0103} \u{0219}i 3000 de suflete se botez\u{0103}. Na\u{0219}terea Bisericii.", reference: "Faptele Apostolilor 2", color: .yellow),

            // Biserica primar\u{0103}
            TimelineEvent(period: "~34 d.Hr.", title: "Sf\u{00E2}ntul \u{0218}tefan \u{2013} Primul Martir", description: "Diaconul \u{0218}tefan este ucis cu pietre, devenind primul martir cre\u{0219}tin. Vede cerurile deschise \u{0219}i pe Iisus st\u{00E2}nd de-a dreapta lui Dumnezeu.", reference: "Faptele Apostolilor 7", color: .red),
            TimelineEvent(period: "~35 d.Hr.", title: "Convertirea lui Saul (Pavel)", description: "Saul, persecutor al cre\u{0219}tinilor, este orbit de o lumin\u{0103} pe drumul Damascului. Aude glasul lui Iisus. Devine Apostolul neamurilor.", reference: "Faptele Apostolilor 9", color: .orange),
            TimelineEvent(period: "~46\u{2013}58 d.Hr.", title: "C\u{0103}l\u{0103}toriile Sf. Pavel", description: "Trei c\u{0103}l\u{0103}torii misionare \u{00EE}n Asia Mic\u{0103}, Grecia \u{0219}i Macedonia. \u{00CE}nfiin\u{021B}eaz\u{0103} comunit\u{0103}\u{021B}i cre\u{0219}tine. Scrie Epistolele.", reference: "Faptele Apostolilor 13\u{2013}28", color: .blue),
            TimelineEvent(period: "~49 d.Hr.", title: "Sinodul Apostolic", description: "Primul sinod al Bisericii \u{00EE}n Ierusalim. Se hot\u{0103}r\u{0103}\u{0219}te c\u{0103} neamurile nu trebuie s\u{0103} \u{021B}in\u{0103} Legea lui Moise pentru a fi m\u{00E2}ntuite.", reference: "Faptele Apostolilor 15", color: .purple),
            TimelineEvent(period: "~64\u{2013}67 d.Hr.", title: "Martiriul Sf. Petru \u{0219}i Pavel", description: "Sf. Petru este r\u{0103}stignit cu capul \u{00EE}n jos la Roma. Sf. Pavel este decapitat. Primii st\u{00E2}lpi ai Bisericii \u{00EE}\u{0219}i d\u{0103}au via\u{021B}a pentru Hristos.", reference: "Tradi\u{021B}ia Bisericii; 2 Timotei 4", color: .red),
            TimelineEvent(period: "~70 d.Hr.", title: "Distrugerea Templului", description: "Armatele romane sub Titus distrug Ierusalimul \u{0219}i al doilea Templu. Proorocia lui Iisus se \u{00EE}mpline\u{0219}te: \u{201E}Nu va r\u{0103}m\u{00E2}ne piatr\u{0103} pe piatr\u{0103}.\u{201D}", reference: "Matei 24:1\u{2013}2", color: .red),
            TimelineEvent(period: "~95 d.Hr.", title: "Apocalipsa", description: "Sf. Ioan Teologul, exilat \u{00EE}n Patmos, prime\u{0219}te vedenia despre sf\u{00E2}r\u{0219}itul veacurilor: cele 7 Biserici, cele 7 pece\u{021B}i, lupta final\u{0103}, Ierusalimul Ceresc \u{0219}i venirea \u{00EE}ntru slav\u{0103}.", reference: "Apocalipsa 1\u{2013}22", color: .purple),
        ]
    }
}

// MARK: - Timeline Event Model

private struct TimelineEvent {
    let period: String
    let title: String
    let description: String
    let reference: String
    let color: Color
}

private struct TimelineReference: Identifiable {
    let id = UUID()
    let displayText: String
    let bookName: String
    let chapter: Int
}
