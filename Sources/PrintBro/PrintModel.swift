import Foundation
import Observation
import PrintBroCore

enum Paginas: Hashable {
    case todas, rango
}

enum OrientacionElegida: Hashable {
    case automatica, vertical, horizontal
}

enum Fase: Equatable {
    case nada
    case enviando
    case imprimiendoImpares
    case esperandoGiro(aviso: String?)
    case imprimiendoPares
    case listo(String)

    var textoProgreso: String? {
        switch self {
        case .enviando: String(localized: "Enviando a la impresora…")
        case .imprimiendoImpares: String(localized: "Imprimiendo hojas impares…")
        case .imprimiendoPares: String(localized: "Imprimiendo hojas pares…")
        default: nil
        }
    }
}

extension Impresora {
    var nombreVisible: String { nombre.replacingOccurrences(of: "_", with: " ") }
}

/// DuplexManual no es Sendable; acá se usa desde una sola tarea por vez.
private struct Caja<T>: @unchecked Sendable {
    let valor: T
}

/// Estado de la app y acciones. Las vistas solo leen y llaman a esto.
@MainActor
@Observable
final class PrintModel {
    // Misma clave que usa DuplexManual para recordar el orden inverso.
    static let claveOrdenInverso = "duplexOrdenInversoPares"
    static let claveImpresoraPreferida = "impresoraPreferida"

    let simulacion: Bool
    private let servicio: PrinterService

    var seccion: Seccion? = .imprimir
    private(set) var impresoras: [Impresora] = []
    var impresora = "" {
        didSet { if impresora != oldValue { cargarOpciones() } }
    }
    private(set) var opciones: [OpcionDriver] = []

    private(set) var archivo: URL?
    private(set) var paginasDocumento: Int?
    var copias = 1
    var paginas = Paginas.todas
    var rango = ""
    var orientacion = OrientacionElegida.automatica
    var tamanioPapel = ""
    var paginasPorHoja = 1
    var valoresDriver: [String: String] = [:]
    var dobleFaz = false {
        didSet {
            // El doble faz manual imprime el documento entero, una copia, una página por hoja.
            if dobleFaz {
                copias = 1
                paginasPorHoja = 1
                paginas = .todas
            }
        }
    }
    var ordenInverso: Bool {
        didSet { UserDefaults.standard.set(ordenInverso, forKey: Self.claveOrdenInverso) }
    }
    var impresoraPreferida: String {
        didSet {
            UserDefaults.standard.set(impresoraPreferida, forKey: Self.claveImpresoraPreferida)
            if impresoras.contains(where: { $0.nombre == impresoraPreferida }) {
                impresora = impresoraPreferida
            }
        }
    }

    private(set) var fase = Fase.nada
    var mensajeError: String?
    var mostrarImportador = false
    // Estado visual del arrastre. Va acá y no en @State porque la macro de @State
    // (SwiftUIMacros) no viene con Command Line Tools.
    var arrastrandoEncima = false
    private var duplex: DuplexManual?

    init() {
        simulacion = ProcessInfo.processInfo.environment["PRINTBRO_DRY_RUN"] == "1"
        servicio = PrinterService(runner: simulacion ? DryRunRunner() : ProcessRunner())
        ordenInverso = UserDefaults.standard.object(forKey: Self.claveOrdenInverso) as? Bool ?? true
        impresoraPreferida = UserDefaults.standard.string(forKey: Self.claveImpresoraPreferida) ?? ""
        recargarImpresoras()
    }

    // MARK: Datos derivados

    var impresoraActual: Impresora? { impresoras.first { $0.nombre == impresora } }

    var avisoDriver: String? {
        impresoraActual.flatMap { PrinterService.avisoDriver($0.marcaYModelo) }
    }

    var tamanios: [String] { opciones.first { $0.clave == "PageSize" }?.valores ?? [] }

    /// Todo lo que ofrece el driver menos el tamaño, que tiene su propio control.
    var opcionesExtra: [OpcionDriver] { opciones.filter { $0.clave != "PageSize" } }

    var esPDF: Bool { archivo?.pathExtension.lowercased() == "pdf" }

    var ocupado: Bool { fase.textoProgreso != nil }

    var mostrandoGiro: Bool {
        if case .esperandoGiro = fase { return true }
        return false
    }

