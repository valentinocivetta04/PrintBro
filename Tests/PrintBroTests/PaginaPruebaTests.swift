import Foundation
import PDFKit
import Testing
@testable import PrintBroCore

@Test func paginaDePruebaTieneImpresoraYFecha() throws {
    let fecha = Date(timeIntervalSince1970: 1_795_294_781)
    let url = try PaginaPrueba.generar(impresora: "Brother_HL_1210W_series", fecha: fecha)
    defer { try? FileManager.default.removeItem(at: url) }

    #expect(url.path.hasPrefix(FileManager.default.temporaryDirectory.path))
    let pdf = try #require(PDFDocument(url: url))
    #expect(pdf.pageCount == 1)
    let texto = try #require(pdf.page(at: 0)?.string)
    // PDFKit extrae "_" en otra línea y cambia los espacios de la fecha: se comparan letras y números.
    func soloLetrasYNumeros(_ s: String) -> String { s.filter { $0.isLetter || $0.isNumber } }
    let extraido = soloLetrasYNumeros(texto)
    #expect(extraido.contains(soloLetrasYNumeros("Página de prueba de PrintBro")))
    #expect(extraido.contains(soloLetrasYNumeros("Brother_HL_1210W_series")))
    #expect(extraido.contains(soloLetrasYNumeros(fecha.formatted(date: .long, time: .shortened))))
}

