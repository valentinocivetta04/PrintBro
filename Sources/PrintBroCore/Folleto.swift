import Foundation
import PDFKit

/// Folleto: hojas impresas de los dos lados, con dos páginas por cara, que se doblan al medio.
public enum Folleto {
    /// Orden de las páginas (desde 1; nil es un lugar en blanco), de a dos por cara.
    /// Para 8 páginas: 8 1 | 2 7 | 6 3 | 4 5.
    public static func orden(paginas: Int) -> [Int?] {
        guard paginas > 0 else { return [] }
        // Cada hoja lleva 4 páginas: se completa con blancos hasta un múltiplo de 4.
        let total = (paginas + 3) / 4 * 4
        var orden: [Int] = []
        for i in stride(from: 0, to: total / 2, by: 2) {
            orden += [total - i, i + 1, i + 2, total - i - 1]
        }
        return orden.map { $0 <= paginas ? $0 : nil }
    }

    /// Arma el PDF del folleto en un archivo temporal (nunca toca el original).
    /// Cada cara es apaisada y del doble de ancho que una página. Quien llama borra el archivo.
    public static func generar(desde url: URL) throws -> URL {
        guard let pdf = PDFDocument(url: url), pdf.pageCount > 0,
              let primera = pdf.page(at: 0)
        else { throw PrintBroError.pdfIlegible }
        let tamanio = primera.bounds(for: .mediaBox).size
        var caja = CGRect(x: 0, y: 0, width: tamanio.width * 2, height: tamanio.height)
        let destino = FileManager.default.temporaryDirectory
            .appendingPathComponent("PrintBro-folleto-\(UUID().uuidString).pdf")
        guard let contexto = CGContext(destino as CFURL, mediaBox: &caja, nil) else {
            throw PrintBroError.pdfIlegible
        }
        let orden = orden(paginas: pdf.pageCount)
        for cara in stride(from: 0, to: orden.count, by: 2) {
            contexto.beginPDFPage(nil)
            for (lado, numero) in [orden[cara], orden[cara + 1]].enumerated() {
                guard let numero, let pagina = pdf.page(at: numero - 1) else { continue }
                let bordes = pagina.bounds(for: .mediaBox)
                // Si una página tiene otro tamaño, se achica para que entre en su mitad.
                let escala = min(tamanio.width / bordes.width, tamanio.height / bordes.height)
                contexto.saveGState()
                contexto.translateBy(x: CGFloat(lado) * tamanio.width, y: 0)
                contexto.scaleBy(x: escala, y: escala)
                pagina.draw(with: .mediaBox, to: contexto)
                contexto.restoreGState()
            }
            contexto.endPDFPage()
        }
        contexto.closePDF()
        return destino
    }
}
