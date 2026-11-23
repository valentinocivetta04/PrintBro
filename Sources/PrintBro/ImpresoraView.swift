import PrintBroCore
import SwiftUI

struct ImpresoraView: View {
    @Environment(PrintModel.self) private var modelo

    var body: some View {
        @Bindable var modelo = modelo
        Group {
            if let impresora = modelo.impresoraActual {
                Form {
                    Section {
                        LabeledContent("Nombre", value: impresora.nombre)
                        LabeledContent("Driver", value: impresora.marcaYModelo)
                        if let estado = modelo.estadoImpresora {
                            LabeledContent("Conexión") {
                                Text(estado.uri)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .textSelection(.enabled)
                            }
                        }
                        LabeledContent("Predeterminada del sistema") {
                            if impresora.predeterminada { Text("Sí") } else { Text("No") }
                        }
                        if let aviso = modelo.avisoDriver {
                            Label {
                                Text(aviso)
                            } icon: {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Estilo.Paleta.acento)
                            }
                        } else {
                            Label("El driver es de Brother.", systemImage: "checkmark.seal")
                        }
                    } header: {
                        Text("Cola de impresión").etiquetaSeccion()
                    }
                    .filaSuperficie()

                    if let estado = modelo.estadoImpresora {
                        Section {
                            LabeledContent("Estado") {
                                Label(estado.general.titulo, systemImage: estado.general.simbolo)
                            }
                            if !estado.aceptaTrabajos {
                                Label("La cola no está aceptando trabajos.", systemImage: "hand.raised")
                            }
                            if estado.motivos.isEmpty {
                                Label("Sin avisos.", systemImage: "checkmark.circle")
                            }
                            ForEach(Array(estado.motivos.enumerated()), id: \.offset) { _, motivo in
                                MotivoView(motivo: motivo)
                            }
                        } header: {
                            Text("Estado").etiquetaSeccion()
                        }
                        .filaSuperficie()
                    }

                    Section {
                        HStack {
                            Button("Imprimir página de prueba") { modelo.confirmandoPaginaPrueba = true }
                                .disabled(modelo.imprimiendoPaginaPrueba)
                                .buttonStyle(.secundario)
                            if modelo.imprimiendoPaginaPrueba { ProgressView().controlSize(.small) }
                        }
                        Button("Volver a buscar impresoras") { modelo.recargarImpresoras() }
                            .buttonStyle(.secundario)
                    }
                    .filaSuperficie()
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
                .alert("¿Imprimir una página de prueba?", isPresented: $modelo.confirmandoPaginaPrueba) {
                    Button("Imprimir") { modelo.imprimirPaginaPrueba() }
                    Button("Cancelar", role: .cancel) {}
                } message: {
                    Text("Sale una sola hoja con el nombre de la impresora y la fecha.")
                }
            } else {
                ContentUnavailableView {
                    Label("No hay impresoras", systemImage: "printer")
                } description: {
                    Text("Agregá la impresora en Configuración del Sistema > Impresoras y escáneres.").textoAtenuado()
                } actions: {
                    Button("Volver a buscar impresoras") { modelo.recargarImpresoras() }
                        .buttonStyle(.primario)
                }
            }
        }
        // Se cancela sola al salir de la pantalla.
        .task { await modelo.refrescarMientrasSeVe(cada: 2) { modelo.actualizarEstado() } }
    }
}
