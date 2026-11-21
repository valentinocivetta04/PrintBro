import SwiftUI

// La lista de trabajos necesita leer la cola desde PrintBroCore (cupsGetJobs2); queda para otra parte.
struct ColaView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Todavía no hay vista de la cola", systemImage: "tray.full")
        } description: {
            Text("Por ahora podés ver los trabajos en Configuración del Sistema > Impresoras y escáneres.")
        }
    }
}
