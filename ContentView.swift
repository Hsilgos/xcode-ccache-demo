import SwiftUI
import my_framework


struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
    
    init() {
        print("OLOLO1")
        call_foo()
        print("OLOLO2")
    }
}

#Preview {
    ContentView()
}
