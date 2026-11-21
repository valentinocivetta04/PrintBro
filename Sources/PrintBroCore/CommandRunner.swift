import Foundation

public struct CommandResult: Sendable, Equatable {
    public var status: Int32
    public var salida: String
    public var error: String

    public init(status: Int32 = 0, salida: String = "", error: String = "") {
        self.status = status
        self.salida = salida
        self.error = error
    }
}

/// Ejecuta herramientas de CUPS (lp, lpoptions, ...). Los tests usan uno falso.
public protocol CommandRunner: Sendable {
    func run(_ herramienta: String, _ argumentos: [String]) throws -> CommandResult
}

public struct ProcessRunner: CommandRunner {
    public init() {}

    public func run(_ herramienta: String, _ argumentos: [String]) throws -> CommandResult {
        let proceso = Process()
        proceso.executableURL = URL(fileURLWithPath: "/usr/bin/\(herramienta)")
        // Arreglo de argumentos, sin shell: nombres con espacios o comillas no rompen nada.
        proceso.arguments = argumentos
        let salida = Pipe(), error = Pipe()
        proceso.standardOutput = salida
        proceso.standardError = error
        try proceso.run()
        // Leer antes de esperar para que una salida grande no trabe el proceso.
        let datosSalida = salida.fileHandleForReading.readDataToEndOfFile()
        let datosError = error.fileHandleForReading.readDataToEndOfFile()
        proceso.waitUntilExit()
        return CommandResult(
            status: proceso.terminationStatus,
            salida: String(decoding: datosSalida, as: UTF8.self),
            error: String(decoding: datosError, as: UTF8.self)
        )
    }
}