    var puedeImprimir: Bool {
        archivo != nil && !impresora.isEmpty && !ocupado && !mostrandoGiro
            && (paginas == .todas || !rango.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    // MARK: Impresoras

    func recargarImpresoras() {
        impresoras = PrinterService.impresoras()
        let elegida = impresoras.first { $0.nombre == impresoraPreferida }
            ?? impresoras.first(where: \.predeterminada)
            ?? impresoras.first
        impresora = elegida?.nombre ?? ""
    }

    private func cargarOpciones() {
        guard !impresora.isEmpty else {
            opciones = []
            return
        }
        do {
            opciones = try servicio.opciones(de: impresora)
        } catch {
            opciones = []
            mensajeError = error.localizedDescription
        }
        tamanioPapel = opciones.first { $0.clave == "PageSize" }?.porDefecto ?? tamanios.first ?? ""
        valoresDriver = [:]
        for opcion in opcionesExtra {
            valoresDriver[opcion.clave] = opcion.porDefecto ?? opcion.valores.first
        }
    }

    // MARK: Archivo

    func pedirArchivo() {
        seccion = .imprimir
        mostrarImportador = true
    }

    func abrir(_ url: URL) {
        guard !ocupado, !mostrandoGiro else { return }
        do {
            try TipoArchivo.validar(url)
            paginasDocumento = url.pathExtension.lowercased() == "pdf"
                ? try DuplexManual.contarPaginas(url)
                : nil
        } catch {
            mensajeError = error.localizedDescription
            return
        }
        archivo = url
        seccion = .imprimir
        fase = .nada
        if !esPDF { dobleFaz = false }
    }

    func cancelar() {
        if mostrandoGiro {
            cancelarDuplex()
            return
        }
        archivo = nil
        paginasDocumento = nil
        dobleFaz = false
        fase = .nada
    }

    // MARK: Impresión

    func imprimir() {
        guard puedeImprimir, let archivo else { return }
        let trabajo = armarTrabajo(archivo)
        guard dobleFaz else {
            fase = .enviando
            let servicio = self.servicio
            enSegundoPlano({ try servicio.imprimir(trabajo) }) { [weak self] ok in
                self?.fase = ok ? .listo(String(localized: "Listo: el trabajo se mandó a la impresora.")) : .nada
            }
            return
        }
        do {
            let nuevo = try DuplexManual(trabajo: trabajo, paginas: paginasDocumento ?? 0, servicio: servicio)
            nuevo.ordenInverso = ordenInverso
            duplex = nuevo
            fase = .imprimiendoImpares
            let caja = Caja(valor: nuevo)
            enSegundoPlano({ try caja.valor.empezar() }) { [weak self] _ in self?.sincronizarDuplex() }
        } catch {
            mensajeError = error.localizedDescription
        }
    }

    func continuarDuplex() {
        guard mostrandoGiro, let duplex else { return }
        duplex.ordenInverso = ordenInverso
        fase = .imprimiendoPares
        let caja = Caja(valor: duplex)
        enSegundoPlano({ try caja.valor.continuar() }) { [weak self] _ in self?.sincronizarDuplex() }
    }

    func cancelarDuplex() {
        duplex?.cancelar()
        sincronizarDuplex()
    }

    private func sincronizarDuplex() {
        guard let duplex else { return }
        switch duplex.estado {
        case .idle, .cancelado:
            fase = .nada
            self.duplex = nil
        case .imprimiendoImpares:
            fase = .imprimiendoImpares
        case .esperandoGiro(let aviso):
            fase = .esperandoGiro(aviso: aviso)
        case .imprimiendoPares:
            fase = .imprimiendoPares
        case .listo:
            fase = .listo(duplex.paginas == 1
                ? String(localized: "Listo: el documento tiene una sola página, no hizo falta girar la hoja.")
                : String(localized: "Listo: se imprimieron las dos caras."))
            self.duplex = nil
        }
    }

    private func armarTrabajo(_ archivo: URL) -> PrintJob {
        var trabajo = PrintJob(archivo: archivo, impresora: impresora)
        trabajo.copias = copias
        if paginas == .rango {
            trabajo.rangoPaginas = rango.replacingOccurrences(of: " ", with: "")
        }
        trabajo.orientacion = switch orientacion {
        case .automatica: nil
        case .vertical: .vertical
        case .horizontal: .horizontal
        }
        trabajo.tamanioPapel = tamanioPapel.isEmpty ? nil : tamanioPapel
        trabajo.paginasPorHoja = paginasPorHoja
        // Solo se mandan las opciones que el usuario cambió.
        for opcion in opcionesExtra {
            if let valor = valoresDriver[opcion.clave], valor != opcion.porDefecto {
                trabajo.opcionesDriver[opcion.clave] = valor
            }
        }
        return trabajo
    }

    /// lp puede tardar (o el runner de simulación espera): se corre fuera del hilo principal.
    private func enSegundoPlano(_ trabajo: @escaping @Sendable () throws -> Void,
                                despues: @escaping @MainActor (Bool) -> Void) {
        Task {
            do {
                try await Task.detached { try trabajo() }.value
                despues(true)
            } catch {
                mensajeError = error.localizedDescription
                despues(false)
            }
        }
    }
}
