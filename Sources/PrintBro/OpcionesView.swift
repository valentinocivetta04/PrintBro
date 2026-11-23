import PrintBroCore
import SwiftUI

struct OpcionesView: View {
    @Environment(PrintModel.self) private var modelo

    var body: some View {
        @Bindable var modelo = modelo
        Form {
            Section {
                HStack {
                    Menu("Cargar") {
                        ForEach(modelo.presets) { preset in
                            Button(preset.nombre) { modelo.aplicar(preset.configuracion) }
                        }
                    }
                    .disabled(modelo.presets.isEmpty)
                    .accessibilityLabel(Text("Cargar preset"))
                    .menuStyle(.button)
                    .buttonStyle(.secundario)
                    Button("Guardar…") { modelo.pedirNombrePreset() }
                        .buttonStyle(.secundario)
                        .accessibilityLabel(Text("Guardar la configuración como preset"))
                    Menu("Borrar") {
                        ForEach(modelo.presets) { preset in
                            Button(preset.nombre, role: .destructive) { modelo.borrarPreset(preset) }
                        }
                    }
                    .disabled(modelo.presets.isEmpty)
                    .accessibilityLabel(Text("Borrar un preset"))
                    .menuStyle(.button)
                    .buttonStyle(.peligro)
                }
            } header: {
                Text("Presets").etiquetaSeccion()
            }
            .filaSuperficie()

            Section {
                Picker("Impresora", selection: $modelo.impresora) {
                    ForEach(modelo.impresoras, id: \.nombre) { impresora in
                        Text(impresora.nombreVisible).tag(impresora.nombre)
                    }
                }
            } header: {
                Text("Impresora").etiquetaSeccion()
            }
            .filaSuperficie()

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
                Text("Copias y páginas").etiquetaSeccion()
            } footer: {
                if let error = modelo.errorRango {
                    Label {
                        Text(error)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Estilo.Paleta.acento)
                    }
                    .foregroundStyle(Estilo.Paleta.texto)
                    .accessibilityLabel(Text("Rango inválido: \(error)"))
                }
            }
            .filaSuperficie()

            Section {
                Picker("Orientación", selection: $modelo.orientacion) {
                    Text("Automática").tag(Orientacion?.none)
                    Text("Vertical").tag(Orientacion?.some(.vertical))
                    Text("Horizontal").tag(Orientacion?.some(.horizontal))
                }
                if !modelo.tamanios.isEmpty {
                    Picker("Tamaño de papel", selection: $modelo.tamanioPapel) {
                        ForEach(modelo.tamanios, id: \.self) { Text($0).tag($0) }
                    }
                }
                Picker("Páginas por hoja", selection: $modelo.paginasPorHoja) {
                    ForEach(PrintJob.paginasPorHojaPosibles, id: \.self) { Text($0, format: .number).tag($0) }
                }
                .disabled(modelo.folleto)
            } header: {
                Text("Diseño").etiquetaSeccion()
            }
            .filaSuperficie()

            Section {
                Toggle("Doble faz manual", isOn: $modelo.dobleFaz)
                    .disabled(!modelo.esPDF)
                Toggle("Imprimir las pares en orden inverso", isOn: $modelo.ordenInverso)
                    .disabled(!modelo.dobleFaz)
                Toggle("Folleto (doblado al medio)", isOn: $modelo.folleto)
                    .disabled(!modelo.esPDF)
                    .accessibilityHint(Text("Reordena las páginas para doblar las hojas al medio"))
            } header: {
                Text("Doble faz manual").etiquetaSeccion()
            } footer: {
                if modelo.archivo != nil && !modelo.esPDF {
                    Text("Solo disponible para PDF.").pieSeccion()
                } else if modelo.folleto {
                    Text("Dos páginas por cara, en hojas apaisadas. Al terminar, doblá la pila al medio.").pieSeccion()
                } else {
                    Text("Primero salen las impares. Después girás las hojas y salen las pares.").pieSeccion()
                }
            }
            .filaSuperficie()

            if !modelo.opciones.isEmpty {
                // Una fila por opción que devuelve lpoptions -l, sin agregar ni sacar nada.
                Section {
                    ForEach(modelo.opciones, id: \.clave) { opcion in
                        Picker(opcion.etiqueta, selection: valor(de: opcion.clave)) {
                            ForEach(opcion.valores, id: \.self) { Text($0).tag($0) }
                        }
                        .help(opcion.clave)
                    }
                } header: {
                    Text("Avanzado").etiquetaSeccion()
                } footer: {
                    Text("Opciones que ofrece el driver de la impresora, con los nombres que trae el driver.").pieSeccion()
                }
                .filaSuperficie()
            }
        }
        .formStyle(.grouped)
        // Deja ver el material de la columna entre las tarjetas del formulario.
        .scrollContentBackground(.hidden)
        .foregroundStyle(Estilo.Paleta.texto)
        .disabled(modelo.ocupado)
        .alert("Guardar preset", isPresented: $modelo.pidiendoNombrePreset) {
            TextField("Nombre del preset", text: $modelo.nombrePreset)
            Button("Guardar") { modelo.guardarPreset() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Guarda impresora, copias, diseño, doble faz y opciones avanzadas. Si ya existe uno con ese nombre, lo reemplaza.")
        }
    }

    private func valor(de clave: String) -> Binding<String> {
        // El tamaño es el mismo valor que el Picker "Tamaño de papel" de Diseño.
        if clave == "PageSize" {
            return Binding(get: { modelo.tamanioPapel }, set: { modelo.tamanioPapel = $0 })
        }
        return Binding(get: { modelo.valoresDriver[clave] ?? "" },
                set: { modelo.valoresDriver[clave] = $0 })
    }
}
