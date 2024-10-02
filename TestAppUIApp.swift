import SwiftUI
import my_framework

@main
struct TestAppUIApp: App {
    init() {
        call_foo()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
}
