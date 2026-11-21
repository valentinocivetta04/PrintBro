import SwiftUI

struct VistaPreviaView: View {
    let archivo: URL
    @Environment(PrintModel.self) private var modelo

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "doc")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text(archivo.lastPathComponent)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                if let paginas = modelo.paginasDocumento {
                    if paginas == 1 {
                        Text("1 página").foregroundStyle(.secondary)
                    } else {
                        Text("\(paginas) páginas").foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .accessibilityElement(children: .combine)

            Divider()

            contenido
        }
    }

    @ViewBuilder private var contenido: some View {
        switch archivo.pathExtension.lowercased() {
        case "pdf":
            PDFKitView(url: archivo)
                .accessibilityLabel(Text("Vista previa del PDF"))
        case "txt":
            ScrollView {
                Text((try? String(contentsOf: archivo, encoding: .utf8)) ?? "")
                    .font(.body.monospaced())
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .accessibilityLabel(Text("Vista previa del texto"))
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
