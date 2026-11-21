import CUPS
import Foundation

public struct Impresora: Sendable, Equatable {
    public var nombre: String
    public var predeterminada: Bool
    /// printer-make-and-model: CUPS lo toma del *NickName del PPD.
    public var marcaYModelo: String
}

public struct OpcionDriver: Sendable, Equatable {
    public var clave: String
    public var etiqueta: String
    public var valores: [String]
    public var porDefecto: String?
}

public struct PrinterService: Sendable {
    let runner: any CommandRunner

    public init(runner: any CommandRunner = ProcessRunner()) {
        self.runner = runner
    }

    /// Lista las colas con la API C de CUPS: no depende del idioma del sistema.
    public static func impresoras() -> [Impresora] {
        var dests: UnsafeMutablePointer<cups_dest_t>?
        let cantidad = cupsGetDests(&dests)
        defer { cupsFreeDests(cantidad, dests) }
        guard let dests else { return [] }
        return (0..<Int(cantidad)).map { i in
            let d = dests[i]
            let modelo = cupsGetOption("printer-make-and-model", d.num_options, d.options)
            return Impresora(
                nombre: String(cString: d.name),
                predeterminada: d.is_default != 0,
                marcaYModelo: modelo.map { String(cString: $0) } ?? ""
            )
        }
    }

    /// Opciones que ofrece el driver de la cola (lpoptions -l).
    public func opciones(de impresora: String) throws -> [OpcionDriver] {
        let r = try runner.run("lpoptions", ["-p", impresora, "-l"])
        guard r.status == 0 else { throw PrintBroError.comandoFallo(r.error) }
        return Self.parsearOpciones(r.salida)
    }

    /// Formato de cada línea: "Clave/Etiqueta: valor *defecto valor".
    /// Se parsea por estructura; la etiqueta puede venir traducida y no se usa para decidir nada.
    public static func parsearOpciones(_ texto: String) -> [OpcionDriver] {
        texto.split(separator: "\n").compactMap { linea in
            guard let barra = linea.firstIndex(of: "/"),
                  // El último ": ": la etiqueta traducida podría tener dos puntos, los valores no.
                  let dosPuntos = linea[barra...].range(of: ": ", options: .backwards)
            else { return nil }
            let clave = String(linea[..<barra])
            let etiqueta = String(linea[linea.index(after: barra)..<dosPuntos.lowerBound])
            var porDefecto: String?
            // Custom.* pide valores a mano (ancho x alto, enteros): se omite.
            let valores = linea[dosPuntos.upperBound...].split(separator: " ").compactMap { v -> String? in
                var valor = String(v)
                if valor.hasPrefix("*") {
                    valor.removeFirst()
                    porDefecto = valor
                }
                return valor.hasPrefix("Custom.") ? nil : valor
            }
            return OpcionDriver(clave: clave, etiqueta: etiqueta, valores: valores, porDefecto: porDefecto)
        }
    }

    /// Devuelve un aviso si el driver no es de Brother (ej. DYMO o genérico), nil si está bien.
    public static func avisoDriver(_ marcaYModelo: String) -> String? {
        if marcaYModelo.localizedCaseInsensitiveContains("brother") { return nil }
        let nombre = marcaYModelo.isEmpty ? "desconocido" : marcaYModelo
        return "El driver de esta cola es «\(nombre)», no es de Brother. Los trabajos pueden figurar como completados sin imprimir nada."
    }

    /// Manda el trabajo a lp. `extra` suma opciones como page-set para el doble faz.
    public func imprimir(_ trabajo: PrintJob, extra: [String] = []) throws {
        try TipoArchivo.validar(trabajo.archivo)
        let r = try runner.run("lp", trabajo.argumentosLP(extra: extra))
        guard r.status == 0 else { throw PrintBroError.comandoFallo(r.error) }
    }
}
