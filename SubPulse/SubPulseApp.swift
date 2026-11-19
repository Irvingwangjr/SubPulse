import SwiftData
import SwiftUI

@main
struct SubPulseApp: App {
    @State private var storeManager = StoreManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(storeManager)
        }
        .modelContainer(for: SubscriptionItem.self)
    }
}
