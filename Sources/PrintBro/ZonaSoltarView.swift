import SwiftUI

struct ZonaSoltarView: View {
    let resaltada: Bool
    @Environment(PrintModel.self) private var modelo

    var body: some View {
        ContentUnavailableView {
            Label("Soltá un archivo acá", systemImage: "doc.viewfinder")
        } description: {
            Text("PDF, imagen (PNG, JPG, HEIC) o texto plano.")
        } actions: {
            Button("Elegir archivo…") { modelo.pedirArchivo() }
                .accessibilityHint(Text("Abre el selector de archivos"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            let forma = RoundedRectangle(cornerRadius: Estilo.Radio.tarjeta, style: .continuous)
            forma
                .fill(resaltada ? Color.accentColor.opacity(0.08) : Color.clear)
                .overlay {
                    forma.strokeBorder(resaltada ? Color.accentColor : Color.secondary.opacity(0.4),
                                       style: StrokeStyle(lineWidth: 2, dash: resaltada ? [] : [6]))
                }
                .padding(Estilo.Espacio.grande)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Zona para soltar un archivo"))
    }
}
