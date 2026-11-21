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

    /// Todas las colas con sus opciones, leídas con la API C de CUPS: no depende del idioma del sistema.
    private static func destinos() -> [(nombre: String, predeterminada: Bool, opciones: [String: String])] {
        var dests: UnsafeMutablePointer<cups_dest_t>?
        let cantidad = cupsGetDests(&dests)
        defer { cupsFreeDests(cantidad, dests) }
        guard let dests else { return [] }
        return (0..<Int(cantidad)).map { i in
            let d = dests[i]
            var opciones: [String: String] = [:]
            for j in 0..<Int(d.num_options) {
                opciones[String(cString: d.options[j].name)] = String(cString: d.options[j].value)
            }
            return (String(cString: d.name), d.is_default != 0, opciones)
        }
    }

    public static func impresoras() -> [Impresora] {
        destinos().map {
            Impresora(nombre: $0.nombre, predeterminada: $0.predeterminada,
                      marcaYModelo: $0.opciones["printer-make-and-model"] ?? "")
        }
    }

    /// Estado actual de una cola (printer-state, printer-state-reasons...).
    public static func estado(de nombre: String) -> EstadoImpresora? {
        destinos().first { $0.nombre == nombre }.map { EstadoImpresora(opciones: $0.opciones) }
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

    /// De lo que eligió el usuario, solo las opciones que difieren del valor por defecto del driver
    /// (y que el driver realmente ofrece).
    public static func opcionesCambiadas(_ opciones: [OpcionDriver], valores: [String: String]) -> [String: String] {
        var cambiadas: [String: String] = [:]
        for opcion in opciones {
            if let valor = valores[opcion.clave], valor != opcion.porDefecto, opcion.valores.contains(valor) {
                cambiadas[opcion.clave] = valor
            }
        }
        return cambiadas
    }

    /// Devuelve un aviso si el driver no es de Brother (ej. DYMO o genérico), nil si está bien.
    public static func avisoDriver(_ marcaYModelo: String) -> String? {
        if marcaYModelo.localizedCaseInsensitiveContains("brother") { return nil }
        let nombre = marcaYModelo.isEmpty ? String(localized: "desconocido") : marcaYModelo
        return String(localized: "El driver de esta cola es «\(nombre)», no es de Brother. Los trabajos pueden figurar como completados sin imprimir nada.")
    }

    /// Manda el trabajo a lp. `extra` suma opciones como page-set para el doble faz.
    public func imprimir(_ trabajo: PrintJob, extra: [String] = []) throws {
        try TipoArchivo.validar(trabajo.archivo)
        let r = try runner.run("lp", trabajo.argumentosLP(extra: extra))
        guard r.status == 0 else { throw PrintBroError.comandoFallo(r.error) }
    }
}
