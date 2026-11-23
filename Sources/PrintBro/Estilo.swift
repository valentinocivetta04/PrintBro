import AppKit
import SwiftUI

/// Tokens de design.md ("macOS Vibrancy") con la paleta violeta.
/// Estructura literal del archivo (transparencias, radios, tipografía); solo cambian los colores.
enum Estilo {
    /// Cada token tiene un valor claro y uno oscuro, y se resuelve según la apariencia de la ventana.
    enum Paleta {
        static let fondo = par(.hex(0xe8e2f4), .hex(0x1c1530))
        static let superficie = par(.blanco(0.55), .blanco(0.10))
        static let superficieFuerte = par(.blanco(0.78), .blanco(0.16))
        static let borde = par(.negro(0.08), .blanco(0.12))
        static let texto = par(.hex(0x1d1d1f), .hex(0xf5f3fa))
        /// En claro 0.64 en lugar de 0.6: con 0.6 daba 4.1:1 sobre el fondo (WCAG AA pide 4.5).
        static let textoAtenuado = par(.hex(0x1d1d1f, 0.64), .hex(0xf5f3fa, 0.6))
        static let primario = par(.hex(0xaf52de), .hex(0xbf5af2))
        static let acento = par(.hex(0x7d7aff), .hex(0x7d7aff))
        static let peligro = par(.hex(0xff3b30), .hex(0xff453a))
        static let velo = par(.blanco(0.4), .blanco(0.06))
        /// Tiñe de violeta los materiales del sistema, que solos son grises.
        static let tinte = par(.hex(0xe8e2f4, 0.5), .hex(0x1c1530, 0.6))
        static let sombra = par(.negro(0.08), .negro(0.3))
        /// on-primary, on-accent y on-surface: negro en design.md.
        static let sobreColor = par(.hex(0x000000), .hex(0x000000))

        struct Tono: Sendable {
            let rojo, verde, azul, alfa: Double

            static func hex(_ valor: UInt32, _ alfa: Double = 1) -> Tono {
                Tono(rojo: Double(valor >> 16 & 0xff) / 255, verde: Double(valor >> 8 & 0xff) / 255,
                     azul: Double(valor & 0xff) / 255, alfa: alfa)
            }
            static func blanco(_ alfa: Double) -> Tono { Tono(rojo: 1, verde: 1, azul: 1, alfa: alfa) }
            static func negro(_ alfa: Double) -> Tono { Tono(rojo: 0, verde: 0, azul: 0, alfa: alfa) }

            var nsColor: NSColor { NSColor(srgbRed: rojo, green: verde, blue: azul, alpha: alfa) }
        }

        private static func par(_ claro: Tono, _ oscuro: Tono) -> Color {
            Color(nsColor: NSColor(name: nil) { apariencia in
                apariencia.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? oscuro.nsColor : claro.nsColor
            })
        }
    }

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
        /// Padding de "card" en design.md.
        static let tarjeta: CGFloat = 24
        static let borde: CGFloat = 1
        static let anilloFoco: CGFloat = 2
    }

    enum Tipo {
        /// h1: 4rem = 64 pt, peso 700, interlineado 1.05.
        static let tamanioTitulo: CGFloat = 64
        static let titulo = Font.system(size: tamanioTitulo, weight: .bold)
        static let interlineadoTitulo = extra(tamanioTitulo, alto: 1.05)
        /// body-md: 1rem = 16 pt, peso 400, interlineado 1.6.
        static let tamanioCuerpo: CGFloat = 16
        static let cuerpo = Font.system(size: tamanioCuerpo, weight: .regular)
        static let interlineadoCuerpo = extra(tamanioCuerpo, alto: 1.6)
        /// label-caps: 0.75rem = 12 pt, peso 600, tracking 0.06em.
        static let tamanioEtiqueta: CGFloat = 12
        static let etiqueta = Font.system(size: tamanioEtiqueta, weight: .semibold)
        static let trackingEtiqueta = tamanioEtiqueta * 0.06

        /// SwiftUI no tiene line-height: se suma la diferencia con el alto natural de SF.
        private static func extra(_ tamanio: CGFloat, alto: CGFloat) -> CGFloat {
            let fuente = NSFont.systemFont(ofSize: tamanio)
            let natural = fuente.ascender - fuente.descender + fuente.leading
            return max(tamanio * alto - natural, 0)
        }
    }

    /// Criterio propio: design.md pide sombras pero no da valores.
    enum Sombra {
        static let color = Estilo.Paleta.sombra
        static let radio: CGFloat = 12
        static let desplazamiento: CGFloat = 2
    }

    enum Estado {
        static let brilloHover = 0.06
        static let brilloPresionado = -0.08
        static let opacidadDeshabilitado = 0.4
    }

    /// Título de pantalla: si 64 pt no entra, se achica hasta la mitad como mucho.
    static let escalaMinimaTitulo: CGFloat = 0.5
}

