import SwiftUI

struct ImprimirView: View {
    @Environment(PrintModel.self) private var modelo

    var body: some View {
        HStack(spacing: 0) {
            Group {
                if let archivo = modelo.archivo {
                    VistaPreviaView(archivo: archivo)
                } else {
                    ZonaSoltarView(resaltada: modelo.arrastrandoEncima)
                }
            }
            .frame(minWidth: 380, maxWidth: .infinity, maxHeight: .infinity)
            .dropDestination(for: URL.self) { urls, _ in
                guard let url = urls.first else { return false }
                modelo.abrir(url)
                return true
            } isTargeted: { modelo.arrastrandoEncima = $0 }

            Divider()

            OpcionesView()
                .frame(width: 350)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BarraImpresionView()
        }
        .sheet(isPresented: mostrandoGiro) {
            GiroHojasSheet()
                .interactiveDismissDisabled()
        }
        .toolbar {
            ToolbarItem {
                Button {
                    modelo.pedirArchivo()
                } label: {
                    Label("Elegir archivo…", systemImage: "doc.badge.plus")
                }
                .help("Elegir archivo… (⌘O)")
            }
        }
    }

    private var mostrandoGiro: Binding<Bool> {
        Binding(get: { modelo.mostrandoGiro },
                set: { if !$0 && modelo.mostrandoGiro { modelo.cancelarDuplex() } })
    }
}
