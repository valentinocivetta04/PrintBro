import SwiftUI

struct AyudaView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Cómo usar PrintBro")
                    .font(.title2.bold())
                Text("1. Soltá un archivo en la ventana o elegilo con Archivo > Abrir… (⌘O).")
                Text("2. Ajustá copias, páginas, orientación, papel y las opciones del driver.")
                Text("3. Tocá Imprimir (⌘P).")
                Text("Doble faz manual")
                    .font(.headline)
                    .padding(.top, 6)
                Text("La impresora no imprime de los dos lados sola. PrintBro manda primero las páginas impares. Cuando terminan, girás la pila, la volvés a poner en la bandeja y tocás Continuar para imprimir las pares.")
                Text("Si el documento tiene una cantidad impar de páginas, la última hoja queda sin dorso.")
                Text("Archivos de Word, Excel o Pages")
                    .font(.headline)
                    .padding(.top, 6)
                Text("Convertilos a PDF primero (Archivo > Exportar como PDF en la app donde los abriste).")
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(24)
        }
        .frame(width: 460, height: 420)
    }
}
