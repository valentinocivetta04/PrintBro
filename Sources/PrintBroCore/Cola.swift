import CUPS
import Foundation

/// Estado de un trabajo (job-state de IPP, RFC 8011): 3 a 9.
public enum EstadoTrabajo: Equatable, Sendable {
    case pendiente, retenido, imprimiendo, detenido, cancelado, abortado, completado

    public init(ipp: Int) {
        switch ipp {
        case 4: self = .retenido
        case 5: self = .imprimiendo
        case 6: self = .detenido
        case 7: self = .cancelado
        case 8: self = .abortado
        case 9: self = .completado
        default: self = .pendiente
        }
    }

    /// Ya no va a cambiar.
    public var terminado: Bool { [.cancelado, .abortado, .completado].contains(self) }

    public var titulo: String {
        switch self {
        case .pendiente: String(localized: "En espera")
        case .retenido: String(localized: "Retenido")
        case .imprimiendo: String(localized: "Imprimiendo")
        case .detenido: String(localized: "Detenido")
        case .cancelado: String(localized: "Cancelado")
        case .abortado: String(localized: "Falló")
        case .completado: String(localized: "Terminado")
        }
    }

    public var simbolo: String {
        switch self {
        case .pendiente: "clock"
        case .retenido: "pause.circle"
        case .imprimiendo: "printer.dotmatrix"
        case .detenido: "exclamationmark.triangle"
        case .cancelado: "xmark.circle"
        case .abortado: "xmark.octagon"
        case .completado: "checkmark.circle"
        }
    }
}

public struct TrabajoCola: Identifiable, Equatable, Sendable {
    public var id: Int
    public var impresora: String
    /// Título del trabajo: CUPS guarda el nombre del archivo.
    public var archivo: String
    public var estado: EstadoTrabajo
    public var fecha: Date

    public init(id: Int, impresora: String, archivo: String, estadoIPP: Int, creacion: Int) {
        self.id = id
        self.impresora = impresora
        self.archivo = archivo
        estado = EstadoTrabajo(ipp: estadoIPP)
        fecha = Date(timeIntervalSince1970: TimeInterval(creacion))
    }
}

extension PrinterService {
    /// Trabajos de una cola con cupsGetJobs2 (solo lectura). `activos` deja afuera los terminados.
    public static func trabajos(de impresora: String, activos: Bool = true) -> [TrabajoCola] {
        var jobs: UnsafeMutablePointer<cups_job_t>?
        let cuales = activos ? CUPS_WHICHJOBS_ACTIVE : CUPS_WHICHJOBS_ALL
        let cantidad = cupsGetJobs2(nil, &jobs, impresora, 0, cuales)
        defer { cupsFreeJobs(cantidad, jobs) }
        guard let jobs, cantidad > 0 else { return [] }
        return (0..<Int(cantidad)).map { i in
            let job = jobs[i]
            return TrabajoCola(id: Int(job.id), impresora: String(cString: job.dest),
                               archivo: String(cString: job.title), estadoIPP: Int(job.state.rawValue),
                               creacion: Int(job.creation_time))
        }
    }

    /// Cancela un trabajo. Solo se mira el código de salida de `cancel`, nunca su texto (viene traducido).
    public func cancelar(_ trabajo: TrabajoCola) throws {
        let r = try runner.run("cancel", ["\(trabajo.impresora)-\(trabajo.id)"])
        guard r.status == 0 else { throw PrintBroError.comandoFallo(r.error) }
    }

    /// Cancela todos los trabajos de la cola.
    public func cancelarTodos(de impresora: String) throws {
        let r = try runner.run("cancel", ["-a", impresora])
        guard r.status == 0 else { throw PrintBroError.comandoFallo(r.error) }
    }
}
