import PrintBroCore
import SwiftUI

/// Un aviso de la impresora: ícono + título + acción sugerida (nunca solo color).
struct MotivoView: View {
    let motivo: Motivo

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 0) {
                Text(motivo.titulo).fontWeight(.medium)
                Text(motivo.accion)
                    .textoAtenuado()
            }
        } icon: {
            Image(systemName: motivo.simbolo)
                .foregroundStyle(esError ? Estilo.Paleta.errorIcono : Estilo.Paleta.avisoIcono)
        }
        .accessibilityElement(children: .combine)
        .filaAviso(esError ? Estilo.Paleta.peligro : Estilo.Paleta.aviso)
    }

    private var esError: Bool {
        motivo.gravedad == .error
    }
}
