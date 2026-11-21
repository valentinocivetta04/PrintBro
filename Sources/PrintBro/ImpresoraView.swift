import PrintBroCore
import SwiftUI

struct ImpresoraView: View {
    @Environment(PrintModel.self) private var modelo

    var body: some View {
        Group {
            if let impresora = modelo.impresoraActual {
                Form {
                    Section("Cola de impresión") {
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
                                Image(systemName: "exclamationmark.triangle.fill").symbolRenderingMode(.multicolor)
                            }
                        } else {
                            Label("El driver es de Brother.", systemImage: "checkmark.seal")
                        }
                    }

                    if let estado = modelo.estadoImpresora {
                        Section("Estado") {
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
                        }
                    }

                    Section("Opciones que ofrece el driver") {
                        ForEach(modelo.opciones, id: \.clave) { opcion in
                            LabeledContent(opcion.etiqueta) {
                                Text(opcion.valores.joined(separator: ", "))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Section {
                        Button("Volver a buscar impresoras") { modelo.recargarImpresoras() }
                    }
                }
                .formStyle(.grouped)
            } else {
                ContentUnavailableView {
                    Label("No hay impresoras", systemImage: "printer")
                } description: {
                    Text("Agregá la impresora en Configuración del Sistema > Impresoras y escáneres.")
                } actions: {
                    Button("Volver a buscar impresoras") { modelo.recargarImpresoras() }
                }
            }
        }
        // Se cancela sola al salir de la pantalla.
        .task { await modelo.refrescarMientrasSeVe(cada: 2) { modelo.actualizarEstado() } }
    }
}
