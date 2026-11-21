import Testing
@testable import PrintBroCore

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
