import AppKit
import Foundation

/// Una hoja A4 con el nombre de la impresora y la fecha, para probar que imprime.
public enum PaginaPrueba {
    /// Arma el PDF en un archivo temporal. Quien llama lo borra.
    public static func generar(impresora: String, fecha: Date = Date()) throws -> URL {
        let destino = FileManager.default.temporaryDirectory
            .appendingPathComponent("PrintBro-prueba-\(UUID().uuidString).pdf")
        var caja = CGRect(x: 0, y: 0, width: 595, height: 842)  // A4 en puntos
        guard let contexto = CGContext(destino as CFURL, mediaBox: &caja, nil) else {
            throw PrintBroError.pdfIlegible
        }
        let lineas: [(String, CGFloat)] = [
            (String(localized: "Página de prueba de PrintBro"), 30),
            (impresora, 20),
            (fecha.formatted(date: .long, time: .shortened), 16),
        ]
        contexto.beginPDFPage(nil)
        NSGraphicsContext.current = NSGraphicsContext(cgContext: contexto, flipped: false)
        var y: CGFloat = 760
        for (texto, tamanio) in lineas {
            (texto as NSString).draw(at: CGPoint(x: 72, y: y), withAttributes: [.font: NSFont.systemFont(ofSize: tamanio)])
            y -= tamanio + 24
        }
        // Un marco para ver si el papel sale derecho y con los márgenes bien.
        contexto.setLineWidth(1)
        contexto.stroke(caja.insetBy(dx: 36, dy: 36))
        NSGraphicsContext.current = nil
        contexto.endPDFPage()
        contexto.closePDF()
        return destino
    }
}