/// Línea de 1 pt con el color border, en lugar de Divider (que usa el color del sistema).
struct LineaBorde: View {
    var body: some View {
        Estilo.Paleta.borde.frame(height: Estilo.Espacio.borde)
    }
}

/// NSVisualEffectView: SwiftUI no deja elegir .sidebar / .headerView / .hudWindow.
struct MaterialSistema: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let mezcla: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let vista = NSVisualEffectView()
        // Siempre activo: si sigue a la ventana, al perder el foco queda gris plano.
        vista.state = .active
        updateNSView(vista, context: context)
        return vista
    }

    func updateNSView(_ vista: NSVisualEffectView, context: Context) {
        vista.material = material
        vista.blendingMode = mezcla
    }
}

/// Material del sistema + tinte violeta + velo. Con "Reducir transparencia" queda sobre bg, sólido.
private struct FondoMaterial: ViewModifier {
    let material: NSVisualEffectView.Material
    let mezcla: NSVisualEffectView.BlendingMode
    let velo: Color
    @Environment(\.accessibilityReduceTransparency) private var sinTransparencia

    func body(content: Content) -> some View {
        content.background {
            ZStack {
                Estilo.Paleta.fondo
                if !sinTransparencia {
                    MaterialSistema(material: material, mezcla: mezcla)
                }
                Estilo.Paleta.tinte
                velo
            }
            .ignoresSafeArea()
        }
    }
}

/// Superficie sobre bg: surface (0.55) o surface-strong (0.78), borde de 1 pt.
private struct Superficie: ViewModifier {
    let color: Color
    let radio: CGFloat
    let relleno: CGFloat
    let sombra: Bool
    /// Las tarjetas ocupan todo el ancho; los paneles respetan el ancho que les dan.
    let anchoCompleto: Bool

    func body(content: Content) -> some View {
        let forma = RoundedRectangle(cornerRadius: radio, style: .continuous)
        content
            .padding(relleno)
            .frame(maxWidth: anchoCompleto ? .infinity : nil, alignment: .leading)
            .foregroundStyle(Estilo.Paleta.texto)
            .background {
                // La sombra va en una base opaca de bg: si no, se ve a través de la superficie translúcida.
                forma.fill(Estilo.Paleta.fondo)
                    .shadow(color: sombra ? Estilo.Sombra.color : .clear,
                            radius: Estilo.Sombra.radio, y: Estilo.Sombra.desplazamiento)
                    .overlay { forma.fill(color) }
            }
            .overlay { forma.strokeBorder(Estilo.Paleta.borde, lineWidth: Estilo.Espacio.borde) }
    }
}

/// button-primary / button-secondary: fondo de color, texto negro, radio 10, padding 16.
struct BotonEstilo: ButtonStyle {
    let fondo: Color

    func makeBody(configuration: Configuration) -> some View {
        CuerpoBoton(configuration: configuration, fondo: fondo)
    }
}

/// Sin @State (falta el plugin de macros): el hover vive en un ObservableObject.
private final class Hover: ObservableObject {
    @Published var activo = false
}

private struct CuerpoBoton: View {
    let configuration: ButtonStyleConfiguration
    let fondo: Color
    @StateObject private var hover = Hover()
    @Environment(\.isEnabled) private var habilitado
    @Environment(\.isFocused) private var enfocado

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: Estilo.Radio.control, style: .continuous)
        configuration.label
            .font(Estilo.Tipo.cuerpo)
            .foregroundStyle(Estilo.Paleta.sobreColor)
            .padding(Estilo.Espacio.medio)
            .background(forma.fill(fondo))
            .brightness(brillo)
            .overlay {
                if enfocado {
                    forma.inset(by: -Estilo.Espacio.anilloFoco)
                        .stroke(Estilo.Paleta.texto, lineWidth: Estilo.Espacio.anilloFoco)
                }
            }
            .opacity(habilitado ? 1 : Estilo.Estado.opacidadDeshabilitado)
            .contentShape(forma)
            .onHover { hover.activo = $0 }
    }

    private var brillo: Double {
        if configuration.isPressed { return Estilo.Estado.brilloPresionado }
        return hover.activo && habilitado ? Estilo.Estado.brilloHover : 0
    }
}

