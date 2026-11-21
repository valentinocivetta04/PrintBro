import PDFKit
import SwiftUI

/// PDFView con la columna de miniaturas a la izquierda. SwiftUI no tiene equivalente.
struct PDFKitView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> ContenedorPDF {
        let contenedor = ContenedorPDF()
        contenedor.pdfView.document = PDFDocument(url: url)
        return contenedor
    }

    func updateNSView(_ contenedor: ContenedorPDF, context: Context) {
        if contenedor.pdfView.document?.documentURL != url {
            contenedor.pdfView.document = PDFDocument(url: url)
        }
    }

    // Ocupa todo el espacio que le ofrecen; el NSView no tiene tamaño propio.
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: ContenedorPDF, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 400, height: proposal.height ?? 500)
    }
}

/// Ubica miniaturas y PDF a mano en layout(): con Auto Layout quedaban con alto cero.
final class ContenedorPDF: NSView {
    let pdfView = PDFView()
    private let miniaturas = PDFThumbnailView()
    private let separador = NSBox()
    private let anchoMiniaturas: CGFloat = 112

    override init(frame: NSRect) {
        super.init(frame: frame)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        miniaturas.pdfView = pdfView
        miniaturas.thumbnailSize = CGSize(width: 76, height: 100)
        miniaturas.backgroundColor = .controlBackgroundColor
        miniaturas.setAccessibilityLabel(String(localized: "Miniaturas de las páginas"))
        separador.boxType = .separator
        addSubview(miniaturas)
        addSubview(separador)
        addSubview(pdfView)
    }

    required init?(coder: NSCoder) { nil }

    override func layout() {
        super.layout()
        let alto = bounds.height
        miniaturas.frame = NSRect(x: 0, y: 0, width: anchoMiniaturas, height: alto)
        separador.frame = NSRect(x: anchoMiniaturas, y: 0, width: 1, height: alto)
        pdfView.frame = NSRect(x: anchoMiniaturas + 1, y: 0,
                               width: max(bounds.width - anchoMiniaturas - 1, 0), height: alto)
    }
}
