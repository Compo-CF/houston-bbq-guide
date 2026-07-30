import SwiftUI

/// Root tab bar — the four pillars of the app.
struct ContentView: View {
    @Environment(LocationManager.self) private var location

    var body: some View {
        TabView {
            FinderTabView()
                .tabItem { Label("Finder", systemImage: "fork.knife") }
            GuideTabView()
                .tabItem { Label("Guide", systemImage: "book.closed.fill") }
            PassportTabView()
                .tabItem { Label("Passport", systemImage: "checklist") }
            EventsTabView()
                .tabItem { Label("Events", systemImage: "calendar") }
        }
        .tint(Theme.amber)
        .task {
            // Ask for location once, up front, so "near me" sorting works.
            if location.authorizationStatus == .notDetermined {
                location.request()
            }
        }
    }
}
