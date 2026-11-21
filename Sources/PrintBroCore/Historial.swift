import Foundation

public struct EntradaHistorial: Codable, Equatable, Sendable, Identifiable {
    public var id = UUID()
    /// El archivo que eligió el usuario (no el PDF temporal del folleto o de una imagen).
    public var archivo: URL
    public var fecha: Date
    public var configuracion: Configuracion

    public init(archivo: URL, fecha: Date = Date(), configuracion: Configuracion) {
        self.archivo = archivo
        self.fecha = fecha
        self.configuracion = configuracion
    }

    /// Resumen corto de las opciones, para la lista.
    public var resumen: String {
        let c = configuracion
        var partes = [c.copias == 1 ? String(localized: "1 copia") : String(localized: "\(c.copias) copias")]
        if let rango = c.rangoPaginas { partes.append(String(localized: "páginas \(rango)")) }
        if let papel = c.tamanioPapel { partes.append(papel) }
        if c.paginasPorHoja > 1 { partes.append(String(localized: "\(c.paginasPorHoja) por hoja")) }
        if c.folleto {
            partes.append(String(localized: "folleto"))
        } else if c.dobleFaz {
            partes.append(String(localized: "doble faz"))
        }
        return partes.joined(separator: " · ")
    }
}

/// Últimos trabajos enviados desde la app, el más nuevo primero.
public struct HistorialStore {
    static let clave = "historial"
    public static let maximo = 20
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func todas() -> [EntradaHistorial] {
        guard let datos = defaults.data(forKey: Self.clave) else { return [] }
        return (try? JSONDecoder().decode([EntradaHistorial].self, from: datos)) ?? []
    }

    public func agregar(_ entrada: EntradaHistorial) throws {
        let lista = Array(([entrada] + todas()).prefix(Self.maximo))
        defaults.set(try JSONEncoder().encode(lista), forKey: Self.clave)
    }
}
