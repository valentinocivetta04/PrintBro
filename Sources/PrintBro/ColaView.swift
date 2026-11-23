import PrintBroCore
import SwiftUI

struct ColaView: View {
    @Environment(PrintModel.self) private var modelo

    var body: some View {
        @Bindable var modelo = modelo
        Group {
            if modelo.trabajosCola.isEmpty {
                ContentUnavailableView {
                    Label("No hay trabajos en la cola", systemImage: "tray")
                } description: {
                    Text("Cuando mandes algo a imprimir, va a aparecer acá hasta que termine.").textoAtenuado()
                }
            } else {
                Table(modelo.trabajosCola, selection: $modelo.seleccionCola) {
                    TableColumn("N.º") { trabajo in
                        Text(trabajo.id, format: .number)
                    }
                    .width(50)
                    TableColumn("Archivo") { trabajo in
                        Text(trabajo.archivo).lineLimit(1).truncationMode(.middle)
                    }
                    TableColumn("Estado") { trabajo in
                        Label(trabajo.estado.titulo, systemImage: trabajo.estado.simbolo)
                    }
                    .width(140)
                    TableColumn("Fecha") { trabajo in
                        Text(trabajo.fecha, format: .dateTime.day().month().hour().minute().second())
                    }
                    .width(150)
                }
                .scrollContentBackground(.hidden)
                .clipShape(RoundedRectangle(cornerRadius: Estilo.Radio.tarjeta, style: .continuous))
                .panel()
                .padding(Estilo.Espacio.medio)
            }
        }
        // Sin esto el estado vacío no ocupa todo el alto y la barra queda en el medio.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack {
                Text("Se actualiza cada 2 segundos.")
                    .textoAtenuado()
                Spacer()
                Button("Cancelar trabajo") { modelo.cancelarSeleccionados() }
                    .disabled(modelo.seleccionCola.isEmpty)
                    .accessibilityHint(Text("Cancela los trabajos seleccionados"))
                    .buttonStyle(.secundario)
                Button("Cancelar todos", role: .destructive) { modelo.confirmandoCancelarTodos = true }
                    .disabled(modelo.trabajosCola.isEmpty)
                    .buttonStyle(.secundario)
            }
            .padding(.horizontal, Estilo.Espacio.medio)
            .padding(.vertical, Estilo.Espacio.chico)
            .fondoEncabezado()
            .overlay(alignment: .top) { LineaBorde() }
        }
        .confirmationDialog("¿Cancelar todos los trabajos de la cola?", isPresented: $modelo.confirmandoCancelarTodos) {
            Button("Cancelar todos", role: .destructive) { modelo.cancelarTodos() }
            Button("No", role: .cancel) {}
        } message: {
            Text("Se cancelan también los trabajos que no mandaste desde PrintBro.")
        }
        // Consulta solo mientras la pantalla se ve: SwiftUI cancela la tarea al salir.
        .task { await modelo.refrescarMientrasSeVe(cada: 2) { modelo.actualizarCola() } }
    }
}