extension ButtonStyle where Self == BotonEstilo {
    static var primario: BotonEstilo { BotonEstilo(fondo: Estilo.Paleta.primario) }
    static var secundario: BotonEstilo { BotonEstilo(fondo: Estilo.Paleta.acento) }
}

extension View {
    /// Raíz de cada ventana: solo claro, texto #1d1d1f, body-md y controles en azul primario.
    func estiloApp() -> some View {
        preferredColorScheme(.light)
            .tint(Estilo.Paleta.primario)
            // El segundo nivel es el que usan las vistas nativas para el texto secundario.
            .foregroundStyle(Estilo.Paleta.texto, Estilo.Paleta.textoAtenuado)
            .font(Estilo.Tipo.cuerpo)
            .lineSpacing(Estilo.Tipo.interlineadoCuerpo)
    }

    /// Fondo de página: bg #dfe6ee.
    func fondoPagina() -> some View {
        background { Estilo.Paleta.fondo.ignoresSafeArea() }
    }

    /// Barra lateral: material .sidebar que muestrea el escritorio + velo surface.
    func fondoBarraLateral() -> some View {
        modifier(FondoMaterial(material: .sidebar, mezcla: .behindWindow, velo: Estilo.Paleta.superficie))
    }

    /// Barras de arriba y abajo: material .headerView + velo surface.
    /// .behindWindow porque design.md pide que la barra muestree el escritorio; con .withinWindow
    /// no toma el contenido de SwiftUI y quedaba casi blanca (#fcfdfd medido).
    func fondoEncabezado() -> some View {
        modifier(FondoMaterial(material: .headerView, mezcla: .behindWindow, velo: Estilo.Paleta.superficie))
    }

    /// Paneles flotantes (hoja de giro): material .hudWindow + velo surface-strong.
    /// Con el scrim (0.4) quedaba gris (#e2e2e3 medido); con 0.78 se acerca a surface sobre bg.
    func fondoPanel() -> some View {
        modifier(FondoMaterial(material: .hudWindow, mezcla: .behindWindow, velo: Estilo.Paleta.superficieFuerte))
    }

    /// card: surface, radio 14, padding 24, sombra sutil.
    func tarjeta() -> some View {
        modifier(Superficie(color: Estilo.Paleta.superficie, radio: Estilo.Radio.tarjeta,
                            relleno: Estilo.Espacio.tarjeta, sombra: true, anchoCompleto: true))
    }

    /// Panel grande (opciones, tabla de la cola): surface-strong, sin padding propio.
    func panel() -> some View {
        modifier(Superficie(color: Estilo.Paleta.superficieFuerte, radio: Estilo.Radio.tarjeta,
                            relleno: 0, sombra: true, anchoCompleto: false))
    }

    /// "label-caps": 12 pt, semibold, mayúsculas, tracking 0.72 pt, text-muted.
    func etiquetaSeccion() -> some View {
        font(Estilo.Tipo.etiqueta)
            .textCase(.uppercase)
            .tracking(Estilo.Tipo.trackingEtiqueta)
            .foregroundStyle(Estilo.Paleta.textoAtenuado)
    }

    /// h1 de cada pantalla.
    func tituloPantalla() -> some View {
        font(Estilo.Tipo.titulo)
            .lineSpacing(Estilo.Tipo.interlineadoTitulo)
            .lineLimit(1)
            .minimumScaleFactor(Estilo.escalaMinimaTitulo)
            .foregroundStyle(Estilo.Paleta.texto)
            .accessibilityAddTraits(.isHeader)
    }

    /// Texto al pie de una sección de Form: text-muted, alineado a la izquierda.
    func pieSeccion() -> some View {
        textoAtenuado()
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Filas de Form sobre surface en lugar del gris del sistema.
    func filaSuperficie() -> some View {
        listRowBackground(Estilo.Paleta.superficie)
    }

    func textoAtenuado() -> some View {
        foregroundStyle(Estilo.Paleta.textoAtenuado)
    }
}
