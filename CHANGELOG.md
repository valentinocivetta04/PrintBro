# Cambios

Acá anoto lo que cambia en cada versión de PrintBro. El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).

## [0.2.0] - 2026-11-23

Esta versión cambia solo la interfaz. La parte que imprime (doble faz, folleto, opciones del driver, cola y estado de la impresora) es la misma de la 0.1.0: no toqué `Sources/PrintBroCore` ni los tests, que siguen siendo 72.

### Agregado

- Modo oscuro. La app sigue el modo claro u oscuro del sistema.
- Colores para los avisos: las advertencias (tóner bajo, driver que no es de Brother, última hoja sin dorso en doble faz) salen en amarillo y los errores (por ejemplo un rango de páginas inválido) en rojo. En los dos casos hay ícono y texto, no solo color.

### Cambiado

- Interfaz nueva con el estilo de vidrio translúcido de macOS y una paleta violeta. La barra lateral, la barra de abajo y el aviso para girar la pila usan los materiales del sistema, que dejan ver el escritorio desenfocado.
- Tamaños más chicos: títulos de pantalla de 24 pt, texto de 13 pt, botones de 28 pt (32 pt los de Cancelar e Imprimir, y los del aviso de doble faz) y tarjetas con menos relleno.
- Los botones tienen una luz fina del mismo color que su relleno.
- Los botones que cancelan o borran (Cancelar, Cancelar trabajo, Cancelar todos y el menú Borrar de los presets) son rojos.
- La barra de arriba tiene el mismo fondo que la página.
- La sección elegida en la barra lateral se marca con un violeta translúcido. Ahora se cambia con clic o con Tab; las flechas del teclado ya no mueven la selección.
- Dentro de PrintBro el color de acento del sistema es violeta. Lo guarda en sus propias preferencias, así que el resto de la Mac sigue con el acento que tengas.
- Ícono nuevo: una impresora con arcos de wifi y una hoja con un tilde.

### Actualizar desde la 0.1.0

Bajá `PrintBro-0.2.0.dmg`, abrilo y arrastrá PrintBro a Aplicaciones para reemplazar la versión anterior. Si la compilás vos, `./build.sh --instalar` hace lo mismo. Como el DMG es una descarga nueva, macOS la vuelve a bloquear la primera vez; se habilita con `xattr -dr com.apple.quarantine /Applications/PrintBro.app`, igual que antes.

No hay que reconfigurar nada: los presets, la opción de imprimir las pares en orden inverso y la impresora predeterminada se guardan con las mismas claves que en la 0.1.0.

### Problemas conocidos

- En mi Mac, macOS rechaza las notificaciones de PrintBro con el error "Notifications are not allowed for this application". Sospecho que es por la firma ad-hoc, pero no lo confirmé. Cuando termina o falla un trabajo, el aviso aparece abajo en la ventana.

## [0.1.0] - 2026-11-21

Primera versión.

### Agregado

- Doble faz manual: imprime las impares con `page-set=odd`, avisa que des vuelta la pila y después imprime las pares con `page-set=even` y `outputorder=reverse` (se puede desactivar). Con una cantidad impar de caras avisa que la última hoja queda sin dorso.
- Las opciones del driver (resolución, ahorro de tóner, tipo de papel, densidad, etc.) tal como las devuelve `lpoptions -l`.
- Copias, rango de páginas con validación, orientación, tamaño de papel (A4 por defecto si el driver lo ofrece) y 1, 2, 4, 6 o 9 páginas por hoja.
- Folleto: arma un PDF temporal con dos páginas por cara para doblar la pila al medio.
- PDF, imágenes (PNG, JPG y HEIC) y texto plano. Las imágenes se pasan a un PDF temporal.
- Vista previa del PDF con miniaturas.
- Cola de impresión que se actualiza cada 2 segundos mientras la mirás, con botones para cancelar un trabajo o todos.
- Estado de la impresora con avisos en español, y una franja arriba de la pantalla de impresión cuando el tóner está bajo.
- Aviso en la pantalla Impresora si el driver de la cola no es de Brother.
- Presets con nombre e historial de los últimos 20 trabajos, con un botón para reimprimir.
- Modo de prueba (`PRINTBRO_DRY_RUN=1`) que no manda nada a la impresora.

[0.2.0]: https://github.com/valentinocivetta04/PrintBro/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/valentinocivetta04/PrintBro/releases/tag/v0.1.0
