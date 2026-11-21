import SwiftUI

enum AppInfo {
    static let nombre = "PrintBro"
}

@main
struct PrintBroApp: App {
    var body: some Scene {
        WindowGroup(AppInfo.nombre) {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Bienvenido a PrintBro")
                .font(.title)
            Text("Elegí un PDF para imprimir.")
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(minWidth: 420, minHeight: 260)
    }
}
