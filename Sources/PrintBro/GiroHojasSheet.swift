import SwiftUI

struct GiroHojasSheet: View {
    @Environment(PrintModel.self) private var modelo

    var body: some View {
        VStack(alignment: .leading, spacing: Estilo.Espacio.medio) {
            Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                .font(Estilo.Tipo.titulo)
                .foregroundStyle(Estilo.Paleta.primario)
                .accessibilityHidden(true)

            Text("Girá las hojas, volvelas a poner en la bandeja y tocá Continuar")
                .fontWeight(.semibold)
                .fixedSize(horizontal: false, vertical: true)

            Text("Esperá a que termine de salir la primera tanda antes de sacar las hojas.")
                .textoAtenuado()
                .fixedSize(horizontal: false, vertical: true)

            if case .esperandoGiro(let aviso?) = modelo.fase {
                Label {
                    Text(aviso)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Estilo.Paleta.avisoIcono)
                }
                .fixedSize(horizontal: false, vertical: true)
                .cajaAviso(Estilo.Paleta.aviso)
            }

            HStack {
                Spacer()
                Button("Cancelar", role: .cancel) { modelo.cancelarDuplex() }
                    .keyboardShortcut(.cancelAction)
                    .accessibilityHint(Text("No imprime las hojas pares"))
                    .buttonStyle(.peligroAccion)
                Button("Continuar") { modelo.continuarDuplex() }
                    .keyboardShortcut(.defaultAction)
                    .accessibilityHint(Text("Imprime las hojas pares"))
                    .buttonStyle(.primarioAccion)
            }
        }
        .padding(Estilo.Espacio.seccion)
        .frame(width: Estilo.Medida.anchoHoja)
        .fondoPanel()
    }
}
