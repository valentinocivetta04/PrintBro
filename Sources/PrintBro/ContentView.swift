import SwiftUI

struct ContentView: View {
    @Environment(PrintModel.self) private var modelo

    var body: some View {
        @Bindable var modelo = modelo
        NavigationSplitView {
            // Selección propia: la del sistema pinta texto oscuro sobre violeta oscuro (poco contraste).
            List(Seccion.allCases) { seccion in
                let elegida = modelo.seccion == seccion
                Button {
                    modelo.seccion = seccion
                } label: {
                    Label {
                        Text(seccion.titulo)
                    } icon: {
                        Image(systemName: seccion.simbolo)
                    }
                    .foregroundStyle(Estilo.Paleta.texto)
                    .padding(.horizontal, Estilo.Espacio.chico)
                    .frame(maxWidth: .infinity, minHeight: Estilo.Boton.altoCompacto, alignment: .leading)
                    .background {
                        if elegida {
                            RoundedRectangle(cornerRadius: Estilo.Radio.chip, style: .continuous)
                                .fill(Estilo.Paleta.primario.opacity(Estilo.Estado.opacidadSeleccion))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(elegida ? .isSelected : [])
            }
            .scrollContentBackground(.hidden)
            .fondoBarraLateral()
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
        } detail: {
            VStack(alignment: .leading, spacing: 0) {
                Text(modelo.seccion.titulo)
                    .tituloPantalla()
                    .padding(.horizontal, Estilo.Espacio.medio)
                    .padding(.top, Estilo.Espacio.chico)
                detalle
            }
            // Barra superior y contenido son una sola superficie: bg debajo de la barra del sistema
            // y una línea de borde de 1 pt entre las dos.
            .background { Estilo.Paleta.fondo.ignoresSafeArea() }
            .overlay(alignment: .top) { LineaBorde() }
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
        switch modelo.seccion {
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
