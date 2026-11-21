import PrintBroCore
import SwiftUI

/// Franja chica arriba de Imprimir con los avisos de la impresora (tóner bajo, sin papel...). No bloquea.
struct FranjaAvisosView: View {
    let motivos: [Motivo]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(motivos.enumerated()), id: \.offset) { _, motivo in
                Label {
                    Text(motivo.titulo).fontWeight(.medium)
                        + Text(verbatim: " · ")
                        + Text(motivo.accion).foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: motivo.simbolo)
                        .foregroundStyle(motivo.gravedad == .error ? Color.red : Color.orange)
                }
                .font(.callout)
                .lineLimit(1)
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.bar)
        .overlay(alignment: .bottom) { Divider() }
    }
}
