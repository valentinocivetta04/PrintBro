import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    // Vive acá para que exista antes de que llegue un archivo abierto desde Finder.
    let modelo = PrintModel()

    func application(_ application: NSApplication, open urls: [URL]) {
        if let url = urls.first { modelo.abrir(url) }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
