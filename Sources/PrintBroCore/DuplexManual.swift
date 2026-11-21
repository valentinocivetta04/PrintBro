import Foundation
import PDFKit

public enum EstadoDuplex: Sendable, Equatable {
    case idle
    case imprimiendoImpares
    /// `aviso` no es nil cuando la cantidad de páginas es impar.
    case esperandoGiro(aviso: String?)
    case imprimiendoPares
    case listo
    case cancelado
}

/// Doble faz manual: primero impares, el usuario gira la pila, después pares.
public final class DuplexManual {
    static let claveOrdenInverso = "duplexOrdenInversoPares"

    public private(set) var estado = EstadoDuplex.idle
    public let trabajo: PrintJob
    public let paginas: Int
    /// Caras que salen de la impresora: con 2 por hoja, 5 páginas son 3 caras.
    public let caras: Int
    private let servicio: PrinterService
    private let defaults: UserDefaults

    /// Recordado entre usos. Por defecto Sí: es lo que anda con esta impresora.
    public var ordenInverso: Bool {
        didSet { defaults.set(ordenInverso, forKey: Self.claveOrdenInverso) }
    }

    public init(trabajo: PrintJob, paginas: Int, servicio: PrinterService, defaults: UserDefaults = .standard) throws {
        guard trabajo.archivo.pathExtension.lowercased() == "pdf" else { throw PrintBroError.duplexSoloPDF }
        guard trabajo.rangoPaginas == nil else { throw PrintBroError.duplexConRango }
        guard trabajo.copias <= 1 else { throw PrintBroError.duplexConCopias }
        guard paginas > 0 else { throw PrintBroError.pdfIlegible }
        self.trabajo = trabajo
        self.paginas = paginas
        // Verificado en papel (2026-11-21): CUPS aplica page-set después de number-up,
        // así que impares/pares cuentan caras impresas, no páginas del PDF.
        caras = (paginas + max(trabajo.paginasPorHoja, 1) - 1) / max(trabajo.paginasPorHoja, 1)
        self.servicio = servicio
        self.defaults = defaults
        ordenInverso = defaults.object(forKey: Self.claveOrdenInverso) as? Bool ?? true
    }

    public static func contarPaginas(_ url: URL) throws -> Int {
        guard let pdf = PDFDocument(url: url) else { throw PrintBroError.pdfIlegible }
        return pdf.pageCount
    }

    public func empezar() throws {
        guard estado == .idle else { throw PrintBroError.estadoInvalido }
        estado = .imprimiendoImpares
        do {
            try servicio.imprimir(trabajo, extra: ["-o", "page-set=odd"])
        } catch {
            estado = .idle
            throw error
        }
        // Con una sola cara no hay dorso que imprimir.
        if caras == 1 {
            estado = .listo
            return
        }
        var aviso: String?
        if caras % 2 == 1 {
            aviso = trabajo.paginasPorHoja > 1
                ? String(localized: "Salen \(caras) caras: la última hoja va a quedar sin dorso.")
                : String(localized: "El documento tiene \(paginas) páginas: la última hoja va a quedar sin dorso.")
        }
        estado = .esperandoGiro(aviso: aviso)
    }

    public func continuar() throws {
        guard case .esperandoGiro = estado else { throw PrintBroError.estadoInvalido }
        let anterior = estado
        estado = .imprimiendoPares
        var extra = ["-o", "page-set=even"]
        if ordenInverso { extra += ["-o", "outputorder=reverse"] }
        do {
            try servicio.imprimir(trabajo, extra: extra)
        } catch {
            // Vuelve a esperar el giro para poder reintentar.
            estado = anterior
            throw error
        }
        estado = .listo
    }

    /// Corta el flujo. No cancela trabajos que ya estén en la cola de CUPS.
    public func cancelar() {
        guard estado != .listo else { return }
        estado = .cancelado
    }
}
