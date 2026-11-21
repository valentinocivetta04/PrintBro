import AppKit
import Foundation
import PDFKit
import Testing
@testable import PrintBroCore

/// PDF de prueba con el texto "Pag N" en cada página, para poder leer el orden después.
func pdfConPaginasNumeradas(_ cantidad: Int) throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("printbro-test-\(UUID().uuidString).pdf")
    var caja = CGRect(x: 0, y: 0, width: 595, height: 842)
    let contexto = try #require(CGContext(url as CFURL, mediaBox: &caja, nil))
    for numero in 1...cantidad {
        contexto.beginPDFPage(nil)
        NSGraphicsContext.current = NSGraphicsContext(cgContext: contexto, flipped: false)
        ("Pag \(numero)" as NSString).draw(at: CGPoint(x: 100, y: 400),
                                           withAttributes: [.font: NSFont.systemFont(ofSize: 40)])
        NSGraphicsContext.current = nil
        contexto.endPDFPage()
    }
    contexto.closePDF()
    return url
}

@Test func ordenDeOchoPaginas() {
    #expect(Folleto.orden(paginas: 8) == [8, 1, 2, 7, 6, 3, 4, 5])
}

@Test func ordenCompletaConBlancos() {
    // 5 páginas ocupan 2 hojas (8 lugares): los que faltan quedan en blanco.
    #expect(Folleto.orden(paginas: 5) == [nil, 1, 2, nil, nil, 3, 4, 5])
    #expect(Folleto.orden(paginas: 1) == [nil, 1, nil, nil])
    #expect(Folleto.orden(paginas: 0) == [])
}

@Test func folletoDeOchoPaginasTieneElOrdenCorrecto() throws {
    let original = try pdfConPaginasNumeradas(8)
    defer { try? FileManager.default.removeItem(at: original) }
    let datosOriginales = try Data(contentsOf: original)

    let folleto = try Folleto.generar(desde: original)
    defer { try? FileManager.default.removeItem(at: folleto) }

    // Es un temporal aparte y el original no cambió.
    #expect(folleto != original)
    #expect(folleto.path.hasPrefix(FileManager.default.temporaryDirectory.path))
    #expect(try Data(contentsOf: original) == datosOriginales)

    let pdf = try #require(PDFDocument(url: folleto))
    #expect(pdf.pageCount == 4)
    let caja = try #require(pdf.page(at: 0)).bounds(for: .mediaBox)
    #expect(caja.width == 1190 && caja.height == 842)

    // Cada cara tiene la página de la izquierda y la de la derecha, en ese orden.
    let esperado = [(8, 1), (2, 7), (6, 3), (4, 5)]
    for (indice, (izquierda, derecha)) in esperado.enumerated() {
        let cara = try #require(pdf.page(at: indice))
        let mitad = caja.width / 2
        let textoIzquierda = cara.selection(for: CGRect(x: 0, y: 0, width: mitad, height: caja.height))?.string ?? ""
        let textoDerecha = cara.selection(for: CGRect(x: mitad, y: 0, width: mitad, height: caja.height))?.string ?? ""
        #expect(textoIzquierda.contains("Pag \(izquierda)"), "cara \(indice + 1) izquierda: \(textoIzquierda)")
        #expect(textoDerecha.contains("Pag \(derecha)"), "cara \(indice + 1) derecha: \(textoDerecha)")
    }
}

@Test func folletoDeArchivoIlegibleDaError() {
    #expect(throws: PrintBroError.pdfIlegible) {
        try Folleto.generar(desde: URL(fileURLWithPath: "/tmp/no-existe-\(UUID().uuidString).pdf"))
    }
}

@Test func ajustarAPaginaMandaFitToPage() {
    var trabajo = PrintJob(archivo: URL(fileURLWithPath: "/tmp/a.pdf"), impresora: "B")
    trabajo.ajustarAPagina = true
    #expect(trabajo.argumentosLP().contains("fit-to-page"))
}
