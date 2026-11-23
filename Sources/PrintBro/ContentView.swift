import SwiftUI

struct ContentView: View {
    @Environment(PrintModel.self) private var modelo

    var body: some View {
        @Bindable var modelo = modelo
        NavigationSplitView {
            List(Seccion.allCases, selection: $modelo.seccion) { seccion in
                Label {
                    Text(seccion.titulo)
                } icon: {
                    Image(systemName: seccion.simbolo)
                }
            }
            .scrollContentBackground(.hidden)
            .fondoBarraLateral()
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
        } detail: {
            VStack(alignment: .leading, spacing: 0) {
                Text((modelo.seccion ?? .imprimir).titulo)
                    .tituloPantalla()
                    .padding(.horizontal, Estilo.Espacio.medio)
                    .padding(.top, Estilo.Espacio.chico)
                detalle
            }
            // Debajo de la barra del sistema va el material propio; el resto es bg.
            .background {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 0).fondoEncabezado()
                    LineaBorde()
                    Estilo.Paleta.fondo
                }
            }
            .toolbarBackground(.hidden, for: .windowToolbar)
        }
        .navigationTitle("PrintBro")
        .fileImporter(isPresented: $modelo.mostrarImportador,
                      allowedContentTypes: [.pdf, .png, .jpeg, .heic, .plainText]) { resultado in
            if case .success(let url) = resultado { modelo.abrir(url) }
        }
        .alert("No se pudo completar", isPresented: hayError) {
            Button("Aceptar") {}
        } message: {
            Text(modelo.mensajeError ?? "")
        }
    }

    @ViewBuilder private var detalle: some View {
        switch modelo.seccion ?? .imprimir {
        case .imprimir: ImprimirView()
        case .historial: HistorialView()
        case .cola: ColaView()
        case .impresora: ImpresoraView()
        }
    }

    private var hayError: Binding<Bool> {
        Binding(get: { modelo.mensajeError != nil },
                set: { if !$0 { modelo.mensajeError = nil } })
    }
}
