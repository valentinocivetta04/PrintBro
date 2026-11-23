import PrintBroCore
import SwiftUI

/// Un aviso de la impresora: ícono + título + acción sugerida (nunca solo color).
struct MotivoView: View {
    let motivo: Motivo

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(motivo.titulo).fontWeight(.medium)
                Text(motivo.accion)
                    .textoAtenuado()
            }
        } icon: {
            Image(systemName: motivo.simbolo)
                .foregroundStyle(Estilo.Paleta.acento)
        }
        .accessibilityElement(children: .combine)
    }
}
