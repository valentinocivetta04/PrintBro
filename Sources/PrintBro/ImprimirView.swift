import SwiftUI

struct ImprimirView: View {
    @Environment(PrintModel.self) private var modelo

    var body: some View {
        HStack(spacing: Estilo.Espacio.medio) {
            Group {
                if let archivo = modelo.archivo {
                    VistaPreviaView(archivo: archivo)
                } else {
                    ZonaSoltarView(resaltada: modelo.arrastrandoEncima)
                }
            }
            .frame(minWidth: 380, maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: Estilo.Radio.tarjeta, style: .continuous))
            .panel()
            .dropDestination(for: URL.self) { urls, _ in
                guard let url = urls.first else { return false }
                modelo.abrir(url)
                return true
            } isTargeted: { modelo.arrastrandoEncima = $0 }

            OpcionesView()
                .frame(width: 350)
                .clipShape(RoundedRectangle(cornerRadius: Estilo.Radio.tarjeta, style: .continuous))
                .panel()
        }
        .padding(Estilo.Espacio.medio)
        .safeAreaInset(edge: .top, spacing: 0) {
            if let motivos = modelo.estadoImpresora?.motivos, !motivos.isEmpty {
                FranjaAvisosView(motivos: motivos)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BarraImpresionView()
        }
        // El estado cambia poco: cada 10 segundos alcanza, y solo mientras se ve la pantalla.
        .task { await modelo.refrescarMientrasSeVe(cada: 10) { modelo.actualizarEstado() } }
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
