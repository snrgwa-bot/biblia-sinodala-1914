import SwiftUI

struct LibraryView: View {
    @Binding var selectedBook: BibleBook?
    @Binding var selectedChapter: Int
    @Binding var selectedTab: Int
    @EnvironmentObject var bibleService: BibleService

    @State private var searchText = ""
    @State private var showingChapterPicker = false
    @State private var pickerBook: BibleBook?

    private var oldTestament: [BibleBook] {
        bibleService.bibleBooks.filter { $0.testament == .old }
    }

    private var newTestament: [BibleBook] {
        bibleService.bibleBooks.filter { $0.testament == .new }
    }

    private var deuterocanonical: [BibleBook] {
        bibleService.bibleBooks.filter { $0.testament == .deuterocanonical }
    }

    private var filteredOT: [BibleBook] {
        if searchText.isEmpty { return oldTestament }
        return oldTestament.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredNT: [BibleBook] {
        if searchText.isEmpty { return newTestament }
        return newTestament.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredDC: [BibleBook] {
        if searchText.isEmpty { return deuterocanonical }
        return deuterocanonical.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private let bookColumns = [
        GridItem(.adaptive(minimum: 100, maximum: 130), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if !filteredOT.isEmpty {
                        bookSection(title: "Vechiul Testament", books: filteredOT)
                    }
                    if !filteredDC.isEmpty {
                        bookSection(title: "C\u{0103}r\u{021B}i Deuterocanonice", books: filteredDC)
                    }
                    if !filteredNT.isEmpty {
                        bookSection(title: "Noul Testament", books: filteredNT)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("Biblia Sinodal\u{0103} 1914")
            .searchable(text: $searchText, prompt: "Caut\u{0103} o carte...")
            .sheet(item: $pickerBook) { book in
                ChapterPickerSheet(
                    book: book,
                    onSelect: { chapter in
                        selectedBook = book
                        selectedChapter = chapter
                        selectedTab = 1
                        pickerBook = nil
                    }
                )
                .presentationDetents([.medium])
            }
        }
    }

    @ViewBuilder
    private func bookSection(title: String, books: [BibleBook]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3.bold())
                .padding(.top, 4)

            LazyVGrid(columns: bookColumns, spacing: 14) {
                ForEach(books) { book in
                    bookCover(book)
                }
            }
        }
    }

    @ViewBuilder
    private func bookCover(_ book: BibleBook) -> some View {
        Button {
            if book.chapters == 1 {
                selectedBook = book
                selectedChapter = 1
                selectedTab = 1
            } else {
                pickerBook = book
            }
        } label: {
            VStack(spacing: 0) {
                Spacer(minLength: 8)
                Text(book.name)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(coverTextColor(book.testament))
                    .padding(.horizontal, 6)
                Spacer(minLength: 4)
                Text("\(book.chapters) cap.")
                    .font(.system(size: 9))
                    .foregroundStyle(coverTextColor(book.testament).opacity(0.7))
                    .padding(.bottom, 10)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(coverGradient(book.testament))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(coverBorderColor(book.testament), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 3, x: 1, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func coverGradient(_ testament: BibleBook.Testament) -> LinearGradient {
        switch testament {
        case .old:
            return LinearGradient(
                colors: [Color(red: 0.45, green: 0.33, blue: 0.22), Color(red: 0.35, green: 0.25, blue: 0.15)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .new:
            return LinearGradient(
                colors: [Color(red: 0.18, green: 0.25, blue: 0.42), Color(red: 0.12, green: 0.18, blue: 0.35)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .deuterocanonical:
            return LinearGradient(
                colors: [Color(red: 0.22, green: 0.38, blue: 0.28), Color(red: 0.15, green: 0.30, blue: 0.20)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    private func coverTextColor(_ testament: BibleBook.Testament) -> Color {
        Color(red: 0.95, green: 0.92, blue: 0.85)
    }

    private func coverBorderColor(_ testament: BibleBook.Testament) -> Color {
        switch testament {
        case .old: return Color(red: 0.55, green: 0.43, blue: 0.30).opacity(0.5)
        case .new: return Color(red: 0.30, green: 0.38, blue: 0.55).opacity(0.5)
        case .deuterocanonical: return Color(red: 0.30, green: 0.48, blue: 0.35).opacity(0.5)
        }
    }
}

// MARK: - Chapter Picker Sheet

struct ChapterPickerSheet: View {
    let book: BibleBook
    let onSelect: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(1...book.chapters, id: \.self) { chapter in
                        Button {
                            onSelect(chapter)
                        } label: {
                            Text("\(chapter)")
                                .font(.body.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
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
            }
        }
    }
}
