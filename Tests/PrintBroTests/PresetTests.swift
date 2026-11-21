import Foundation
import Testing
@testable import PrintBroCore

private func almacenVacio() -> PresetStore {
    PresetStore(defaults: UserDefaults(suiteName: "printbro.tests.\(UUID().uuidString)")!)
}

private func configuracionDePrueba() -> Configuracion {
    var c = Configuracion()
    c.impresora = "Brother_HL_1210W_series"
    c.copias = 2
    c.rangoPaginas = "1-3"
    c.orientacion = .horizontal
    c.tamanioPapel = "A4"
    c.paginasPorHoja = 4
    c.opcionesDriver = ["TonerSaveMode": "ON"]
    return c
}

@Test func guardarYCargarPreset() throws {
    let almacen = almacenVacio()
    try almacen.guardar(Preset(nombre: " Apuntes ", configuracion: configuracionDePrueba()))
    let presets = almacen.todos()
    #expect(presets.count == 1)
    #expect(presets[0].nombre == "Apuntes")
    var esperada = configuracionDePrueba()
    esperada.rangoPaginas = nil  // el rango no se guarda en presets
    #expect(presets[0].configuracion == esperada)
}

@Test func mismoNombreReemplazaYOrdena() throws {
    let almacen = almacenVacio()
    try almacen.guardar(Preset(nombre: "Zeta", configuracion: Configuracion()))
    try almacen.guardar(Preset(nombre: "apuntes", configuracion: Configuracion()))
    var otra = Configuracion()
    otra.copias = 3
    try almacen.guardar(Preset(nombre: "Zeta", configuracion: otra))
    #expect(almacen.todos().map(\.nombre) == ["apuntes", "Zeta"])
    #expect(almacen.todos()[1].configuracion.copias == 3)
}

@Test func borrarPreset() throws {
    let almacen = almacenVacio()
    try almacen.guardar(Preset(nombre: "A", configuracion: Configuracion()))
    try almacen.guardar(Preset(nombre: "B", configuracion: Configuracion()))
    try almacen.borrar(nombre: "A")
    #expect(almacen.todos().map(\.nombre) == ["B"])
}

@Test func presetSinNombreDaError() {
    #expect(throws: PrintBroError.presetSinNombre) {
        try almacenVacio().guardar(Preset(nombre: "   ", configuracion: Configuracion()))
    }
}
