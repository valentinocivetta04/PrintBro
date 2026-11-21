import Testing
@testable import PrintBroCore

// Opciones reales del destino en esta Mac (cupsGetDests, 2026-11-21). Para comparar, `lpstat -l -p`
// en español muestra "Avisos: toner-low-report": el código no se traduce, el resto del texto sí.
let opcionesRealesBrother: [String: String] = [
    "copies": "1",
    "device-uri": "dnssd://Brother%20HL-1210W%20series._pdl-datastream._tcp.local./?bidi",
    "printer-info": "Brother HL-1210W series",
    "printer-is-accepting-jobs": "true",
    "printer-make-and-model": "Brother HL-1210W series CUPS",
    "printer-state": "3",
    "printer-state-reasons": "toner-low-report",
    "printer-uri-supported": "ipp://localhost/printers/Brother_HL_1210W_series",
]

@Test func estadoRealDeEstaImpresora() {
    let estado = EstadoImpresora(opciones: opcionesRealesBrother)
    #expect(estado.general == .lista)
    #expect(estado.motivos == [.tonerBajo])
    #expect(estado.motivos[0].gravedad == .aviso)
    #expect(estado.uri.hasPrefix("dnssd://Brother"))
    #expect(estado.aceptaTrabajos)
}

@Test(arguments: [
    ("toner-low", Motivo.tonerBajo),
    ("toner-low-report", .tonerBajo),
    ("toner-low-warning", .tonerBajo),
    ("toner-empty-error", .sinToner),
    ("media-empty-error", .sinPapel),
    ("media-needed", .sinPapel),
    ("media-jam-error", .atasco),
    ("cover-open-error", .tapaAbierta),
    ("paused", .pausada),
    ("offline-report", .sinConexion),
])
func mapeaMotivosEstandar(codigo: String, esperado: Motivo) {
    #expect(Motivo(codigo: codigo) == esperado)
}

@Test func motivoDesconocidoNoRompeNada() {
    let motivo = Motivo(codigo: "com.brother.algo-raro-report")
    #expect(motivo == .otro("com.brother.algo-raro-report"))
    #expect(motivo.titulo == "Aviso de la impresora (com.brother.algo-raro-report)")
    #expect(!motivo.accion.isEmpty)
    #expect(motivo.gravedad == .aviso)
}

@Test func listaDeMotivos() {
    #expect(Motivo.lista("none").isEmpty)
    #expect(Motivo.lista("").isEmpty)
    #expect(Motivo.lista("toner-low-report, media-jam-error") == [.tonerBajo, .atasco])
}

@Test func mensajesEnEspanolConAccion() {
    #expect(Motivo.tonerBajo.titulo == "Tóner bajo")
    #expect(Motivo.sinToner.titulo == "Sin tóner")
    #expect(Motivo.sinPapel.titulo == "Sin papel")
    #expect(Motivo.atasco.titulo == "Atasco de papel")
    #expect(Motivo.tapaAbierta.titulo == "Tapa abierta")
    #expect(Motivo.sinPapel.accion == "Cargá papel en la bandeja.")
    #expect(Motivo.atasco.gravedad == .error)
}

@Test(arguments: [("3", EstadoGeneral.lista), ("4", .imprimiendo), ("5", .pausada)])
func estadoGeneralPorPrinterState(valor: String, esperado: EstadoGeneral) {
    var opciones = opcionesRealesBrother
    opciones["printer-state"] = valor
    #expect(EstadoImpresora(opciones: opciones).general == esperado)
}

@Test func offlineGanaSobrePrinterState() {
    var opciones = opcionesRealesBrother
    opciones["printer-state-reasons"] = "offline-report"
    let estado = EstadoImpresora(opciones: opciones)
    #expect(estado.general == .sinConexion)
    #expect(estado.general.titulo == "Sin conexión")
}
