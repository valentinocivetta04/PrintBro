<p align="center"><img src="docs/icono.png" width="160" alt="Ícono de PrintBro"></p>

# PrintBro

PrintBro es una app de Mac que hice para usar mi impresora Brother HL-1210W sin pelearme con el diálogo de impresión. La impresora es láser, monocromática y por WiFi, pero no imprime de los dos lados sola. Lo que más uso de la app es el doble faz manual: primero imprime las páginas impares, me pide que dé vuelta la pila y después imprime las pares.

La hice para uso propio mientras estudio la Tecnicatura en IA en la UNR. Si tenés la misma impresora (o una parecida que use CUPS) capaz te sirve.

## Qué hace

- Imprime PDF, imágenes (PNG, JPG y HEIC) y texto plano. Las imágenes se ajustan a la hoja.
- Muestra una vista previa del PDF con las miniaturas de las páginas.
- Doble faz manual, con la opción de mandar las pares en orden inverso.
- Folleto: reordena las páginas para imprimir dos por cara y doblar la pila al medio.
- Rango de páginas, copias, orientación, tamaño de papel y 1, 2, 4, 6 o 9 páginas por hoja.
- Muestra las opciones propias del driver (resolución, ahorro de tóner, etc.) tal como las devuelve `lpoptions -l`, sin inventar ninguna.
- Presets con nombre y un historial de los últimos 20 trabajos, con un botón para reimprimir.
- Ve la cola de impresión, deja cancelar trabajos y avisa cuando a la impresora le falta tóner o papel, está pausada o sin conexión.

## Requisitos

- macOS 14 o posterior.
- Las Command Line Tools de Apple (`xcode-select --install`). No hace falta Xcode.
- La impresora agregada en Configuración del Sistema con el driver oficial de Brother (en mi caso "Brother HL-1210W series CUPS").

## Cómo compilarla

```bash
./build.sh
```

Eso compila en modo release y arma `PrintBro.app` en la carpeta del proyecto, con el ícono y firmada ad-hoc. Para dejarla además en Aplicaciones:

```bash
./build.sh --instalar
```

Los tests se corren así (con solo Command Line Tools, `swift test` a secas no encuentra las macros de Swift Testing):

```bash
./test.sh
```

Si querés probar la interfaz sin gastar papel, abrila en modo simulación. En ese modo `lp` y `cancel` no se ejecutan; el resto (leer impresoras, opciones y estado) es real.

```bash
PRINTBRO_DRY_RUN=1 ./PrintBro.app/Contents/MacOS/PrintBro
```

## Cómo uso el doble faz

1. Abro el PDF (lo arrastro a la ventana, uso Archivo > Abrir o "Abrir con > PrintBro" desde Finder).
2. Activo "Doble faz manual" y toco Imprimir. Salen las páginas impares.
3. Cuando aparece el aviso, espero que termine de salir la primera tanda, doy vuelta la pila, la vuelvo a poner en la bandeja y toco Continuar. Salen las pares.

La opción "Imprimir las pares en orden inverso" viene activada porque con mi forma de girar la pila es la que deja cada página par en el dorso correcto. Si vos girás la pila de otra manera, probá desactivarla. La app se acuerda de lo que elijas.

Con una cantidad impar de páginas la última hoja queda sin dorso, y la app lo avisa antes de que gires la pila. El doble faz imprime el documento entero y una sola copia, así que desactiva el rango y las copias mientras está prendido.

## Folleto

Con "Folleto" la app arma un PDF temporal con dos páginas por cara, en orden de folleto (para 8 páginas: 8 y 1, 2 y 7, 6 y 3, 4 y 5), y lo imprime con doble faz. Al terminar doblás la pila al medio. El PDF original no se toca y el temporal se borra cuando termina o cancelás el trabajo.

## Problemas comunes

### Los trabajos figuran como completados pero no sale nada

Me pasó con una cola que tenía un driver equivocado (DYMO). La app lee el driver de la cola y muestra un aviso arriba si no es de Brother. La solución es borrar la cola y volver a agregar la impresora con el driver de Brother.

### La impresora está pausada

Aparece en la pantalla Impresora y en la franja de avisos. Se reanuda desde Configuración del Sistema > Impresoras y escáneres; la app no la reanuda sola.

### Tóner bajo

Mi impresora lo reporta como `toner-low-report` y la luz naranja titila, pero sigue imprimiendo bien. La app lo muestra como "Tóner bajo" en una franja arriba de la pantalla Imprimir, sin bloquear nada.

### La última hoja salió sin dorso

Es lo esperable con un documento de páginas impares en doble faz.

### No aparecen notificaciones

Como la app está firmada ad-hoc, macOS no la deja mandar notificaciones. Cuando termina o falla un trabajo, el aviso aparece abajo en la ventana.

## Limitaciones

- Solo imprime. La HL-1210W no escanea ni copia, y la app tampoco.
- No convierte Word, Excel ni Pages: hay que exportarlos a PDF primero.
- Está pensada para mi impresora y probada solo con ella. Lo que viene del driver (las opciones avanzadas) cambia con cada impresora.
- La interfaz está solo en español.

## Cómo está hecha

Es un paquete de Swift sin dependencias externas: SwiftUI para la interfaz, PDFKit para la vista previa y el folleto, y la API C de CUPS para leer impresoras, estado y cola. Toda la lógica está en el target `PrintBroCore`, que tiene los tests. Para imprimir usa `lp` con los argumentos armados como lista (nunca como un string de shell), y para cancelar usa `cancel`. La salida de esos comandos viene traducida al español, así que la app solo mira si terminaron bien o mal.

## Licencia

MIT. Ver [LICENSE](LICENSE).
