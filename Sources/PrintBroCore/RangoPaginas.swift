import Foundation

public enum RangoPaginas {
    /// Valida un rango tipo "1-3, 5,8-10" y lo devuelve sin espacios.
    /// `total` es la cantidad de páginas del documento, si se conoce.
    public static func validar(_ texto: String, total: Int? = nil) throws -> String {
        let limpio = texto.replacingOccurrences(of: " ", with: "")
        guard !limpio.isEmpty else {
            throw PrintBroError.rangoInvalido("Escribí qué páginas querés, por ejemplo 1-3,5.")
        }
        for parte in limpio.split(separator: ",", omittingEmptySubsequences: false) {
            let numeros = parte.split(separator: "-", omittingEmptySubsequences: false)
            // Solo dígitos y guiones: Int() aceptaría "+3".
            guard parte.allSatisfy({ ("0"..."9").contains($0) || $0 == "-" }),
                  (1...2).contains(numeros.count),
                  let desde = Int(numeros[0]), let hasta = Int(numeros[numeros.count - 1]),
                  desde >= 1, desde <= hasta
            else {
                throw PrintBroError.rangoInvalido("«\(parte)» no es válido. Usá números y guiones, por ejemplo 1-3,5,8-10.")
            }
            if let total, hasta > total {
                throw PrintBroError.rangoInvalido("El documento tiene \(total) páginas y «\(parte)» se pasa.")
            }
        }
        return limpio
    }
}
