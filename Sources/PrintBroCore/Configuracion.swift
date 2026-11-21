import Foundation

/// Lo que el usuario eligió en el formulario, sin el archivo. Se guarda en presets e historial.
public struct Configuracion: Codable, Equatable, Sendable {
    public var impresora = ""
    public var copias = 1
    public var rangoPaginas: String?
    public var orientacion: Orientacion?
    public var tamanioPapel: String?
    public var paginasPorHoja = 1
    /// Todos los valores elegidos en Avanzado (no solo los cambiados), para poder restaurarlos.
    public var opcionesDriver: [String: String] = [:]
    public var dobleFaz = false
    public var folleto = false

    public init() {}
}

public struct Preset: Codable, Equatable, Sendable, Identifiable {
    public var nombre: String
    public var configuracion: Configuracion
    public var id: String { nombre }

    public init(nombre: String, configuracion: Configuracion) {
        self.nombre = nombre
        self.configuracion = configuracion
    }
}

/// Presets con nombre en UserDefaults, ordenados por nombre.
public struct PresetStore {
    static let clave = "presets"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func todos() -> [Preset] {
        guard let datos = defaults.data(forKey: Self.clave) else { return [] }
        return (try? JSONDecoder().decode([Preset].self, from: datos)) ?? []
    }

    /// Guarda el preset; si ya hay uno con ese nombre, lo reemplaza.
    public func guardar(_ preset: Preset) throws {
        let nombre = preset.nombre.trimmingCharacters(in: .whitespaces)
        guard !nombre.isEmpty else { throw PrintBroError.presetSinNombre }
        var lista = todos().filter { $0.nombre != nombre }
        var nuevo = preset
        nuevo.nombre = nombre
        nuevo.configuracion.rangoPaginas = nil  // el rango depende de cada documento
        lista.append(nuevo)
        lista.sort { $0.nombre.localizedStandardCompare($1.nombre) == .orderedAscending }
        try escribir(lista)
    }

    public func borrar(nombre: String) throws {
        try escribir(todos().filter { $0.nombre != nombre })
    }

    private func escribir(_ lista: [Preset]) throws {
        defaults.set(try JSONEncoder().encode(lista), forKey: Self.clave)
    }
}
