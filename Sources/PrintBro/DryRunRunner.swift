import Foundation
import PrintBroCore

/// Modo simulación (PRINTBRO_DRY_RUN=1): lp y cancel no se ejecutan, el resto sí (solo lectura).
struct DryRunRunner: CommandRunner {
    private let real = ProcessRunner()

    func run(_ herramienta: String, _ argumentos: [String]) throws -> CommandResult {
        guard herramienta == "lp" || herramienta == "cancel" else {
            return try real.run(herramienta, argumentos)
        }
        let linea = "[simulación] \(herramienta) \(argumentos)\n"
        FileHandle.standardError.write(Data(linea.utf8))
        // Pausa para que se vea el progreso en pantalla.
        Thread.sleep(forTimeInterval: 2)
        return CommandResult()
    }
}
