import Foundation
import PrintBroCore

/// Runner falso: guarda los comandos y nunca ejecuta nada (no imprime papel).
final class FakeRunner: CommandRunner, @unchecked Sendable {
    private(set) var llamadas: [(herramienta: String, argumentos: [String])] = []
    var respuesta = CommandResult()

    func run(_ herramienta: String, _ argumentos: [String]) throws -> CommandResult {
        llamadas.append((herramienta, argumentos))
        return respuesta
    }
}
