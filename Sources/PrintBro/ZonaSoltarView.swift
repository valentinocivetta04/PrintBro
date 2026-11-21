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
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(resaltada ? Color.accentColor : Color.secondary.opacity(0.4),
                              style: StrokeStyle(lineWidth: 2, dash: resaltada ? [] : [6]))
                .padding(20)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Zona para soltar un archivo"))
    }
}
