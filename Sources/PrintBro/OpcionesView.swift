import SwiftUI

struct OpcionesView: View {
    @Environment(PrintModel.self) private var modelo

    var body: some View {
        @Bindable var modelo = modelo
        Form {
            Section("Impresora") {
                Picker("Impresora", selection: $modelo.impresora) {
                    ForEach(modelo.impresoras, id: \.nombre) { impresora in
                        Text(impresora.nombreVisible).tag(impresora.nombre)
                    }
                }
            }

            Section {
                Stepper("Copias: \(modelo.copias)", value: $modelo.copias, in: 1...99)
                    .disabled(modelo.dobleFaz)
                    .accessibilityValue(Text(modelo.copias, format: .number))
                Picker("Páginas", selection: $modelo.paginas) {
                    Text("Todas").tag(Paginas.todas)
                    Text("Rango").tag(Paginas.rango)
                }
                .pickerStyle(.segmented)
                .disabled(modelo.dobleFaz)
                if modelo.paginas == .rango {
                    TextField("Rango de páginas", text: $modelo.rango, prompt: Text("Ej.: 1-3, 5, 8-10"))
                }
            } header: {
                Text("Copias y páginas")
            } footer: {
                if let error = modelo.errorRango {
                    Label {
                        Text(error)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill").symbolRenderingMode(.multicolor)
                    }
                    .accessibilityLabel(Text("Rango inválido: \(error)"))
                }
            }

            Section("Diseño") {
                Picker("Orientación", selection: $modelo.orientacion) {
                    Text("Automática").tag(OrientacionElegida.automatica)
                    Text("Vertical").tag(OrientacionElegida.vertical)
                    Text("Horizontal").tag(OrientacionElegida.horizontal)
                }
                if !modelo.tamanios.isEmpty {
                    Picker("Tamaño de papel", selection: $modelo.tamanioPapel) {
                        ForEach(modelo.tamanios, id: \.self) { Text($0).tag($0) }
                    }
                }
                Picker("Páginas por hoja", selection: $modelo.paginasPorHoja) {
                    ForEach([1, 2, 4, 6, 9, 16], id: \.self) { Text($0, format: .number).tag($0) }
                }
                .disabled(modelo.dobleFaz)
            }

            Section {
                Toggle("Doble faz manual", isOn: $modelo.dobleFaz)
                    .disabled(!modelo.esPDF)
                Toggle("Imprimir las pares en orden inverso", isOn: $modelo.ordenInverso)
                    .disabled(!modelo.dobleFaz)
            } header: {
                Text("Doble faz manual")
            } footer: {
                if modelo.archivo != nil && !modelo.esPDF {
                    Text("Solo disponible para PDF.")
                } else {
                    Text("Primero salen las impares. Después girás las hojas y salen las pares.")
                }
            }

            if !modelo.opcionesExtra.isEmpty {
                Section("Opciones del driver") {
                    ForEach(modelo.opcionesExtra, id: \.clave) { opcion in
                        Picker(opcion.etiqueta, selection: valor(de: opcion.clave)) {
                            ForEach(opcion.valores, id: \.self) { Text($0).tag($0) }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .disabled(modelo.ocupado)
    }

    private func valor(de clave: String) -> Binding<String> {
        Binding(get: { modelo.valoresDriver[clave] ?? "" },
                set: { modelo.valoresDriver[clave] = $0 })
    }
}
