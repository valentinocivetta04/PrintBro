import AppKit
import UserNotifications

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    // Vive acá para que exista antes de que llegue un archivo abierto desde Finder.
    let modelo = PrintModel()

    override init() {
        // Acento violeta (5 = púrpura) para lo que pinta el sistema, como la selección de la
        // barra lateral, que no toma .tint. Se guarda en las preferencias de PrintBro, no en
        // las globales: el resto de la Mac sigue con su acento.
        UserDefaults.standard.set(5, forKey: "AppleAccentColor")
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        if let url = urls.first { modelo.abrir(url) }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        modelo.borrarTemporalesAlSalir()
    }

    // Sin esto, macOS no muestra la notificación si PrintBro está adelante.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
