//
// https://github.com/atacan
// 20.05.24
	

import SwiftUI
import ComposableArchitecture

@main
struct DiscusssionSharedInDependencyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(store: Store(initialState: Content.State(), reducer: {
                Content()
            }))
        }
    }
}
