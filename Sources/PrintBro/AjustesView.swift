import SwiftUI

struct AjustesView: View {
    @Environment(PrintModel.self) private var modelo

    var body: some View {
        @Bindable var modelo = modelo
        Form {
            Section {
                Toggle("Imprimir las pares en orden inverso", isOn: $modelo.ordenInverso)
            } header: {
                Text("Doble faz manual").etiquetaSeccion()
            } footer: {
                Text("Con tu forma de girar la pila, esta opción deja cada página par en el dorso correcto.").pieSeccion()
            }
            .filaSuperficie()

            Section {
                Picker("Impresora predeterminada", selection: $modelo.impresoraPreferida) {
                    Text("La predeterminada del sistema").tag("")
                    ForEach(modelo.impresoras, id: \.nombre) { impresora in
                        Text(impresora.nombreVisible).tag(impresora.nombre)
                    }
                }
            } header: {
                Text("Impresora").etiquetaSeccion()
            } footer: {
                Text("Solo cambia la que elige PrintBro al abrir. No toca la configuración del sistema.").pieSeccion()
            }
            .filaSuperficie()
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .fondoPagina()
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
    }
}
