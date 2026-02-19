import SwiftUI

@main
struct BibliaRomanaApp: App {
    @ObservedObject private var storageService = StorageService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorScheme)
        }
    }

    private var colorScheme: ColorScheme? {
        switch storageService.settings.theme {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}
