import AppKit
import SwiftUI

/// Tokens de design.md ("macOS Vibrancy") pasados a medidas de macOS.
enum Estilo {
    /// Radios: chips 8, botones y controles 10, tarjetas 14.
    enum Radio {
        static let chip: CGFloat = 8
        static let control: CGFloat = 10
        static let tarjeta: CGFloat = 14
    }

    enum Espacio {
        static let chico: CGFloat = 8
        static let medio: CGFloat = 16
        static let grande: CGFloat = 32
    }
}

/// NSVisualEffectView: el material del sistema que muestrea y desenfoca lo que hay atrás.
/// SwiftUI no deja elegir .sidebar / .headerView / .hudWindow con sus Material.
struct MaterialSistema: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let mezcla: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let vista = NSVisualEffectView()
        vista.state = .followsWindowActiveState
        updateNSView(vista, context: context)
        return vista
    }

    func updateNSView(_ vista: NSVisualEffectView, context: Context) {
        vista.material = material
        vista.blendingMode = mezcla
    }
}

/// Fondo de material con caída a color sólido si está activo "Reducir transparencia".
private struct FondoMaterial: ViewModifier {
    let material: NSVisualEffectView.Material
    let mezcla: NSVisualEffectView.BlendingMode
    @Environment(\.accessibilityReduceTransparency) private var sinTransparencia

    func body(content: Content) -> some View {
        content.background {
            if sinTransparencia {
                Color(nsColor: .windowBackgroundColor).ignoresSafeArea()
            } else {
                MaterialSistema(material: material, mezcla: mezcla).ignoresSafeArea()
            }
        }
    }
}

/// Tarjeta: material regular, radio 14 y borde finito del sistema.
private struct Tarjeta: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var sinTransparencia

    func body(content: Content) -> some View {
        let forma = RoundedRectangle(cornerRadius: Estilo.Radio.tarjeta, style: .continuous)
        content
            .padding(Estilo.Espacio.medio)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if sinTransparencia {
                    forma.fill(Color(nsColor: .controlBackgroundColor))
                } else {
                    forma.fill(.regularMaterial)
                }
            }
            .overlay { forma.strokeBorder(Color(nsColor: .separatorColor)) }
    }
}

extension View {
    /// Barra lateral y columna de opciones (mezcla con el escritorio).
    func fondoBarraLateral() -> some View {
        modifier(FondoMaterial(material: .sidebar, mezcla: .behindWindow))
    }

    /// Barras de arriba y abajo dentro de la ventana (mezcla con el contenido que pasa por atrás).
    func fondoEncabezado() -> some View {
        modifier(FondoMaterial(material: .headerView, mezcla: .withinWindow))
    }

    /// Paneles flotantes, como la hoja de giro.
    func fondoPanel() -> some View {
        modifier(FondoMaterial(material: .hudWindow, mezcla: .behindWindow))
    }

    func tarjeta() -> some View {
        modifier(Tarjeta())
    }

    /// "label-caps" de design.md: 12 pt, semibold, mayúsculas, tracking 0.06em (0.72 pt).
    /// En macOS el estilo de 12 pt es .callout (.caption es 10).
    func etiquetaSeccion() -> some View {
        font(.callout.weight(.semibold))
            .textCase(.uppercase)
            .tracking(0.72)
            .foregroundStyle(.secondary)
    }

    /// Botones con el radio de controles de design.md.
    func bordeControl() -> some View {
        buttonBorderShape(.roundedRectangle(radius: Estilo.Radio.control))
    }
}
