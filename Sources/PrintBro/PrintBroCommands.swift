import SwiftUI

struct PrintBroCommands: Commands {
    let modelo: PrintModel
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Abrir…") { modelo.pedirArchivo() }
                .keyboardShortcut("o")
        }
        CommandGroup(replacing: .printItem) {
            Button("Imprimir") { modelo.imprimir() }
                .keyboardShortcut("p")
                .disabled(!modelo.puedeImprimir)
        }
        CommandGroup(replacing: .help) {
            Button("Ayuda de PrintBro") { openWindow(id: "ayuda") }
                .keyboardShortcut("?")
        }
    }
}
