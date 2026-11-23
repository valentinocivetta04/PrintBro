import PrintBroCore
import SwiftUI

struct HistorialView: View {
    @Environment(PrintModel.self) private var modelo

    var body: some View {
        if modelo.historial.isEmpty {
            ContentUnavailableView {
                Label("Todavía no hay trabajos", systemImage: "clock.arrow.circlepath")
            } description: {
                Text("Acá vas a ver los últimos 20 trabajos que mandes desde PrintBro.").textoAtenuado()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: Estilo.Espacio.chico) {
                    ForEach(modelo.historial) { entrada in
                        fila(entrada)
                    }
                }
                .padding(Estilo.Espacio.medio)
            }
        }
    }

    private func fila(_ entrada: EntradaHistorial) -> some View {
        HStack(spacing: Estilo.Espacio.medio) {
            Image(systemName: "doc")
                .textoAtenuado()
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(entrada.archivo.lastPathComponent)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(entrada.fecha, format: .dateTime.day().month().year().hour().minute())
                    .textoAtenuado()
                Text(entrada.resumen)
                    .textoAtenuado()
            }
            Spacer()
            Button("Reimprimir") { modelo.reimprimir(entrada) }
                .disabled(modelo.ocupado || modelo.mostrandoGiro)
                .accessibilityLabel(Text("Reimprimir \(entrada.archivo.lastPathComponent)"))
                .buttonStyle(.primario)
        }
        .tarjeta()
        .accessibilityElement(children: .combine)
    }
}
