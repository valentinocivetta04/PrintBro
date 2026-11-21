import Foundation
import Testing
@testable import PrintBroCore

@Test func argumentosMinimos() {
    let trabajo = PrintJob(archivo: URL(fileURLWithPath: "/tmp/a.pdf"), impresora: "Brother_HL_1210W_series")
    #expect(trabajo.argumentosLP() == ["-d", "Brother_HL_1210W_series", "/tmp/a.pdf"])
}

@Test func argumentosCompletos() {
    var trabajo = PrintJob(archivo: URL(fileURLWithPath: "/tmp/a.pdf"), impresora: "B")
    trabajo.copias = 2
    trabajo.rangoPaginas = "1-3,5"
    trabajo.orientacion = .horizontal
    trabajo.tamanioPapel = "A4"
    trabajo.paginasPorHoja = 2
    trabajo.opcionesDriver = ["TonerSaveMode": "ON", "BRResolution": "2400x600dpi"]
    #expect(trabajo.argumentosLP(extra: ["-o", "page-set=odd"]) == [
        "-d", "B", "-n", "2",
        "-o", "page-ranges=1-3,5",
        "-o", "orientation-requested=4",
        "-o", "PageSize=A4",
        "-o", "number-up=2",
        "-o", "BRResolution=2400x600dpi",
        "-o", "TonerSaveMode=ON",
        "-o", "page-set=odd",
        "/tmp/a.pdf",
    ])
}

@Test(arguments: PrintJob.paginasPorHojaPosibles)
func paginasPorHojaUsaNumberUp(valor: Int) {
    var trabajo = PrintJob(archivo: URL(fileURLWithPath: "/tmp/a.pdf"), impresora: "B")
    trabajo.paginasPorHoja = valor
    let args = trabajo.argumentosLP()
    // Con 1 no hace falta mandar number-up.
    #expect(args.contains("number-up=\(valor)") == (valor > 1))
}

@Test func tituloVaComoUnSoloArgumento() {
    var trabajo = PrintJob(archivo: URL(fileURLWithPath: "/tmp/PrintBro-folleto-ABC.pdf"), impresora: "B")
    trabajo.titulo = "mi apunte \"final\".pdf"
    #expect(trabajo.argumentosLP() == ["-d", "B", "-t", "mi apunte \"final\".pdf", "/tmp/PrintBro-folleto-ABC.pdf"])
}

@Test func sinTituloNoMandaMenosT() {
    let trabajo = PrintJob(archivo: URL(fileURLWithPath: "/tmp/a.pdf"), impresora: "B")
    #expect(!trabajo.argumentosLP().contains("-t"))
}

@Test func orientacionVertical() {
    var trabajo = PrintJob(archivo: URL(fileURLWithPath: "/tmp/a.pdf"), impresora: "B")
    trabajo.orientacion = .vertical
    #expect(trabajo.argumentosLP().contains("orientation-requested=3"))
}

@Test func nombreRaroQuedaEnUnSoloArgumento() {
    let ruta = "/tmp/mi \"apunte\"; rm -rf ~ $(x).pdf"
    let trabajo = PrintJob(archivo: URL(fileURLWithPath: ruta), impresora: "B")
    #expect(trabajo.argumentosLP().last == ruta)
}

@Test func rutaRelativaSeVuelveAbsoluta() {
    let trabajo = PrintJob(archivo: URL(fileURLWithPath: "-raro.pdf"), impresora: "B")
    #expect(trabajo.argumentosLP().last!.hasPrefix("/"))
}

@Test(arguments: ["a.pdf", "b.PNG", "c.jpg", "d.jpeg", "e.heic", "f.txt"])
func aceptaFormatosDirectos(nombre: String) throws {
    try TipoArchivo.validar(URL(fileURLWithPath: "/tmp/\(nombre)"))
}

@Test(arguments: ["docx", "xlsx", "pages"])
func pideConvertirOffice(ext: String) {
    #expect(throws: PrintBroError.convertirAPDF(ext)) {
        try TipoArchivo.validar(URL(fileURLWithPath: "/tmp/x.\(ext)"))
    }
    #expect(PrintBroError.convertirAPDF(ext).errorDescription!.contains("convertilo a PDF primero"))
}

@Test func rechazaFormatoDesconocido() {
    #expect(throws: PrintBroError.formatoNoSoportado("zip")) {
        try TipoArchivo.validar(URL(fileURLWithPath: "/tmp/x.zip"))
    }
}
