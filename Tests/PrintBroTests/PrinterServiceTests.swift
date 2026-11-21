import Foundation
import Testing
@testable import PrintBroCore

// Salida real de `lpoptions -p Brother_HL_1210W_series -l` en esta Mac (2026-11-21).
let salidaRealLpoptions = """
PageSize/Media Size: A4 *Letter Legal Executive A5 A5Rotated ISOB5 FanFoldGermanLegal Custom.WIDTHxHEIGHT
BRMediaType/Media Type: *Plain Recycled
BRResolution/Resolution: 300dpi *300x600dpi 2400x600dpi
BRHalfTonePattern/Graphics Quality: *Brother Brother4
TonerSaveMode/Toner Save Mode: *OFF ON
BRImproveOutput/Improvement Settings: *OFF BRLessPaperCurl BRFixIntensity
BRSkipBlank/Skip Blank Page: *OFF ON
BRDensityAdjustment/Density Adjustment: *Default _Custom Custom.INTEGER

"""

@Test func parseaOpcionesRealesDelDriver() {
    let opciones = PrinterService.parsearOpciones(salidaRealLpoptions)
    #expect(opciones.count == 8)
    #expect(opciones.map(\.clave) == [
        "PageSize", "BRMediaType", "BRResolution", "BRHalfTonePattern",
        "TonerSaveMode", "BRImproveOutput", "BRSkipBlank", "BRDensityAdjustment",
    ])
    #expect(opciones[0] == OpcionDriver(
        clave: "PageSize", etiqueta: "Media Size",
        valores: ["A4", "Letter", "Legal", "Executive", "A5", "A5Rotated", "ISOB5", "FanFoldGermanLegal"],
        porDefecto: "Letter"
    ))
    #expect(opciones[2].porDefecto == "300x600dpi")
    #expect(opciones[7].valores == ["Default", "_Custom"])
}

@Test func parseaEtiquetasTraducidasConDosPuntos() {
    let opciones = PrinterService.parsearOpciones("PageSize/Tamaño: del papel: *A4 Letter\nbasura sin formato\n")
    #expect(opciones.count == 1)
    #expect(opciones[0].clave == "PageSize")
    #expect(opciones[0].etiqueta == "Tamaño: del papel")
    #expect(opciones[0].valores == ["A4", "Letter"])
    #expect(opciones[0].porDefecto == "A4")
}

@Test func opcionesUsaLpoptionsConArgumentosSeparados() throws {
    let runner = FakeRunner()
    runner.respuesta = CommandResult(salida: salidaRealLpoptions)
    let opciones = try PrinterService(runner: runner).opciones(de: "Brother_HL_1210W_series")
    #expect(opciones.count == 8)
    #expect(runner.llamadas.count == 1)
    #expect(runner.llamadas[0].herramienta == "lpoptions")
    #expect(runner.llamadas[0].argumentos == ["-p", "Brother_HL_1210W_series", "-l"])
}

@Test func avanzadoMuestraExactamenteLasOpcionesDeLpoptions() {
    // Las claves que lista la sección Avanzado son las de la salida real, en el mismo orden.
    let opciones = PrinterService.parsearOpciones(salidaRealLpoptions)
    let clavesReales = salidaRealLpoptions.split(separator: "\n").map { String($0.prefix { $0 != "/" }) }
    #expect(opciones.map(\.clave) == clavesReales)
}

@Test func soloSeMandanLasOpcionesCambiadas() {
    let opciones = PrinterService.parsearOpciones(salidaRealLpoptions)
    let valores = [
        "TonerSaveMode": "ON",          // cambiada
        "BRResolution": "300x600dpi",   // igual al defecto
        "BRMediaType": "Cartón",        // el driver no la ofrece
        "Inventada": "X",               // no existe
    ]
    #expect(PrinterService.opcionesCambiadas(opciones, valores: valores) == ["TonerSaveMode": "ON"])
}

@Test func driverBrotherNoDaAviso() {
    #expect(PrinterService.avisoDriver("Brother HL-1210W series CUPS") == nil)
}

@Test(arguments: ["DYMO LabelWriter 450", "Generic PostScript Printer", "Impresora PostScript genérica", ""])
func driverAjenoDaAviso(modelo: String) {
    let aviso = PrinterService.avisoDriver(modelo)
    #expect(aviso != nil)
    #expect(aviso!.contains("no es de Brother"))
}

@Test func imprimirFallaSiLpDevuelveError() {
    let runner = FakeRunner()
    runner.respuesta = CommandResult(status: 1, error: "lp: error")
    let trabajo = PrintJob(archivo: URL(fileURLWithPath: "/tmp/a.pdf"), impresora: "X")
    #expect(throws: PrintBroError.comandoFallo("lp: error")) {
        try PrinterService(runner: runner).imprimir(trabajo)
    }
}

@Test func imprimirRechazaDocxSinLlamarALp() {
    let runner = FakeRunner()
    let trabajo = PrintJob(archivo: URL(fileURLWithPath: "/tmp/informe.docx"), impresora: "X")
    #expect(throws: PrintBroError.convertirAPDF("docx")) {
        try PrinterService(runner: runner).imprimir(trabajo)
    }
    #expect(runner.llamadas.isEmpty)
}
