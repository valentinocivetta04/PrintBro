import Foundation

/// Seguimiento de los trabajos que manda la app, para avisar cuando terminan o fallan.
/// La salida de lp viene traducida, así que el id no se lee de ahí: se anota el último id
/// antes de mandar y después se buscan los trabajos nuevos con cupsGetJobs2.
public enum Seguimiento {
    public static func ultimoId(de impresora: String) -> Int {
        PrinterService.trabajos(de: impresora, activos: false).map(\.id).max() ?? 0
    }

    public static func nuevos(_ trabajos: [TrabajoCola], despuesDe id: Int) -> [TrabajoCola] {
        trabajos.filter { $0.id > id }
    }

    /// Título y texto de la notificación, o nil si el trabajo todavía no terminó.
    public static func aviso(para estado: EstadoTrabajo, archivo: String) -> (titulo: String, cuerpo: String)? {
        switch estado {
        case .completado:
            (String(localized: "Impresión terminada"), String(localized: "«\(archivo)» ya salió de la impresora."))
        case .abortado:
            (String(localized: "La impresión falló"), String(localized: "«\(archivo)» no se pudo imprimir. Revisá la impresora."))
        case .cancelado:
            (String(localized: "Impresión cancelada"), String(localized: "Se canceló «\(archivo)»."))
        default:
            nil
        }
    }
}
