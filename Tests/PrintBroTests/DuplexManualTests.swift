import CoreGraphics
import Foundation
import Testing
@testable import PrintBroCore

private func preparar(paginas: Int, defaults: UserDefaults = nuevosDefaults()) throws -> (DuplexManual, FakeRunner) {
    let runner = FakeRunner()
    let trabajo = PrintJob(archivo: URL(fileURLWithPath: "/tmp/doc.pdf"), impresora: "B")
    let duplex = try DuplexManual(trabajo: trabajo, paginas: paginas,
                                  servicio: PrinterService(runner: runner), defaults: defaults)
    return (duplex, runner)
}

private func nuevosDefaults() -> UserDefaults {
    UserDefaults(suiteName: "printbro.tests.\(UUID().uuidString)")!
}

@Test func flujoCompletoPar() throws {
    let (duplex, runner) = try preparar(paginas: 4)
    #expect(duplex.estado == .idle)
    try duplex.empezar()
    #expect(duplex.estado == .esperandoGiro(aviso: nil))
    #expect(runner.llamadas[0].argumentos == ["-d", "B", "-o", "page-set=odd", "/tmp/doc.pdf"])
    try duplex.continuar()
    #expect(duplex.estado == .listo)
    #expect(runner.llamadas[1].argumentos ==
        ["-d", "B", "-o", "page-set=even", "-o", "outputorder=reverse", "/tmp/doc.pdf"])
}

@Test func impar_avisaHojaSinDorso() throws {
    let (duplex, _) = try preparar(paginas: 5)
    try duplex.empezar()
    guard case .esperandoGiro(let aviso) = duplex.estado else {
        Issue.record("estado inesperado: \(duplex.estado)")
        return
    }
    #expect(aviso == "El documento tiene 5 páginas: la última hoja va a quedar sin dorso.")
}

@Test func unaSolaPaginaTerminaSinGiro() throws {
    let (duplex, runner) = try preparar(paginas: 1)
    try duplex.empezar()
    #expect(duplex.estado == .listo)
    #expect(runner.llamadas.count == 1)
}

@Test func cancelarEsperandoGiroNoImprimePares() throws {
    let (duplex, runner) = try preparar(paginas: 4)
    try duplex.empezar()
    duplex.cancelar()
    #expect(duplex.estado == .cancelado)
    #expect(throws: PrintBroError.estadoInvalido) { try duplex.continuar() }
    #expect(runner.llamadas.count == 1)
}

@Test func cancelarAntesDeEmpezar() throws {
    let (duplex, runner) = try preparar(paginas: 4)
    duplex.cancelar()
    #expect(duplex.estado == .cancelado)
    #expect(throws: PrintBroError.estadoInvalido) { try duplex.empezar() }
    #expect(runner.llamadas.isEmpty)
}

@Test func cancelarDespuesDeListoNoCambiaNada() throws {
    let (duplex, _) = try preparar(paginas: 2)
    try duplex.empezar()
    try duplex.continuar()
    duplex.cancelar()
    #expect(duplex.estado == .listo)
}

@Test func sinOrdenInversoNoMandaOutputorder() throws {
    let (duplex, runner) = try preparar(paginas: 2)
    duplex.ordenInverso = false
    try duplex.empezar()
    try duplex.continuar()
    #expect(!runner.llamadas[1].argumentos.contains("outputorder=reverse"))
}

@Test func ordenInversoSeRecuerda() throws {
    let defaults = nuevosDefaults()
    let (primero, _) = try preparar(paginas: 2, defaults: defaults)
    #expect(primero.ordenInverso == true)
    primero.ordenInverso = false
    let (segundo, _) = try preparar(paginas: 2, defaults: defaults)
    #expect(segundo.ordenInverso == false)
}

@Test func falloEnParesPermiteReintentar() throws {
    let (duplex, runner) = try preparar(paginas: 3)
    try duplex.empezar()
    runner.respuesta = CommandResult(status: 1, error: "sin conexión")
    #expect(throws: PrintBroError.comandoFallo("sin conexión")) { try duplex.continuar() }
    guard case .esperandoGiro = duplex.estado else {
        Issue.record("debería seguir esperando el giro")
        return
    }
    runner.respuesta = CommandResult()
    try duplex.continuar()
    #expect(duplex.estado == .listo)
}

@Test func falloEnImparesVuelveAIdle() throws {
    let (duplex, runner) = try preparar(paginas: 2)
    runner.respuesta = CommandResult(status: 1, error: "x")
    #expect(throws: PrintBroError.comandoFallo("x")) { try duplex.empezar() }
    #expect(duplex.estado == .idle)
}

@Test func rechazaNoPDFyRango() throws {
    let servicio = PrinterService(runner: FakeRunner())
    let imagen = PrintJob(archivo: URL(fileURLWithPath: "/tmp/foto.png"), impresora: "B")
    #expect(throws: PrintBroError.duplexSoloPDF) {
        try DuplexManual(trabajo: imagen, paginas: 1, servicio: servicio)
    }
    var conRango = PrintJob(archivo: URL(fileURLWithPath: "/tmp/a.pdf"), impresora: "B")
    conRango.rangoPaginas = "1-2"
    #expect(throws: PrintBroError.duplexConRango) {
        try DuplexManual(trabajo: conRango, paginas: 4, servicio: servicio)
    }
}

@Test func cuentaPaginasConPDFKit() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("printbro-\(UUID().uuidString).pdf")
    defer { try? FileManager.default.removeItem(at: url) }
    var caja = CGRect(x: 0, y: 0, width: 595, height: 842)
    let contexto = try #require(CGContext(url as CFURL, mediaBox: &caja, nil))
    for _ in 0..<3 {
        contexto.beginPDFPage(nil)
        contexto.endPDFPage()
    }
    contexto.closePDF()
    #expect(try DuplexManual.contarPaginas(url) == 3)
}

@Test func pdfIlegibleDaError() {
    #expect(throws: PrintBroError.pdfIlegible) {
        try DuplexManual.contarPaginas(URL(fileURLWithPath: "/tmp/no-existe-\(UUID().uuidString).pdf"))
    }
}
