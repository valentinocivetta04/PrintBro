import PrintBroCore
import SwiftUI

/// Franja chica arriba de Imprimir con los avisos de la impresora (tóner bajo, sin papel...). No bloquea.
struct FranjaAvisosView: View {
    let motivos: [Motivo]

    var body: some View {
        VStack(alignment: .leading, spacing: Estilo.Espacio.chico / 2) {
            ForEach(Array(motivos.enumerated()), id: \.offset) { _, motivo in
                Label {
                    Text(motivo.titulo).fontWeight(.medium)
                        + Text(verbatim: " · ")
                        + Text(motivo.accion).foregroundStyle(Estilo.Paleta.textoAtenuado)
                } icon: {
                    Image(systemName: motivo.simbolo)
                        .foregroundStyle(Estilo.Paleta.acento)
                }
                .foregroundStyle(Estilo.Paleta.texto)
                .lineLimit(1)
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Estilo.Espacio.medio)
        .padding(.vertical, Estilo.Espacio.chico)
        .fondoEncabezado()
        .overlay(alignment: .bottom) { LineaBorde() }
    }
}
