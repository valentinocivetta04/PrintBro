import SwiftUI

enum AppInfo {
    static let nombre = "PrintBro"
}

@main
struct PrintBroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        Window(AppInfo.nombre, id: "principal") {
            ContentView()
                .environment(delegate.modelo)
        }
        .defaultSize(width: 1080, height: 720)
        .commands { PrintBroCommands(modelo: delegate.modelo) }

        Window("Ayuda de PrintBro", id: "ayuda") {
            AyudaView()
        }
        .windowResizability(.contentSize)

        Settings {
            AjustesView()
                .environment(delegate.modelo)
        }
    }
}
