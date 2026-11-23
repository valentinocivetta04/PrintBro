import SwiftUI

struct VistaPreviaView: View {
    let archivo: URL
    @Environment(PrintModel.self) private var modelo

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Estilo.Espacio.chico) {
                Image(systemName: "doc")
                    .textoAtenuado()
                    .accessibilityHidden(true)
                Text(archivo.lastPathComponent)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                if let paginas = modelo.paginasDocumento {
                    if paginas == 1 {
                        Text("1 página").textoAtenuado()
                    } else {
                        Text("\(paginas) páginas").textoAtenuado()
                    }
                }
            }
            .padding(.horizontal, Estilo.Espacio.medio)
            .padding(.vertical, Estilo.Espacio.chico)
            .fondoEncabezado()
            .accessibilityElement(children: .combine)

            LineaBorde()

            contenido
        }
    }

    @ViewBuilder private var contenido: some View {
        switch archivo.pathExtension.lowercased() {
        case "pdf":
            PDFKitView(url: archivo)
                .accessibilityLabel(Text("Vista previa del PDF"))
        case "txt":
            // Si no es UTF-8 (o no se puede leer) se avisa en vez de mostrar una vista vacía.
            if let texto = try? String(contentsOf: archivo, encoding: .utf8) {
                ScrollView {
                    Text(texto)
                        .font(Estilo.Tipo.cuerpo.monospaced())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .accessibilityLabel(Text("Vista previa del texto"))
            } else {
                ContentUnavailableView("No se pudo mostrar la vista previa", systemImage: "eye.slash",
                                       description: Text("No se pudo leer el archivo como texto UTF-8.").foregroundStyle(Estilo.Paleta.textoAtenuado))
            }
        default:
            if let imagen = NSImage(contentsOf: archivo) {
                Image(nsImage: imagen)
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .accessibilityLabel(Text("Vista previa de la imagen"))
            } else {
                ContentUnavailableView("No se pudo mostrar la vista previa", systemImage: "eye.slash")
            }
        }
    }
}
