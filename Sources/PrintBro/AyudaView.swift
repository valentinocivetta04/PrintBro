import SwiftUI

struct AyudaView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Estilo.Espacio.medio) {
                Text("Cómo usar PrintBro")
                    .font(.title2.bold())
                VStack(alignment: .leading, spacing: Estilo.Espacio.chico) {
                    Text("1. Soltá un archivo en la ventana o elegilo con Archivo > Abrir… (⌘O).")
                    Text("2. Ajustá copias, páginas, orientación, papel y las opciones del driver.")
                    Text("3. Tocá Imprimir (⌘P).")
                }
                .tarjeta()
                Text("Doble faz manual")
                    .etiquetaSeccion()
                VStack(alignment: .leading, spacing: Estilo.Espacio.chico) {
                    Text("La impresora no imprime de los dos lados sola. PrintBro manda primero las páginas impares. Cuando terminan, girás la pila, la volvés a poner en la bandeja y tocás Continuar para imprimir las pares.")
                    Text("Si el documento tiene una cantidad impar de páginas, la última hoja queda sin dorso.")
                }
                .tarjeta()
                Text("Archivos de Word, Excel o Pages")
                    .etiquetaSeccion()
                Text("Convertilos a PDF primero (Archivo > Exportar como PDF en la app donde los abriste).")
                    .tarjeta()
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(Estilo.Espacio.medio)
        }
        .frame(width: 460, height: 420)
        .fondoBarraLateral()
    }
}
