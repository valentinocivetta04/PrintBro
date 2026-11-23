import AppKit
import SwiftUI

/// Tokens del sistema visual: referencia "macOS Vibrancy" con paleta violeta y escala compacta.
/// Las vistas toman colores, radios, espacios y tipografía de acá.
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
        /// Tiñe de violeta los materiales del sistema, que solos son grises.
        static let tinte = par(.hex(0xe8e2f4, 0.5), .hex(0x1c1530, 0.6))
        /// El HUD oscuro es más claro que los otros materiales (#605e6b medido con 0.6): lleva más tinte.
        static let tintePanel = par(.hex(0xe8e2f4, 0.5), .hex(0x1c1530, 0.85))
        static let sombra = par(.negro(0.08), .negro(0.3))
        /// Advertencias (tóner bajo, driver ajeno, hoja sin dorso): relleno y borde.
        static let aviso = par(.hex(0xffcc00), .hex(0xffd60a))
        /// Ícono de advertencia: #ffcc00 da 1.1:1 sobre su relleno en claro; #997a00 es el ámbar
        /// más claro que llega a 3:1.
        static let avisoIcono = par(.hex(0x997a00), .hex(0xffd60a))
        /// Ícono de error: el rojo en claro da 2.2:1 sobre su relleno; #e20c00 llega a 3:1.
        static let errorIcono = par(.hex(0xe20c00), .hex(0xff453a))
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

    /// Radios: chips y botones 8, cajas de aviso 10, tarjetas y paneles 14.
    enum Radio {
        static let chip: CGFloat = 8
        static let control: CGFloat = 10
        static let tarjeta: CGFloat = 14
    }

    /// Escala compacta (desvío deliberado de los tamaños web de design.md).
    enum Espacio {
        static let chico: CGFloat = 8
        static let medio: CGFloat = 16
        /// Entre secciones de un panel.
        static let seccion: CGFloat = 24
        static let grande: CGFloat = 32
        static let tarjeta: CGFloat = 16
        static let borde: CGFloat = 1
        static let anilloFoco: CGFloat = 2
        /// Alto mínimo de una fila de opciones.
        static let fila: CGFloat = 32
    }

    /// Medidas fijas de columnas y ventanas.
    enum Medida {
        static let anchoMinimoVistaPrevia: CGFloat = 380
        static let anchoOpciones: CGFloat = 350
        static let anchoAjustes: CGFloat = 480
        static let anchoAyuda: CGFloat = 460
        static let altoAyuda: CGFloat = 420
        static let anchoHoja: CGFloat = 440
    }

    /// Botones compactos (28 pt) y de acción de la barra inferior y la hoja (32 pt).
    enum Boton {
        static let altoCompacto: CGFloat = 28
        static let rellenoCompacto: CGFloat = 14
        static let altoAccion: CGFloat = 32
        static let rellenoAccion: CGFloat = 18
    }

    enum Tipo {
        /// Título de pantalla: 24 pt bold, interlineado 1.2.
        static let tamanioTitulo: CGFloat = 24
        static let titulo = Font.system(size: tamanioTitulo, weight: .bold)
        /// Cuerpo: 13 pt, interlineado 1.4.
        static let tamanioCuerpo: CGFloat = 13
        static let cuerpo = Font.system(size: tamanioCuerpo, weight: .regular)
        static let interlineadoCuerpo = extra(tamanioCuerpo, alto: 1.4)
        static let boton = Font.system(size: tamanioCuerpo, weight: .medium)
        /// Texto secundario: 12 pt.
        static let secundario = Font.system(size: 12, weight: .regular)
        /// label-caps: 11 pt, peso 600, tracking 0.06em.
        static let tamanioEtiqueta: CGFloat = 11
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
        static let radio: CGFloat = 12
        static let desplazamiento: CGFloat = 2
    }

    /// Luz de neón fina de todos los botones, del color de su relleno: una sombra difusa y otra
    /// pegada al borde, sin desplazamiento.
    enum Neon {
        static let opacidadAncha = 0.35
        static let radioAncho: CGFloat = 5
        static let opacidadBorde = 0.6
        static let radioBorde: CGFloat = 1
        /// El halo crece con el hover y se achica al presionar.
        static let escalaHover: CGFloat = 1.3
        static let escalaPresionado: CGFloat = 0.6
    }

    enum Estado {
        static let brilloHover = 0.06
        static let brilloPresionado = -0.08
        static let opacidadDeshabilitado = 0.4
        /// Fila seleccionada de la barra lateral: primario translúcido.
        static let opacidadSeleccion = 0.26
        /// Relleno y borde de advertencias y errores.
        static let opacidadRellenoAviso = 0.2
        static let opacidadBordeAviso = 0.5
    }
}

