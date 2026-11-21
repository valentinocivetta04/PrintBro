import Foundation
import Observation
import UserNotifications
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
            // El doble faz manual imprime el documento entero, una copia.
            if dobleFaz {
                copias = 1
                paginas = .todas
            } else {
                folleto = false
            }
        }
    }
    /// El folleto siempre va con doble faz manual y arma sus propias 2 páginas por cara.
    var folleto = false {
        didSet {
            if folleto {
                dobleFaz = true
                paginasPorHoja = 1
            }
        }
    }
    /// PDFs temporales (folleto, imágenes convertidas). Se borran al terminar el trabajo.
    private var temporales: [URL] = []
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
    private(set) var estadoImpresora: EstadoImpresora?
    private(set) var trabajosCola: [TrabajoCola] = []
    var seleccionCola: Set<Int> = []
    var confirmandoCancelarTodos = false
    private let almacenHistorial = HistorialStore()
    private(set) var historial: [EntradaHistorial] = []
    private let almacenPresets = PresetStore()
    private(set) var presets: [Preset] = []
    var pidiendoNombrePreset = false
    var nombrePreset = ""
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
        presets = almacenPresets.todos()
        historial = almacenHistorial.todas()
    }

    // MARK: Estado de la impresora

    /// Lectura local de CUPS (rápida): se llama desde .task de las pantallas mientras se ven.
    func actualizarEstado() {
        estadoImpresora = impresora.isEmpty ? nil : PrinterService.estado(de: impresora)
    }

    func actualizarCola() {
        if simulacion { FileHandle.standardError.write(Data("[simulación] consulta cola\n".utf8)) }
        trabajosCola = impresora.isEmpty ? [] : PrinterService.trabajos(de: impresora)
        seleccionCola = seleccionCola.intersection(trabajosCola.map(\.id))
    }

    func cancelarSeleccionados() {
        let elegidos = trabajosCola.filter { seleccionCola.contains($0.id) }
        let servicio = self.servicio
        enSegundoPlano({ for trabajo in elegidos { try servicio.cancelar(trabajo) } }) { [weak self] _ in
            self?.actualizarCola()
        }
    }

    func cancelarTodos() {
        let servicio = self.servicio, impresora = self.impresora
        enSegundoPlano({ try servicio.cancelarTodos(de: impresora) }) { [weak self] _ in
            self?.actualizarCola()
        }
    }

    var confirmandoPaginaPrueba = false
    private(set) var imprimiendoPaginaPrueba = false

    /// Una hoja con el nombre de la impresora y la fecha. El PDF temporal se borra cuando lp termina.
    func imprimirPaginaPrueba() {
        guard !impresora.isEmpty, !imprimiendoPaginaPrueba else { return }
        let url: URL
        do {
            url = try PaginaPrueba.generar(impresora: impresora)
        } catch {
            mensajeError = error.localizedDescription
            return
        }
        imprimiendoPaginaPrueba = true
        let servicio = self.servicio
        var paraEnviar = PrintJob(archivo: url, impresora: impresora)
        paraEnviar.titulo = String(localized: "Página de prueba")
        let trabajo = paraEnviar
        let idAntes = Seguimiento.ultimoId(de: impresora)
        enSegundoPlano({ try servicio.imprimir(trabajo) }) { [weak self] ok in
            try? FileManager.default.removeItem(at: url)
            self?.imprimiendoPaginaPrueba = false
            if ok { self?.seguir(despuesDe: idAntes, archivo: String(localized: "Página de prueba")) }
        }
    }

    /// Repite `accion` cada `segundos` hasta que SwiftUI cancela la tarea (la pantalla se deja de ver).
    func refrescarMientrasSeVe(cada segundos: Double, _ accion: () -> Void) async {
        while !Task.isCancelled {
            accion()
            try? await Task.sleep(for: .seconds(segundos))
        }
    }

    // MARK: Historial

    private func registrar(_ entrada: EntradaHistorial) {
        do {
            try almacenHistorial.agregar(entrada)
            historial = almacenHistorial.todas()
        } catch {
            mensajeError = error.localizedDescription
        }
    }

    /// Vuelve a mandar un trabajo del historial con las mismas opciones.
    func reimprimir(_ entrada: EntradaHistorial) {
        guard FileManager.default.fileExists(atPath: entrada.archivo.path) else {
            mensajeError = PrintBroError.archivoNoEncontrado(entrada.archivo.lastPathComponent).localizedDescription
            return
        }
        abrir(entrada.archivo)
        guard archivo == entrada.archivo else { return }
        aplicar(entrada.configuracion)
        imprimir()
    }

    // MARK: Configuración, presets

    func configuracionActual() -> Configuracion {
        var c = Configuracion()
        c.impresora = impresora
        c.copias = copias
        c.rangoPaginas = paginas == .rango ? rango : nil
        c.orientacion = switch orientacion {
        case .automatica: nil
        case .vertical: .vertical
        case .horizontal: .horizontal
        }
        c.tamanioPapel = tamanioPapel.isEmpty ? nil : tamanioPapel
        c.paginasPorHoja = paginasPorHoja
        c.opcionesDriver = valoresDriver
        c.dobleFaz = dobleFaz
        c.folleto = folleto
        return c
    }

    /// Carga una configuración guardada. Lo que el driver actual no ofrece se ignora.
    func aplicar(_ c: Configuracion) {
        // Primero la impresora: al cambiarla se recargan las opciones del driver.
        if impresoras.contains(where: { $0.nombre == c.impresora }) { impresora = c.impresora }
        dobleFaz = c.dobleFaz
        folleto = c.folleto
        copias = c.copias
        paginasPorHoja = PrintJob.paginasPorHojaPosibles.contains(c.paginasPorHoja) ? c.paginasPorHoja : 1
        if let r = c.rangoPaginas {
            paginas = .rango
            rango = r
        } else {
            paginas = .todas
        }
        orientacion = switch c.orientacion {
        case nil: .automatica
        case .vertical: .vertical
        case .horizontal: .horizontal
        }
        if let papel = c.tamanioPapel, tamanios.contains(papel) { tamanioPapel = papel }
        for opcion in opcionesExtra {
            if let valor = c.opcionesDriver[opcion.clave], opcion.valores.contains(valor) {
                valoresDriver[opcion.clave] = valor
            }
        }
    }

    func pedirNombrePreset() {
        nombrePreset = ""
        pidiendoNombrePreset = true
    }

    func guardarPreset() {
        do {
            try almacenPresets.guardar(Preset(nombre: nombrePreset, configuracion: configuracionActual()))
            presets = almacenPresets.todos()
        } catch {
            mensajeError = error.localizedDescription
        }
    }

    func cargarPreset(_ preset: Preset) {
        aplicar(preset.configuracion)
    }

    func borrarPreset(_ preset: Preset) {
        do {
            try almacenPresets.borrar(nombre: preset.nombre)
            presets = almacenPresets.todos()
        } catch {
            mensajeError = error.localizedDescription
        }
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
    }

    /// Mensaje para mostrar bajo el campo de rango mientras se escribe (nil si está bien).
    var errorRango: String? {
        guard paginas == .rango else { return nil }
        do {
            _ = try RangoPaginas.validar(rango, total: paginasDocumento)
            return nil
        } catch {
            return error.localizedDescription
        }
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
        // A4 si el driver lo ofrece (el driver de Brother trae Letter por defecto).
        tamanioPapel = tamanios.contains("A4")
            ? "A4"
            : opciones.first { $0.clave == "PageSize" }?.porDefecto ?? tamanios.first ?? ""
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
        var trabajo: PrintJob
        var paginasAImprimir = paginasDocumento ?? 0
        do {
            trabajo = try armarTrabajo(archivo)
            if folleto {
                let temporal = try Folleto.generar(desde: archivo)
                temporales.append(temporal)
                trabajo.archivo = temporal
                trabajo.ajustarAPagina = true
                trabajo.orientacion = nil
                paginasAImprimir = Folleto.orden(paginas: paginasAImprimir).count / 2
            } else if ImagenAPDF.esImagen(archivo) {
                let temporal = try ImagenAPDF.convertir(archivo)
                temporales.append(temporal)
                trabajo.archivo = temporal
                trabajo.ajustarAPagina = true
            }
            // Si se manda un temporal, la cola muestra igual el nombre del archivo elegido.
            if trabajo.archivo != archivo { trabajo.titulo = archivo.lastPathComponent }
        } catch {
            borrarTemporales()
            mensajeError = error.localizedDescription
            return
        }
        let entrada = EntradaHistorial(archivo: archivo, configuracion: configuracionActual())
        let idAntes = Seguimiento.ultimoId(de: impresora)
        guard dobleFaz else {
            fase = .enviando
            let servicio = self.servicio
            let trabajoFinal = trabajo
            enSegundoPlano({ try servicio.imprimir(trabajoFinal) }) { [weak self] ok in
                if ok {
                    self?.registrar(entrada)
                    self?.seguir(despuesDe: idAntes, archivo: archivo.lastPathComponent)
                }
                // lp ya copió el archivo a la cola de CUPS: el temporal se puede borrar.
                self?.borrarTemporales()
                self?.fase = ok ? .listo(String(localized: "Listo: el trabajo se mandó a la impresora.")) : .nada
            }
            return
        }
        do {
            let nuevo = try DuplexManual(trabajo: trabajo, paginas: paginasAImprimir, servicio: servicio)
            nuevo.ordenInverso = ordenInverso
            duplex = nuevo
            fase = .imprimiendoImpares
            let caja = Caja(valor: nuevo)
            enSegundoPlano({ try caja.valor.empezar() }) { [weak self] ok in
                // Se registra cuando ya salió la primera tanda.
                if ok {
                    self?.registrar(entrada)
                    self?.seguir(despuesDe: idAntes, archivo: archivo.lastPathComponent)
                }
                self?.sincronizarDuplex()
            }
        } catch {
            borrarTemporales()
            mensajeError = error.localizedDescription
        }
    }

    private func borrarTemporales() {
        for url in temporales { try? FileManager.default.removeItem(at: url) }
        temporales = []
    }

    func continuarDuplex() {
        guard mostrandoGiro, let duplex else { return }
        duplex.ordenInverso = ordenInverso
        fase = .imprimiendoPares
        let caja = Caja(valor: duplex)
        let idAntes = Seguimiento.ultimoId(de: impresora)
        let nombre = archivo?.lastPathComponent ?? ""
        enSegundoPlano({ try caja.valor.continuar() }) { [weak self] ok in
            if ok { self?.seguir(despuesDe: idAntes, archivo: nombre) }
            self?.sincronizarDuplex()
        }
    }

    // MARK: Avisos de trabajos terminados

    private struct SinPermisoDeNotificaciones: Error {}

    /// id del trabajo → (cola, nombre del archivo que eligió el usuario).
    private var seguidos: [Int: (impresora: String, archivo: String)] = [:]
    private var tareaSeguimiento: Task<Void, Never>?
    /// Aviso dentro de la ventana cuando las notificaciones del sistema no están disponibles.
    var avisoTrabajo: String?

    private func seguir(despuesDe id: Int, archivo: String) {
        if simulacion {
            // No hay trabajo real en CUPS: se manda el aviso igual para probar las notificaciones.
            notificar(String(localized: "Impresión terminada"),
                      String(localized: "«\(archivo)» ya salió de la impresora (simulación)."))
            return
        }
        for trabajo in Seguimiento.nuevos(PrinterService.trabajos(de: impresora, activos: false), despuesDe: id) {
            seguidos[trabajo.id] = (impresora, archivo)
        }
        guard tareaSeguimiento == nil, !seguidos.isEmpty else { return }
        tareaSeguimiento = Task { [weak self] in
            while let self, !self.seguidos.isEmpty {
                try? await Task.sleep(for: .seconds(2))
                self.revisarSeguidos()
            }
            self?.tareaSeguimiento = nil
        }
    }

    private func revisarSeguidos() {
        for (id, dato) in seguidos {
            let trabajos = PrinterService.trabajos(de: dato.impresora, activos: false)
            guard let trabajo = trabajos.first(where: { $0.id == id }) else {
                seguidos[id] = nil  // CUPS ya no lo tiene: no hay nada que avisar
                continue
            }
            if let aviso = Seguimiento.aviso(para: trabajo.estado, archivo: dato.archivo) {
                seguidos[id] = nil
                notificar(aviso.titulo, aviso.cuerpo)
            }
        }
    }

    /// Notificación del sistema; si no se puede (app firmada ad-hoc, permiso negado), aviso en la ventana.
    private func notificar(_ titulo: String, _ cuerpo: String) {
        Task {
            do {
                let centro = UNUserNotificationCenter.current()
                guard try await centro.requestAuthorization(options: [.alert, .sound]) else {
                    throw SinPermisoDeNotificaciones()
                }
                let contenido = UNMutableNotificationContent()
                contenido.title = titulo
                contenido.body = cuerpo
                contenido.sound = .default
                try await centro.add(UNNotificationRequest(identifier: UUID().uuidString, content: contenido, trigger: nil))
                FileHandle.standardError.write(Data("[notificación] enviada: \(titulo)\n".utf8))
            } catch {
                FileHandle.standardError.write(Data("[notificación] no disponible (\(error)); aviso en la ventana\n".utf8))
                avisoTrabajo = "\(titulo). \(cuerpo)"
            }
        }
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
            borrarTemporales()
        case .imprimiendoImpares:
            fase = .imprimiendoImpares
        case .esperandoGiro(let aviso):
            fase = .esperandoGiro(aviso: aviso)
        case .imprimiendoPares:
            fase = .imprimiendoPares
        case .listo:
            fase = .listo(duplex.caras == 1
                ? String(localized: "Listo: sale una sola cara, no hizo falta girar la hoja.")
                : String(localized: "Listo: se imprimieron las dos caras."))
            self.duplex = nil
            borrarTemporales()
        }
    }

    private func armarTrabajo(_ archivo: URL) throws -> PrintJob {
        var trabajo = PrintJob(archivo: archivo, impresora: impresora)
        trabajo.copias = copias
        if paginas == .rango {
            trabajo.rangoPaginas = try RangoPaginas.validar(rango, total: paginasDocumento)
        }
        trabajo.orientacion = switch orientacion {
        case .automatica: nil
        case .vertical: .vertical
        case .horizontal: .horizontal
        }
        trabajo.tamanioPapel = tamanioPapel.isEmpty ? nil : tamanioPapel
        trabajo.paginasPorHoja = paginasPorHoja
        // PageSize va aparte (tamanioPapel); del resto solo lo que el usuario cambió.
        trabajo.opcionesDriver = PrinterService.opcionesCambiadas(opcionesExtra, valores: valoresDriver)
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
