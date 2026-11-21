import SwiftUI

struct ImpresoraView: View {
    @Environment(PrintModel.self) private var modelo

    var body: some View {
        if let impresora = modelo.impresoraActual {
            Form {
                Section("Cola de impresión") {
                    LabeledContent("Nombre", value: impresora.nombre)
                    LabeledContent("Driver", value: impresora.marcaYModelo)
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
}
