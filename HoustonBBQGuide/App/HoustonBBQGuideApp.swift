import SwiftUI

@main
struct HoustonBBQGuideApp: App {
    @State private var store = JointStore()
    @State private var passport = PassportStore()
    @State private var location = LocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(passport)
                .environment(location)
                .preferredColorScheme(.dark)
                .onChange(of: location.location) { _, newValue in
                    store.userLocation = newValue
                }
        }
    }
}
