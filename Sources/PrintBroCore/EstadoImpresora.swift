import Foundation

/// Motivo de estado de CUPS (printer-state-reasons). Los códigos son estándar y no se traducen.
public enum Motivo: Equatable, Sendable {
    case tonerBajo
    case sinToner
    case sinPapel
    case atasco
    case tapaAbierta
    case pausada
    case sinConexion
    case otro(String)

    public enum Gravedad: Sendable {
        case aviso, error
    }

    /// Lee un código como "toner-low-report". Los sufijos -report/-warning/-error solo cambian la gravedad.
    public init(codigo: String) {
        var base = codigo
        for sufijo in ["-report", "-warning", "-error"] where base.hasSuffix(sufijo) {
            base.removeLast(sufijo.count)
        }
        switch base {
        case "toner-low", "marker-supply-low": self = .tonerBajo
        case "toner-empty", "marker-supply-empty": self = .sinToner
        case "media-empty", "media-needed": self = .sinPapel
        case "media-jam": self = .atasco
        case "cover-open", "door-open": self = .tapaAbierta
        case "paused": self = .pausada
        case "offline", "connecting-to-device", "timed-out": self = .sinConexion
        default: self = .otro(codigo)
        }
    }

    /// Lista separada por comas; "none" significa que no hay motivos.
    public static func lista(_ texto: String) -> [Motivo] {
        texto.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0 != "none" }
            .map(Motivo.init(codigo:))
    }

    public var titulo: String {
        switch self {
        case .tonerBajo: String(localized: "Tóner bajo")
        case .sinToner: String(localized: "Sin tóner")
        case .sinPapel: String(localized: "Sin papel")
        case .atasco: String(localized: "Atasco de papel")
        case .tapaAbierta: String(localized: "Tapa abierta")
        case .pausada: String(localized: "Impresora pausada")
        case .sinConexion: String(localized: "Sin conexión")
        case .otro(let codigo): String(localized: "Aviso de la impresora (\(codigo))")
        }
    }

    public var accion: String {
        switch self {
        case .tonerBajo: String(localized: "Todavía imprime. Conseguí un cartucho de repuesto.")
        case .sinToner: String(localized: "Cambiá el cartucho de tóner.")
        case .sinPapel: String(localized: "Cargá papel en la bandeja.")
        case .atasco: String(localized: "Abrí la impresora y sacá con cuidado la hoja trabada.")
        case .tapaAbierta: String(localized: "Cerrá la tapa de la impresora.")
        case .pausada: String(localized: "Reanudala desde Configuración del Sistema > Impresoras y escáneres.")
        case .sinConexion: String(localized: "Revisá que esté prendida y en la misma red WiFi que la Mac.")
        case .otro: String(localized: "Revisá la impresora.")
        }
    }

    public var simbolo: String {
        switch self {
        case .tonerBajo, .sinToner: "drop.triangle"
        case .sinPapel: "doc.badge.ellipsis"
        case .atasco: "exclamationmark.octagon"
        case .tapaAbierta: "rectangle.portrait.on.rectangle.portrait.angled"
        case .pausada: "pause.circle"
        case .sinConexion: "wifi.exclamationmark"
        case .otro: "info.circle"
        }
    }

    public var gravedad: Gravedad {
        switch self {
        case .tonerBajo, .otro: .aviso
        case .sinToner, .sinPapel, .atasco, .tapaAbierta, .pausada, .sinConexion: .error
        }
    }
}

public enum EstadoGeneral: Equatable, Sendable {
    case lista, imprimiendo, pausada, sinConexion

    public var titulo: String {
        switch self {
        case .lista: String(localized: "Lista")
        case .imprimiendo: String(localized: "Imprimiendo")
        case .pausada: String(localized: "Pausada")
        case .sinConexion: String(localized: "Sin conexión")
        }
    }

    public var simbolo: String {
        switch self {
        case .lista: "checkmark.circle"
        case .imprimiendo: "printer.dotmatrix"
        case .pausada: "pause.circle"
        case .sinConexion: "wifi.exclamationmark"
        }
    }
}

public struct EstadoImpresora: Equatable, Sendable {
    public var nombre: String
    public var driver: String
    public var uri: String
    public var aceptaTrabajos: Bool
    public var general: EstadoGeneral
    public var motivos: [Motivo]

    /// Arma el estado desde las opciones del destino de CUPS (cupsGetDests). Sin texto localizado.
    public init(nombre: String, opciones: [String: String]) {
        self.nombre = nombre
        driver = opciones["printer-make-and-model"] ?? ""
        uri = opciones["device-uri"] ?? ""
        aceptaTrabajos = opciones["printer-is-accepting-jobs"] != "false"
        motivos = Motivo.lista(opciones["printer-state-reasons"] ?? "")
        // printer-state: 3 = idle, 4 = processing, 5 = stopped (RFC 8011).
        if motivos.contains(.sinConexion) {
            general = .sinConexion
        } else {
            switch opciones["printer-state"] {
            case "4": general = .imprimiendo
            case "5": general = .pausada
            default: general = .lista
            }
        }
    }
}
