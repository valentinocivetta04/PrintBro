import Foundation

public enum Orientacion: String, Sendable, Codable {
    case vertical, horizontal
}

public struct PrintJob: Sendable, Equatable {
    /// Valores de number-up que ofrece la app.
    public static let paginasPorHojaPosibles = [1, 2, 4, 6, 9]

    public var archivo: URL
    public var impresora: String
    public var copias = 1
    /// Formato de CUPS, ej. "1-3,5".
    public var rangoPaginas: String?
    public var orientacion: Orientacion?
    /// Un valor de PageSize que ofrezca el driver, ej. "A4".
    public var tamanioPapel: String?
    public var paginasPorHoja = 1
    /// Clave y valor tal como los da lpoptions -l.
    public var opcionesDriver: [String: String] = [:]
    /// Escala el contenido al papel (folletos e imágenes).
    public var ajustarAPagina = false

    public init(archivo: URL, impresora: String) {
        self.archivo = archivo
        self.impresora = impresora
    }

    public func argumentosLP(extra: [String] = []) -> [String] {
        var args = ["-d", impresora]
        if copias > 1 { args += ["-n", String(copias)] }
        if let rangoPaginas { args += ["-o", "page-ranges=\(rangoPaginas)"] }
        switch orientacion {
        case .vertical: args += ["-o", "orientation-requested=3"]
        case .horizontal: args += ["-o", "orientation-requested=4"]
        case nil: break
        }
        if let tamanioPapel { args += ["-o", "PageSize=\(tamanioPapel)"] }
        if paginasPorHoja > 1 { args += ["-o", "number-up=\(paginasPorHoja)"] }
        if ajustarAPagina { args += ["-o", "fit-to-page"] }
        // Ordenadas para que los argumentos salgan siempre iguales.
        for clave in opcionesDriver.keys.sorted() {
            args += ["-o", "\(clave)=\(opcionesDriver[clave]!)"]
        }
        args += extra
        // Ruta absoluta: nunca empieza con "-", así lp no la confunde con una opción.
        args.append(archivo.standardizedFileURL.path)
        return args
    }
}

public enum TipoArchivo {
    static let directos: Set<String> = ["pdf", "png", "jpg", "jpeg", "heic", "txt"]
    static let paraConvertir: Set<String> = ["docx", "doc", "xlsx", "xls", "pages", "numbers", "key", "pptx"]

    public static func validar(_ url: URL) throws {
        let ext = url.pathExtension.lowercased()
        if directos.contains(ext) { return }
        if paraConvertir.contains(ext) { throw PrintBroError.convertirAPDF(ext) }
        throw PrintBroError.formatoNoSoportado(ext)
    }
}
