import Testing
@testable import PrintBroCore

private func trabajo(_ id: Int, estado: Int = 3) -> TrabajoCola {
    TrabajoCola(id: id, impresora: "Brother_HL_1210W_series", archivo: "a.pdf", estadoIPP: estado, creacion: 0)
}

@Test func soloSeSiguenLosTrabajosNuevos() {
    let cola = [trabajo(7), trabajo(8), trabajo(9), trabajo(10)]
    #expect(Seguimiento.nuevos(cola, despuesDe: 8).map(\.id) == [9, 10])
    #expect(Seguimiento.nuevos(cola, despuesDe: 10).isEmpty)
}

@Test func avisoAlTerminarOFallar() throws {
    let terminado = try #require(Seguimiento.aviso(para: .completado, archivo: "apunte.pdf"))
    #expect(terminado.titulo == "Impresión terminada")
    #expect(terminado.cuerpo == "«apunte.pdf» ya salió de la impresora.")
    let fallo = try #require(Seguimiento.aviso(para: .abortado, archivo: "apunte.pdf"))
    #expect(fallo.titulo == "La impresión falló")
    #expect(Seguimiento.aviso(para: .cancelado, archivo: "a.pdf")?.titulo == "Impresión cancelada")
}

@Test func sinAvisoMientrasNoTermina() {
    #expect(Seguimiento.aviso(para: .pendiente, archivo: "a.pdf") == nil)
    #expect(Seguimiento.aviso(para: .imprimiendo, archivo: "a.pdf") == nil)
    #expect(Seguimiento.aviso(para: .retenido, archivo: "a.pdf") == nil)
}
