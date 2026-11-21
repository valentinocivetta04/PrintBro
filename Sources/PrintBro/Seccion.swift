import Foundation

enum Seccion: String, CaseIterable, Identifiable, Hashable {
    case imprimir, cola, impresora

    var id: Self { self }

    var titulo: LocalizedStringResource {
        switch self {
        case .imprimir: "Imprimir"
        case .cola: "Cola"
        case .impresora: "Impresora"
        }
    }

    var simbolo: String {
        switch self {
        case .imprimir: "printer"
        case .cola: "tray.full"
        case .impresora: "gearshape"
        }
    }
}
