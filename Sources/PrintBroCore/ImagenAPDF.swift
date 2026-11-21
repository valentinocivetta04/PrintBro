import AppKit
import PDFKit

/// CUPS no reconoce HEIC en esta Mac (cupsfilter: "no se ha podido determinar el tipo MIME").
/// Por eso todas las imágenes se pasan a un PDF temporal y se imprimen con fit-to-page.
public enum ImagenAPDF {
    public static let extensiones: Set<String> = ["png", "jpg", "jpeg", "heic"]

    public static func esImagen(_ url: URL) -> Bool {
        extensiones.contains(url.pathExtension.lowercased())
    }

    /// Devuelve un PDF temporal de una página con la imagen. Quien llama lo borra.
    public static func convertir(_ url: URL) throws -> URL {
        guard let imagen = NSImage(contentsOf: url), let pagina = PDFPage(image: imagen) else {
            throw PrintBroError.imagenIlegible
        }
        let documento = PDFDocument()
        documento.insert(pagina, at: 0)
        let destino = FileManager.default.temporaryDirectory
            .appendingPathComponent("PrintBro-imagen-\(UUID().uuidString).pdf")
        guard documento.write(to: destino) else { throw PrintBroError.imagenIlegible }
        return destino
    }
}
