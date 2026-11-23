import SwiftUI

@main
struct PrintBroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        Window("PrintBro", id: "principal") {
            ContentView()
                .environment(delegate.modelo)
                .estiloApp()
        }
        .defaultSize(width: 1080, height: 720)
        .commands { PrintBroCommands(modelo: delegate.modelo) }

        Window("Ayuda de PrintBro", id: "ayuda") {
            AyudaView()
                .estiloApp()
        }
        .windowResizability(.contentSize)

        Settings {
            AjustesView()
                .environment(delegate.modelo)
                .estiloApp()
        }
    }
}
