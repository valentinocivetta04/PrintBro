import Foundation
import Testing
@testable import PrintBroCore

private func historialVacio() -> HistorialStore {
    HistorialStore(defaults: UserDefaults(suiteName: "printbro.tests.\(UUID().uuidString)")!)
}

private func entrada(_ numero: Int) -> EntradaHistorial {
    EntradaHistorial(archivo: URL(fileURLWithPath: "/tmp/doc\(numero).pdf"),
                     fecha: Date(timeIntervalSince1970: Double(numero)),
                     configuracion: Configuracion())
}

@Test func historialGuardaElMasNuevoPrimero() throws {
    let historial = historialVacio()
    try historial.agregar(entrada(1))
    try historial.agregar(entrada(2))
    #expect(historial.todas().map(\.archivo.lastPathComponent) == ["doc2.pdf", "doc1.pdf"])
}

@Test func historialSeQuedaConLosUltimos20() throws {
    let historial = historialVacio()
    for numero in 1...25 { try historial.agregar(entrada(numero)) }
    let todas = historial.todas()
    #expect(todas.count == 20)
    #expect(todas.first?.archivo.lastPathComponent == "doc25.pdf")
    #expect(todas.last?.archivo.lastPathComponent == "doc6.pdf")
}

@Test func historialConservaLasOpciones() throws {
    let historial = historialVacio()
    var c = Configuracion()
    c.copias = 2
    c.rangoPaginas = "1-3"
    c.tamanioPapel = "A4"
    c.dobleFaz = true
    try historial.agregar(EntradaHistorial(archivo: URL(fileURLWithPath: "/tmp/a.pdf"), configuracion: c))
    let guardada = try #require(historial.todas().first)
    #expect(guardada.configuracion == c)
    #expect(guardada.resumen == "2 copias · páginas 1-3 · A4 · doble faz")
}

@Test func resumenDeFolleto() {
    var c = Configuracion()
    c.dobleFaz = true
    c.folleto = true
    let e = EntradaHistorial(archivo: URL(fileURLWithPath: "/tmp/a.pdf"), configuracion: c)
    #expect(e.resumen == "1 copia · folleto")
}
