import Foundation

public enum PrintBroError: LocalizedError, Equatable {
    case convertirAPDF(String)
    case formatoNoSoportado(String)
    case comandoFallo(String)
    case pdfIlegible
    case duplexSoloPDF
    case duplexConRango
    case duplexConCopias
    case estadoInvalido
    case rangoInvalido(String)
    case presetSinNombre
    case imagenIlegible
    case archivoNoEncontrado(String)

    public var errorDescription: String? {
        switch self {
        case .archivoNoEncontrado(let nombre):
            "No se encontró «\(nombre)». Puede que lo hayas movido o borrado."
        case .imagenIlegible:
            "No se pudo leer la imagen."
        case .presetSinNombre:
            "Poné un nombre para el preset."
        case .rangoInvalido(let detalle):
            detalle
        case .convertirAPDF(let ext):
            "Los archivos .\(ext) no se pueden imprimir directo: convertilo a PDF primero."
        case .formatoNoSoportado(let ext):
            "El formato .\(ext) no está soportado. Usá PDF, imagen (png, jpg, heic) o texto plano."
        case .comandoFallo(let detalle):
            "La impresión falló: \(detalle)"
        case .pdfIlegible:
            "No se pudo leer el PDF."
        case .duplexSoloPDF:
            "El doble faz manual solo funciona con PDF."
        case .duplexConRango:
            "El doble faz manual imprime el documento entero: sacá el rango de páginas."
        case .duplexConCopias:
            "El doble faz manual imprime una sola copia: imprimí el documento de nuevo para hacer otra."
        case .estadoInvalido:
            "Esa acción no se puede hacer en este momento."
        }
    }
}