/// Línea de 1 pt con el color border, en lugar de Divider (que usa el color del sistema).
struct LineaBorde: View {
    var body: some View {
        Estilo.Paleta.borde.frame(height: Estilo.Espacio.borde)
    }
}

/// NSVisualEffectView: SwiftUI no deja elegir .sidebar / .headerView / .hudWindow.
/// Siempre .behindWindow: muestrea el escritorio (con .withinWindow no toma el contenido de SwiftUI).
struct MaterialSistema: NSViewRepresentable {
    let material: NSVisualEffectView.Material

    func makeNSView(context: Context) -> NSVisualEffectView {
        let vista = NSVisualEffectView()
        // Siempre activo: si sigue a la ventana, al perder el foco queda gris plano.
        vista.state = .active
        updateNSView(vista, context: context)
        return vista
    }

    func updateNSView(_ vista: NSVisualEffectView, context: Context) {
        vista.material = material
        vista.blendingMode = .behindWindow
    }
}

/// Material del sistema + tinte violeta + velo. Con "Reducir transparencia" queda sobre bg, sólido.
private struct FondoMaterial: ViewModifier {
    let material: NSVisualEffectView.Material
    let velo: Color
    var tinte = Estilo.Paleta.tinte
    @Environment(\.accessibilityReduceTransparency) private var sinTransparencia

    func body(content: Content) -> some View {
        content.background {
            ZStack {
                Estilo.Paleta.fondo
                if !sinTransparencia {
                    MaterialSistema(material: material)
                }
                tinte
                velo
            }
            .ignoresSafeArea()
        }
    }
}

/// Superficie sobre bg: surface (0.55) o surface-strong (0.78), borde de 1 pt.
private struct Superficie: ViewModifier {
    let color: Color
    let relleno: CGFloat
    /// Las tarjetas ocupan todo el ancho; los paneles respetan el ancho que les dan.
    let anchoCompleto: Bool

    func body(content: Content) -> some View {
        let forma = RoundedRectangle(cornerRadius: Estilo.Radio.tarjeta, style: .continuous)
        content
            .padding(relleno)
            .frame(maxWidth: anchoCompleto ? .infinity : nil, alignment: .leading)
            // Recorta lo de adentro (tabla, PDF, Form) a las esquinas redondeadas.
            .clipShape(forma)
            .foregroundStyle(Estilo.Paleta.texto)
            .background {
                // La sombra va en una base opaca de bg: si no, se ve a través de la superficie translúcida.
                forma.fill(Estilo.Paleta.fondo)
                    .shadow(color: Estilo.Paleta.sombra, radius: Estilo.Sombra.radio, y: Estilo.Sombra.desplazamiento)
                    .overlay { forma.fill(color) }
            }
            .overlay { forma.strokeBorder(Estilo.Paleta.borde, lineWidth: Estilo.Espacio.borde) }
    }
}

/// Botón con relleno de color, texto negro y luz de neón fina del mismo color.
/// Compacto (28 pt) por defecto; de acción (32 pt) en la barra inferior y la hoja de giro.
struct BotonEstilo: ButtonStyle {
    let fondo: Color
    var accion = false

    func makeBody(configuration: Configuration) -> some View {
        CuerpoBoton(configuration: configuration, fondo: fondo, accion: accion)
    }
}

/// Sin @State (falta el plugin de macros): el hover vive en un ObservableObject.
private final class Hover: ObservableObject {
    @Published var activo = false
}

private struct CuerpoBoton: View {
    let configuration: ButtonStyleConfiguration
    let fondo: Color
    let accion: Bool
    @StateObject private var hover = Hover()
    @Environment(\.isEnabled) private var habilitado
    @Environment(\.isFocused) private var enfocado

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: Estilo.Radio.chip, style: .continuous)
        configuration.label
            .font(Estilo.Tipo.boton)
            .foregroundStyle(Estilo.Paleta.sobreColor)
            .padding(.horizontal, accion ? Estilo.Boton.rellenoAccion : Estilo.Boton.rellenoCompacto)
            .frame(height: accion ? Estilo.Boton.altoAccion : Estilo.Boton.altoCompacto)
            .background {
                // Sin animación: la luz cambia de golpe entre estados (respeta "Reducir movimiento").
                forma.fill(fondo)
                    .shadow(color: fondo.opacity(Estilo.Neon.opacidadAncha), radius: Estilo.Neon.radioAncho * escalaHalo)
                    .shadow(color: fondo.opacity(Estilo.Neon.opacidadBorde), radius: Estilo.Neon.radioBorde * escalaHalo)
            }
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

    private var escalaHalo: CGFloat {
        if configuration.isPressed { return Estilo.Neon.escalaPresionado }
        return hover.activo && habilitado ? Estilo.Neon.escalaHover : 1
    }

    private var brillo: Double {
        if configuration.isPressed { return Estilo.Estado.brilloPresionado }
        return hover.activo && habilitado ? Estilo.Estado.brilloHover : 0
    }
}

