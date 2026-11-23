import SwiftUI

struct GiroHojasSheet: View {
    @Environment(PrintModel.self) private var modelo

    var body: some View {
        VStack(alignment: .leading, spacing: Estilo.Espacio.medio) {
            Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                .font(.largeTitle)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text("Girá las hojas, volvelas a poner en la bandeja y tocá Continuar")
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)

            Text("Esperá a que termine de salir la primera tanda antes de sacar las hojas.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if case .esperandoGiro(let aviso?) = modelo.fase {
                Label {
                    Text(aviso)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill").symbolRenderingMode(.multicolor)
                }
                .fixedSize(horizontal: false, vertical: true)
                .tarjeta()
            }

            HStack {
                Spacer()
                Button("Cancelar", role: .cancel) { modelo.cancelarDuplex() }
                    .keyboardShortcut(.cancelAction)
                    .accessibilityHint(Text("No imprime las hojas pares"))
                Button("Continuar") { modelo.continuarDuplex() }
                    .keyboardShortcut(.defaultAction)
                    .accessibilityHint(Text("Imprime las hojas pares"))
            }
            .controlSize(.large)
            .bordeControl()
        }
        .padding(Estilo.Espacio.grande)
        .frame(width: 440)
        .fondoPanel()
    }
}
