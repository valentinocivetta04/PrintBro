import SwiftUI

/// Barra inferior: estado del trabajo y botones Cancelar / Imprimir.
struct BarraImpresionView: View {
    @Environment(PrintModel.self) private var modelo

    var body: some View {
        HStack(spacing: 12) {
            estado
            Spacer()
            Button("Cancelar", role: .cancel) { modelo.cancelar() }
                .disabled(modelo.archivo == nil || modelo.ocupado)
                .accessibilityHint(Text("Cierra el documento elegido"))
            Button("Imprimir") { modelo.imprimir() }
                .buttonStyle(.borderedProminent)
                .disabled(!modelo.puedeImprimir)
                .help("Imprimir (⌘P)")
        }
        .controlSize(.large)
        .bordeControl()
        .padding(.horizontal, Estilo.Espacio.medio)
        .padding(.vertical, Estilo.Espacio.chico)
        .fondoEncabezado()
        .overlay(alignment: .top) { Divider() }
    }

    @ViewBuilder private var estado: some View {
        if let texto = modelo.fase.textoProgreso {
            ProgressView()
                .controlSize(.small)
            Text(texto)
                .accessibilityAddTraits(.updatesFrequently)
        } else if let aviso = modelo.avisoTrabajo {
            Label(aviso, systemImage: "bell")
                .lineLimit(2)
            Button {
                modelo.avisoTrabajo = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text("Cerrar aviso"))
        } else if case .listo(let mensaje) = modelo.fase {
            Label {
                Text(mensaje)
            } icon: {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            }
        } else if modelo.simulacion {
            Label("Modo simulación: no se imprime nada", systemImage: "testtube.2")
                .foregroundStyle(.secondary)
        }
    }
}
