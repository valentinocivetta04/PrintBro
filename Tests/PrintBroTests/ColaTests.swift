import Foundation
import Testing
@testable import PrintBroCore

// Trabajo real leído con cupsGetJobs2 en esta Mac (2026-11-21): la hoja de prueba de number-up.
let trabajoReal = TrabajoCola(id: 8, impresora: "Brother_HL_1210W_series",
                              archivo: "prueba number-up 4 páginas.pdf", estadoIPP: 9, creacion: 1_795_294_781)

@Test func trabajoRealTerminado() {
    #expect(trabajoReal.estado == .completado)
    #expect(trabajoReal.estado.terminado)
    #expect(trabajoReal.fecha == Date(timeIntervalSince1970: 1_795_294_781))
}

@Test(arguments: [
    (3, EstadoTrabajo.pendiente), (4, .retenido), (5, .imprimiendo), (6, .detenido),
    (7, .cancelado), (8, .abortado), (9, .completado), (42, .pendiente),
])
func mapeaEstadoDeTrabajo(ipp: Int, esperado: EstadoTrabajo) {
    #expect(EstadoTrabajo(ipp: ipp) == esperado)
}

@Test func soloLosFinalesEstanTerminados() {
    #expect(!EstadoTrabajo.pendiente.terminado)
    #expect(!EstadoTrabajo.imprimiendo.terminado)
    #expect(EstadoTrabajo.abortado.terminado)
    #expect(EstadoTrabajo.abortado.titulo == "Falló")
}

@Test func cancelarUsaElRunnerConElIdDelTrabajo() throws {
    let runner = FakeRunner()
    var pendiente = trabajoReal
    pendiente.estado = .pendiente
    try PrinterService(runner: runner).cancelar(pendiente)
    #expect(runner.llamadas.count == 1)
    #expect(runner.llamadas[0].herramienta == "cancel")
    #expect(runner.llamadas[0].argumentos == ["Brother_HL_1210W_series-8"])
}

@Test func cancelarTodosUsaMenosA() throws {
    let runner = FakeRunner()
    try PrinterService(runner: runner).cancelarTodos(de: "Brother_HL_1210W_series")
    #expect(runner.llamadas[0].argumentos == ["-a", "Brother_HL_1210W_series"])
}

@Test func cancelarQueFallaDaError() {
    let runner = FakeRunner()
    runner.respuesta = CommandResult(status: 1, error: "cancel: no existe")
    #expect(throws: PrintBroError.comandoFallo("cancel: no existe")) {
        try PrinterService(runner: runner).cancelar(trabajoReal)
    }
}