extension ButtonStyle where Self == BotonEstilo {
    static var primario: BotonEstilo { BotonEstilo(fondo: Estilo.Paleta.primario) }
    static var secundario: BotonEstilo { BotonEstilo(fondo: Estilo.Paleta.acento) }
    /// Cancelar, rechazar, borrar o descartar.
    static var peligro: BotonEstilo { BotonEstilo(fondo: Estilo.Paleta.peligro) }
    static var primarioAccion: BotonEstilo { BotonEstilo(fondo: Estilo.Paleta.primario, accion: true) }
    static var peligroAccion: BotonEstilo { BotonEstilo(fondo: Estilo.Paleta.peligro, accion: true) }
}

extension View {
    /// Raíz de cada ventana: texto, body-md y controles en violeta primario. Sigue el modo del sistema.
    func estiloApp() -> some View {
        tint(Estilo.Paleta.primario)
            // El segundo nivel es el que usan las vistas nativas para el texto secundario.
            .foregroundStyle(Estilo.Paleta.texto, Estilo.Paleta.textoAtenuado)
            .font(Estilo.Tipo.cuerpo)
            .lineSpacing(Estilo.Tipo.interlineadoCuerpo)
    }

    /// Fondo de página (Paleta.fondo).
    func fondoPagina() -> some View {
        background { Estilo.Paleta.fondo.ignoresSafeArea() }
    }

    /// Barra lateral: material .sidebar que muestrea el escritorio + velo surface.
    func fondoBarraLateral() -> some View {
        modifier(FondoMaterial(material: .sidebar, velo: Estilo.Paleta.superficie))
    }

    /// Barras de arriba y abajo: material .headerView + velo surface.
    func fondoEncabezado() -> some View {
        modifier(FondoMaterial(material: .headerView, velo: Estilo.Paleta.superficie))
    }

    /// Paneles flotantes (hoja de giro): material .hudWindow + velo surface-strong.
    /// Con el scrim (0.4) quedaba gris (#e2e2e3 medido); con 0.78 se acerca a surface sobre bg.
    func fondoPanel() -> some View {
        modifier(FondoMaterial(material: .hudWindow, velo: Estilo.Paleta.superficieFuerte,
                               tinte: Estilo.Paleta.tintePanel))
    }

    /// Tarjeta: superficie, radio 14, relleno 16, sombra sutil.
    func tarjeta() -> some View {
        modifier(Superficie(color: Estilo.Paleta.superficie, relleno: Estilo.Espacio.tarjeta, anchoCompleto: true))
    }

    /// Panel grande (opciones, tabla de la cola): surface-strong, sin padding propio.
    func panel() -> some View {
        modifier(Superficie(color: Estilo.Paleta.superficieFuerte, relleno: 0, anchoCompleto: false))
    }

    /// Etiqueta de sección: 11 pt, semibold, mayúsculas, tracking 0.06em, texto atenuado.
    func etiquetaSeccion() -> some View {
        font(Estilo.Tipo.etiqueta)
            .textCase(.uppercase)
            .tracking(Estilo.Tipo.trackingEtiqueta)
            .foregroundStyle(Estilo.Paleta.textoAtenuado)
    }

    /// h1 de cada pantalla.
    func tituloPantalla() -> some View {
        font(Estilo.Tipo.titulo)
            .lineLimit(1)
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

    /// Texto secundario: 12 pt, text-muted.
    func textoAtenuado() -> some View {
        foregroundStyle(Estilo.Paleta.textoAtenuado)
            .font(Estilo.Tipo.secundario)
    }

    /// Advertencia (amarillo) o error (rojo): relleno suave, borde de 1 pt; el texto queda en su color normal.
    func cajaAviso(_ color: Color) -> some View {
        let forma = RoundedRectangle(cornerRadius: Estilo.Radio.control, style: .continuous)
        return padding(.horizontal, Estilo.Espacio.medio)
            .padding(.vertical, Estilo.Espacio.chico)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(Estilo.Paleta.texto)
            .background(forma.fill(color.opacity(Estilo.Estado.opacidadRellenoAviso)))
            .overlay {
                forma.strokeBorder(color.opacity(Estilo.Estado.opacidadBordeAviso), lineWidth: Estilo.Espacio.borde)
            }
    }

    /// Fila de Form con fondo de advertencia o error (un Form no deja bordear una sola fila).
    func filaAviso(_ color: Color) -> some View {
        listRowBackground(color.opacity(Estilo.Estado.opacidadRellenoAviso))
    }

    /// Filas de opciones de al menos 32 pt.
    func filasCompactas() -> some View {
        environment(\.defaultMinListRowHeight, Estilo.Espacio.fila)
    }
}
