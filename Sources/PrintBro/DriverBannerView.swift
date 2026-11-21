import SwiftUI

/// Aviso no bloqueante cuando la cola no usa un driver de Brother.
struct DriverBannerView: View {
    let mensaje: String

    var body: some View {
        Label {
            Text(mensaje)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .symbolRenderingMode(.multicolor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
        .overlay(alignment: .bottom) { Divider() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Advertencia: \(mensaje)"))
    }
}
