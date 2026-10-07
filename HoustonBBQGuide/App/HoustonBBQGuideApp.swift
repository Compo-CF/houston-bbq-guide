import SwiftUI

@main
struct HoustonBBQGuideApp: App {
    @State private var store = JointStore()
    @State private var passport = PassportStore()
    @State private var location = LocationManager()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(store)
                    .environment(passport)
                    .environment(location)
                    .onChange(of: location.location) { _, newValue in
                        store.userLocation = newValue
                    }

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .task {
                            // Hold long enough for the splash's own animation
                            // to finish; the store fetches joints in the
                            // background during this window.
                            try? await Task.sleep(for: .milliseconds(1400))
                            withAnimation(.easeOut(duration: 0.5)) {
                                showSplash = false
                            }
                        }
                        .allowsHitTesting(false)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
