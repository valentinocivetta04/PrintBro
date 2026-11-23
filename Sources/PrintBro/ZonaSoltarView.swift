import SwiftUI

struct ZonaSoltarView: View {
    let resaltada: Bool
    @Environment(PrintModel.self) private var modelo

    var body: some View {
        ContentUnavailableView {
            Label("Soltá un archivo acá", systemImage: "doc.viewfinder")
        } description: {
            Text("PDF, imagen (PNG, JPG, HEIC) o texto plano.").textoAtenuado()
        } actions: {
            Button("Elegir archivo…") { modelo.pedirArchivo() }
                .buttonStyle(.primario)
                .accessibilityHint(Text("Abre el selector de archivos"))
        }
        .foregroundStyle(Estilo.Paleta.texto)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            let forma = RoundedRectangle(cornerRadius: Estilo.Radio.tarjeta, style: .continuous)
            forma
                .fill(resaltada ? Estilo.Paleta.superficieFuerte : Estilo.Paleta.superficie)
                .overlay {
                    forma.strokeBorder(resaltada ? Estilo.Paleta.primario : Estilo.Paleta.textoAtenuado,
                                       style: StrokeStyle(lineWidth: 2, dash: resaltada ? [] : [6]))
                }
                .padding(Estilo.Espacio.grande)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Zona para soltar un archivo"))
    }
}
