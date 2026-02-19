import SwiftUI

struct ShareCardView: View {
    let verse: Verse
    let bookName: String
    @Environment(\.dismiss) private var dismiss

    @State private var selectedStyle: CardStyle = .parchment

    enum CardStyle: String, CaseIterable {
        case parchment = "Pergament"
        case dark = "\u{00CE}ntunecat"
        case nature = "Natur\u{0103}"
        case royal = "Regal"

        var background: LinearGradient {
            switch self {
            case .parchment:
                return LinearGradient(
                    colors: [Color(red: 0.96, green: 0.93, blue: 0.85), Color(red: 0.92, green: 0.88, blue: 0.78)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .dark:
                return LinearGradient(
                    colors: [Color(red: 0.1, green: 0.1, blue: 0.15), Color(red: 0.15, green: 0.12, blue: 0.2)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .nature:
                return LinearGradient(
                    colors: [Color(red: 0.2, green: 0.4, blue: 0.3), Color(red: 0.15, green: 0.3, blue: 0.25)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .royal:
                return LinearGradient(
                    colors: [Color(red: 0.3, green: 0.2, blue: 0.4), Color(red: 0.2, green: 0.1, blue: 0.35)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
        }

        var textColor: Color {
            switch self {
            case .parchment: return Color(red: 0.2, green: 0.15, blue: 0.1)
            case .dark, .nature, .royal: return .white
            }
        }

        var accentColor: Color {
            switch self {
            case .parchment: return Color(red: 0.6, green: 0.45, blue: 0.25)
            case .dark: return Color(red: 0.6, green: 0.55, blue: 0.8)
            case .nature: return Color(red: 0.5, green: 0.8, blue: 0.6)
            case .royal: return Color(red: 0.8, green: 0.6, blue: 0.9)
            }
        }
    }

    private var shareText: String {
        let verseText = verse.text.trimmingCharacters(in: .whitespacesAndNewlines)
        return "\u{201E}\(verseText)\u{201D}\n\u{2014} \(bookName) \(verse.chapter):\(verse.verse)\n\nBiblia Sinodal\u{0103} 1914 \u{2014} Biblia Rom\u{00E2}n\u{0103}"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Style picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(CardStyle.allCases, id: \.self) { style in
                                Button {
                                    selectedStyle = style
                                } label: {
                                    Text(style.rawValue)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedStyle == style ? Color.blue : Color(.systemGray5))
                                        .foregroundStyle(selectedStyle == style ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Card preview
                    cardView
                        .padding(.horizontal)

                    // Share button — SwiftUI native
                    ShareLink(item: shareText) {
                        Label("Distribuie", systemImage: "square.and.arrow.up")
                            .font(.body.bold())
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.4, green: 0.3, blue: 0.2))
                    .padding(.horizontal)

                    Spacer(minLength: 20)
                }
                .padding(.top)
            }
            .navigationTitle("Distribuie Verset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Gata") { dismiss() }
                }
            }
        }
    }

    private var cardView: some View {
        VStack(spacing: 16) {
            Text("\u{2726}")
                .font(.title)
                .foregroundStyle(selectedStyle.accentColor)

            Text("\u{201E}\(verse.text.trimmingCharacters(in: .whitespacesAndNewlines))\u{201D}")
                .font(.system(size: 16, design: .serif))
                .italic()
                .multilineTextAlignment(.center)
                .foregroundStyle(selectedStyle.textColor)
                .lineSpacing(4)

            Text("\u{2014} \(bookName) \(verse.chapter):\(verse.verse)")
                .font(.caption.bold())
                .foregroundStyle(selectedStyle.accentColor)

            Text("Biblia Sinodal\u{0103} 1914 \u{2014} Biblia Rom\u{00E2}n\u{0103}")
                .font(.system(size: 9))
                .foregroundStyle(selectedStyle.textColor.opacity(0.5))
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(selectedStyle.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
