import Foundation

enum Seccion: String, CaseIterable, Identifiable, Hashable {
    case imprimir, historial, cola, impresora

    var id: Self { self }

    var titulo: LocalizedStringResource {
        switch self {
        case .imprimir: "Imprimir"
        case .historial: "Historial"
        case .cola: "Cola"
        case .impresora: "Impresora"
        }
    }

    var simbolo: String {
        switch self {
        case .imprimir: "printer"
        case .historial: "clock.arrow.circlepath"
        case .cola: "tray.full"
        case .impresora: "gearshape"
        }
    }
}
