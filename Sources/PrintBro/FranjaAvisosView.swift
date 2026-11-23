import PrintBroCore
import SwiftUI

/// Franja chica arriba de Imprimir con los avisos de la impresora (tóner bajo, sin papel...). No bloquea.
/// Amarilla si son advertencias; roja si alguno es un error.
struct FranjaAvisosView: View {
    let motivos: [Motivo]

    var body: some View {
        VStack(alignment: .leading, spacing: Estilo.Espacio.chico) {
            ForEach(Array(motivos.enumerated()), id: \.offset) { _, motivo in
                Label {
                    Text(motivo.titulo).fontWeight(.medium)
                        + Text(verbatim: " · ")
                        + Text(motivo.accion).foregroundStyle(Estilo.Paleta.textoAtenuado)
                } icon: {
                    Image(systemName: motivo.simbolo)
                        .foregroundStyle(motivo.gravedad == .error ? Estilo.Paleta.errorIcono : Estilo.Paleta.avisoIcono)
                }
                .foregroundStyle(Estilo.Paleta.texto)
                .lineLimit(1)
                .accessibilityElement(children: .combine)
            }
        }
        .cajaAviso(hayError ? Estilo.Paleta.peligro : Estilo.Paleta.aviso)
        .padding([.horizontal, .top], Estilo.Espacio.medio)
    }

    private var hayError: Bool {
        motivos.contains { $0.gravedad == .error }
    }
}
