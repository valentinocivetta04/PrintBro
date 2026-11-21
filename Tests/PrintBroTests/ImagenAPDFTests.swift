import AppKit
import Foundation
import ImageIO
import PDFKit
import Testing
import UniformTypeIdentifiers
@testable import PrintBroCore

/// Imagen de prueba de 300x200 en el formato pedido.
private func imagenDePrueba(_ tipo: UTType, extension ext: String) throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("printbro-test-\(UUID().uuidString).\(ext)")
    let contexto = try #require(CGContext(data: nil, width: 300, height: 200, bitsPerComponent: 8, bytesPerRow: 0,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    contexto.setFillColor(CGColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1))
    contexto.fill(CGRect(x: 0, y: 0, width: 300, height: 200))
    let imagen = try #require(contexto.makeImage())
    let destino = try #require(CGImageDestinationCreateWithURL(url as CFURL, tipo.identifier as CFString, 1, nil))
    CGImageDestinationAddImage(destino, imagen, nil)
    #expect(CGImageDestinationFinalize(destino))
    return url
}

@Test(arguments: [(UTType.png, "png"), (UTType.jpeg, "jpg"), (UTType.heic, "heic")])
func imagenSeConvierteAPDFTemporal(tipo: UTType, ext: String) throws {
    let imagen = try imagenDePrueba(tipo, extension: ext)
    defer { try? FileManager.default.removeItem(at: imagen) }
    #expect(ImagenAPDF.esImagen(imagen))

    let pdf = try ImagenAPDF.convertir(imagen)
    defer { try? FileManager.default.removeItem(at: pdf) }
    #expect(pdf.path.hasPrefix(FileManager.default.temporaryDirectory.path))
    let documento = try #require(PDFDocument(url: pdf))
    #expect(documento.pageCount == 1)
}

@Test func textoYPDFNoSonImagen() {
    #expect(!ImagenAPDF.esImagen(URL(fileURLWithPath: "/tmp/a.txt")))
    #expect(!ImagenAPDF.esImagen(URL(fileURLWithPath: "/tmp/a.pdf")))
}

@Test func imagenRotaDaError() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("printbro-rota-\(UUID().uuidString).png")
    try Data("no soy una imagen".utf8).write(to: url)
    defer { try? FileManager.default.removeItem(at: url) }
    #expect(throws: PrintBroError.imagenIlegible) { try ImagenAPDF.convertir(url) }
}
