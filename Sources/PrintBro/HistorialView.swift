import PrintBroCore
import SwiftUI

struct HistorialView: View {
    @Environment(PrintModel.self) private var modelo

    var body: some View {
        if modelo.historial.isEmpty {
            ContentUnavailableView {
                Label("Todavía no hay trabajos", systemImage: "clock.arrow.circlepath")
            } description: {
                Text("Acá vas a ver los últimos 20 trabajos que mandes desde PrintBro.")
            }
        } else {
            List(modelo.historial) { entrada in
                HStack(spacing: 12) {
                    Image(systemName: "doc")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entrada.archivo.lastPathComponent)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Text(entrada.fecha, format: .dateTime.day().month().year().hour().minute())
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Text(entrada.resumen)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Reimprimir") { modelo.reimprimir(entrada) }
                        .disabled(modelo.ocupado || modelo.mostrandoGiro)
                        .accessibilityLabel(Text("Reimprimir \(entrada.archivo.lastPathComponent)"))
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
            }
        }
    }
}
