# Pruebas manuales — Flujo de registro de ventas (M3)

## Propósito

Comprobar manualmente, desde la perspectiva del tendero, que se puede
completar una venta de principio a fin, detectar problemas de usabilidad y
dejar evidencia del funcionamiento alcanzado en M3.

- Reglas de negocio de referencia: [`reglas_negocio_ventas.md`](reglas_negocio_ventas.md).
- Formato y evidencia de referencia (M2): [`plan-pruebas-manuales-catalogo-producto.md`](plan-pruebas-manuales-catalogo-producto.md)
  y [`evidencia-m2/README.md`](evidencia-m2/README.md).
- Pantallas cubiertas: Catálogo, Registrar venta y Venta confirmada.
- **Fuera de alcance:** pruebas con usuarios externos, estudios formales de
  usabilidad y pruebas de carga.

> **Estado:** ejecutado el 2026-10-15 en Windows de escritorio (ver
> [Datos de la ejecución](#datos-de-la-ejecución)). 35 de 40 casos aprobados,
> 2 fallidos y 3 no ejecutados. Las capturas están en
> `docs/evidencia-m3/capturas/`. Ver [Alcance y limitaciones](#alcance-y-limitaciones-de-esta-ejecución).

## Datos de la ejecución

| Dato | Valor |
|---|---|
| Fecha | 2026-10-15 |
| Quién ejecutó | Claude Code, a pedido de alexander. Manejó la app real con el mouse y el teclado y leyó el árbol de accesibilidad de Windows; no fue una persona probando a mano. |
| Rama / commit probado | `main` (`3450334`) |
| Dispositivo (emulador o físico) | Windows de escritorio con `sqflite_common_ffi`; ventana de 430×880 (también 380×700, 820×470 y 1300×900) |
| Versión del sistema | Windows 11 (10.0.26300) |

Notas de la ejecución:

- Instalación limpia y datos de P3 cargados desde la propia app.
- La base se leyó con SQLite (`cabal.db`) para comprobar lo guardado.
- Para los casos de la sección F se usó una modificación **temporal y no
  commiteada** de `VentaService.registrarVenta` que lanzaba una excepción si
  existía un archivo `fail.flag`; después se revirtió.
- Los tamaños de pantalla se probaron redimensionando la ventana de escritorio,
  no en dispositivos reales.
- No se grabó video; la evidencia son capturas y volcados de la base.

## Alcance y limitaciones de esta ejecución

- **No se probó en Android.** En el entorno donde se ejecutó no hay Android SDK
  ni emulador ni dispositivo físico, así que no fue posible hacerlo. Todo se
  verificó en Windows de escritorio con `sqflite_common_ffi`, que usa el mismo
  código de la app pero no es el entorno final del tendero. Por eso los
  tamaños de pantalla se probaron redimensionando la ventana, y el
  comportamiento del teclado táctil y de la rotación real de un celular no se
  comprobó.
- **No se grabará video del flujo completo.** El equipo decidió no hacerlo; la
  evidencia queda como capturas de pantalla y volcados de la base de datos
  (ver [Evidencia](#evidencia)).
- **Tres casos quedan sin ejecutar y así se dejan:**
  - **VEN-21:** no se puede alcanzar desde la interfaz (ver D-05).
  - **VEN-38:** necesita un teclado táctil, que no existe en escritorio.
  - **VEN-40:** necesita una persona con cronómetro y es solo una observación
    de usabilidad, no un criterio de aprobación.

## Preparación

| # | Precondición |
|---|---|
| P1 | App corriendo desde la rama a probar (`flutter run` desde `app_cabal/`) en Android, o en Windows de escritorio con `sqflite_common_ffi` (ver nota de `evidencia-m2`). |
| P2 | Instalación limpia (desinstalar o borrar datos) antes de empezar. |
| P3 | Cargar estos productos desde "Agregar producto": `Coca Cola` Q10.50, `Pan dulce` Q2.50, `Agua pura` Q8.00, `Chicle` Q0.10, `Galleta` Q0.20, `Dulce` Q0.30, `Aceite` Q19.99. |
| P4 | Flujo de entrada: Login (placeholder) → "Ingresar (placeholder)" → Catálogo → "Probar registrar venta" (o tocar una tarjeta de producto) → Registrar venta. |

### Cómo verificar lo guardado

Todavía no hay una pantalla de consulta de ventas, así que lo almacenado se
verifica en la base `cabal.db`, tablas `venta` y `detalle_venta`:

- **Android:** *App Inspection → Database Inspector* en Android Studio, o
  `adb shell run-as <paquete> sqlite3 databases/cabal.db "SELECT ..."`.
- **Windows de escritorio:** abrir el archivo `cabal.db` (carpeta de bases de
  `sqflite_common_ffi`) con cualquier visor de SQLite.

Consultas útiles:

```sql
SELECT * FROM venta;
SELECT * FROM detalle_venta;
```

### Cómo provocar un error de guardado

Para los casos de la sección F, cambiar **temporalmente y sin commitear**
`VentaService.registrarVenta` (`app_cabal/lib/services/venta_service.dart`) para
que lance una excepción:

```dart
Future<void> registrarVenta(Venta venta) async {
  throw Exception('fallo simulado');
  // ...
}
```

Volver a dejar el archivo como estaba al terminar esos casos.

## Textos de la interfaz (referencia)

| Elemento | Texto |
|---|---|
| Listas de la pantalla | `Productos` y `Venta actual` |
| Venta vacía | `Toca un producto para agregarlo a la venta` |
| Botón de guardar | `Confirmar venta` |
| Sin productos en el catálogo | `No hay productos registrados` / `Agrega productos al catálogo para registrar ventas.` |
| Confirmación | `Venta registrada`, `Total: Q…`, botones `Nueva venta` y `Volver al catálogo` |
| Error de cantidad | `Ingresa una cantidad válida.` · `La cantidad debe ser un número entero.` · `La cantidad debe ser mayor que cero.` |
| Error de guardado | `No se pudo registrar la venta. Intenta de nuevo.` |

---

## A. Venta con un solo producto

| ID | Caso | Pasos | Datos | Resultado esperado | Resultado obtenido | ✔/✘ |
|---|---|---|---|---|---|---|
| VEN-01 | Venta mínima | 1. Entrar a Registrar venta. 2. Tocar `Coca Cola`. 3. Tocar `Confirmar venta`. | Coca Cola ×1 | Aparece en `Venta actual` con cantidad 1, subtotal `Q10.50` y total `Q10.50`. Al confirmar se muestra `Venta registrada` y `Total: Q10.50`. En la base: 1 fila en `venta` y 1 en `detalle_venta` (cantidad 1, precio 10.5). | Fila Coca Cola ×1, subtotal y total Q10.50. Confirmación "Venta registrada" / "Total: Q10.50". BD: 1 venta y 1 detalle (cantidad 1, precio 10.5). | ✔ |
| VEN-02 | Cambiar la cantidad escribiéndola | 1. Tocar `Coca Cola`. 2. Cambiar el campo de cantidad a `4`. 3. Confirmar. | Coca Cola ×4 | Subtotal `Q42.00` y total `Q42.00`. Confirmación con `Total: Q42.00`. En la base: cantidad 4, precio 10.5. | Subtotal y total Q42.00; confirmación "Total: Q42.00". BD: cantidad 4, precio 10.5. | ✔ |
| VEN-03 | Cambiar la cantidad con +/− | 1. Tocar `Coca Cola`. 2. Tocar `+` dos veces. 3. Tocar `−` una vez. | Coca Cola ×2 | Cantidad 2, subtotal `Q21.00`. El botón `−` está deshabilitado cuando la cantidad es 1. | Cantidad 2 y subtotal Q21.00. Con cantidad 1 el botón − aparece atenuado. | ✔ |

## B. Venta con varios productos y distintas cantidades

| ID | Caso | Pasos | Datos | Resultado esperado | Resultado obtenido | ✔/✘ |
|---|---|---|---|---|---|---|
| VEN-04 | Varios productos | 1. Tocar `Coca Cola`, `Pan dulce` y `Agua pura`. 2. Poner cantidades 2, 3 y 1. 3. Confirmar. | Coca Cola ×2, Pan dulce ×3, Agua pura ×1 | Subtotales `Q21.00`, `Q7.50` y `Q8.00`; total `Q36.50`. Confirmación con `Total: Q36.50`. En la base: 1 venta y 3 detalles con las cantidades y precios indicados. | Subtotales Q21.00, Q7.50 y Q8.00; total Q36.50; confirmación "Total: Q36.50". BD: 1 venta y 3 detalles (2×10.5, 3×2.5, 1×8.0). Capturas 02 y 05. | ✔ |
| VEN-05 | Producto repetido no se duplica | 1. Tocar `Coca Cola` tres veces. | Coca Cola ×3 | Una sola fila de `Coca Cola` con cantidad 3 y subtotal `Q31.50`. | Una sola fila de Coca Cola con cantidad 3 y subtotal Q31.50. | ✔ |
| VEN-06 | Eliminar un producto | 1. Agregar `Coca Cola` y `Pan dulce`. 2. Eliminar `Coca Cola` con el ícono de basura. | — | Solo queda `Pan dulce`; el total se actualiza a `Q2.50`. | Al eliminar Coca Cola solo queda Pan dulce y el total pasa de Q34.00 a Q2.50. | ✔ |
| VEN-07 | Eliminar todos los productos | 1. Agregar un producto. 2. Eliminarlo. | — | `Venta actual` vuelve al mensaje de venta vacía, el total es `Q0.00` y `Confirmar venta` queda deshabilitado. | Mensaje de venta vacía y total Q0.00. Un clic real en "Confirmar venta" no hace nada (botón atenuado). | ✔ |

## C. Cálculo de subtotales y total

| ID | Caso | Pasos | Datos | Resultado esperado | Resultado obtenido | ✔/✘ |
|---|---|---|---|---|---|---|
| VEN-08 | Total con decimales | Agregar `Chicle`, `Galleta` y `Dulce`, cantidad 1 cada uno. | 0.10 + 0.20 + 0.30 | Total `Q0.60` (sin `Q0.6000…` ni `Q0.59`). | Total Q0.60. | ✔ |
| VEN-09 | Subtotal con redondeo | Agregar `Aceite` con cantidad 3. | 19.99 × 3 | Subtotal y total `Q59.97`. | Subtotal y total Q59.97. | ✔ |
| VEN-10 | Cantidad grande | Agregar `Coca Cola` con cantidad `100`. | 10.50 × 100 | Subtotal y total `Q1050.00`. | Subtotal y total Q1050.00. | ✔ |
| VEN-11 | El total sigue a cada cambio | Agregar un producto, subir su cantidad, agregar otro y eliminar el primero. | — | Después de cada acción el total refleja exactamente la suma de los subtotales visibles. | Total Q10.50 → Q21.00 (+1) → Q23.50 (agregar Pan dulce) → Q2.50 (eliminar Coca Cola ×2). | ✔ |
| VEN-12 | Formato en quetzales | Revisar precios y totales en toda la pantalla. | — | Todos con prefijo `Q` y dos decimales. | Precios, subtotales y totales de Registrar venta y de la confirmación llevan Q y dos decimales. El Catálogo mostraba `$` (ver D-02, corregido). | ✔ |

## D. Venta vacía o con datos inválidos

| ID | Caso | Pasos | Datos | Resultado esperado | Resultado obtenido | ✔/✘ |
|---|---|---|---|---|---|---|
| VEN-13 | Venta vacía | Entrar a Registrar venta sin tocar productos. | — | Total `Q0.00`. `Confirmar venta` deshabilitado. No se puede registrar nada. | Total Q0.00; un clic real en "Confirmar venta" no hace nada y no se crea ninguna venta. Captura 04. | ✔ |
| VEN-14 | Cantidad 0 | Agregar un producto y escribir `0` en la cantidad. | `0` | Campo en rojo y mensaje `La cantidad debe ser mayor que cero.`; `Confirmar venta` deshabilitado. | Mensaje "La cantidad debe ser mayor que cero."; confirmar sin efecto. Captura 03. El subtotal sigue mostrando el último valor válido (ver D-04). | ✔ |
| VEN-15 | Cantidad negativa | Escribir `-1`. | `-1` | Mismo mensaje que VEN-14; confirmar deshabilitado. | Mismo mensaje que VEN-14; confirmar sin efecto. | ✔ |
| VEN-16 | Cantidad decimal | Escribir `1.5`. | `1.5` | Mensaje `La cantidad debe ser un número entero.`; confirmar deshabilitado. | Mensaje "La cantidad debe ser un número entero."; confirmar sin efecto. | ✔ |
| VEN-17 | Cantidad no numérica | Escribir `abc`. | `abc` | Mensaje `Ingresa una cantidad válida.`; confirmar deshabilitado. | Mensaje "Ingresa una cantidad válida."; confirmar sin efecto. | ✔ |
| VEN-18 | Cantidad vacía | Borrar el contenido del campo. | (vacío) | Mensaje `Ingresa una cantidad válida.`; confirmar deshabilitado. | Mensaje "Ingresa una cantidad válida."; confirmar sin efecto. | ✔ |
| VEN-19 | Corregir la cantidad | Provocar VEN-14 y luego escribir `2`. | `0` → `2` | El mensaje desaparece, el subtotal se calcula con 2 y confirmar se habilita. | Al escribir 2 el mensaje desaparece, el subtotal pasa a Q21.00 y confirmar guarda la venta. | ✔ |
| VEN-20 | Un producto inválido bloquea toda la venta | Agregar dos productos y poner `0` en el segundo. | — | Confirmar deshabilitado. Al eliminar el producto inválido se habilita. | Con Pan dulce en 0 confirmar no responde, aunque Coca Cola es válida. Al eliminar Pan dulce el total queda en Q21.00 y se puede confirmar. | ✔ |
| VEN-21 | Catálogo sin productos | Con instalación limpia, entrar a Registrar venta. | — | Mensaje `No hay productos registrados` con indicación de agregar productos al catálogo y botón `Agregar producto`. | No ejecutable desde la interfaz: Registrar venta solo se alcanza desde el Catálogo con productos (las tarjetas y "Probar registrar venta" solo existen con productos). El estado queda cubierto por pruebas automatizadas (ver D-05). | ➖ |

## E. Persistencia

| ID | Caso | Pasos | Datos | Resultado esperado | Resultado obtenido | ✔/✘ |
|---|---|---|---|---|---|---|
| VEN-22 | La venta sobrevive al reinicio | 1. Registrar la venta de VEN-04. 2. Cerrar la app por completo. 3. Abrirla de nuevo. 4. Revisar la base. | VEN-04 | La venta y sus 3 detalles siguen en `venta` y `detalle_venta` con los mismos valores. | Tras cerrar la app a la fuerza y reabrirla, `venta` y `detalle_venta` conservan las ventas anteriores con los mismos valores. Verificado leyendo `cabal.db`. Evidencia 07. | ✔ |
| VEN-23 | El catálogo sobrevive al reinicio | Tras VEN-22, abrir el Catálogo. | — | Los productos cargados en P3 siguen ahí. | Los 7 productos de P3 siguen en el Catálogo. Captura 07. | ✔ |
| VEN-24 | La venta en curso no se guarda sin confirmar | 1. Agregar productos sin confirmar. 2. Cerrar la app por completo. 3. Revisar la base. | — | No se creó ninguna venta nueva. | Con Pan dulce y Galleta sin confirmar, tras cerrar y reabrir no hay venta nueva en la base y la venta en curso quedó vacía. | ✔ |

## F. Errores durante el guardado

Requieren provocar el error como se indica en [Cómo provocar un error de
guardado](#cómo-provocar-un-error-de-guardado).

| ID | Caso | Pasos | Datos | Resultado esperado | Resultado obtenido | ✔/✘ |
|---|---|---|---|---|---|---|
| VEN-25 | Falla el guardado | Con el error provocado, agregar `Coca Cola` ×2 y confirmar. | Coca Cola ×2 | Aparece `No se pudo registrar la venta. Intenta de nuevo.`. **No** se muestra `Venta registrada`. Los productos y cantidades siguen en pantalla. En la base no se creó ninguna venta ni detalle. | Aparece "No se pudo registrar la venta. Intenta de nuevo."; no se muestra la confirmación; los productos y cantidades siguen en pantalla (Q23.50); la base no recibió ninguna venta ni detalle del intento. Captura 08. | ✔ |
| VEN-26 | Reintento exitoso | Tras VEN-25, quitar la excepción provocada, recompilar y repetir la venta. | — | La venta se guarda una sola vez y se muestra la confirmación. | Al quitar el fallo y volver a confirmar, la venta se guarda una sola vez (1 venta nueva, 2 detalles) y se muestra "Total: Q23.50". | ✔ |
| VEN-27 | El error desaparece al corregir | Tras VEN-25, cambiar la cantidad de un producto. | — | El mensaje de error se oculta. | Al cambiar la cantidad con + el mensaje de error desaparece. | ✔ |
| VEN-28 | Doble pulsación al confirmar | Con el flujo normal, tocar `Confirmar venta` dos veces seguidas lo más rápido posible. | — | Se registra una sola venta (una fila en `venta`). El botón muestra un indicador de carga mientras guarda. | Dos clics seguidos sobre "Confirmar venta" crearon una sola venta (Agua pura ×1). | ✔ |

## G. Confirmación y navegación

| ID | Caso | Pasos | Datos | Resultado esperado | Resultado obtenido | ✔/✘ |
|---|---|---|---|---|---|---|
| VEN-29 | Confirmación con total | Registrar una venta. | VEN-04 | `Venta registrada` e indicación del total (`Total: Q36.50`). | "Venta registrada" y "Total: Q36.50". Captura 05. | ✔ |
| VEN-30 | Nueva venta | En la confirmación, tocar `Nueva venta`. | — | Regresa a Registrar venta sin productos seleccionados, con total `Q0.00` y confirmar deshabilitado. | Regresa a Registrar venta con el mensaje de venta vacía, total Q0.00 y confirmar sin efecto. Captura 06. | ✔ |
| VEN-31 | Dos ventas consecutivas | Registrar VEN-01, tocar `Nueva venta` y registrar VEN-02. | — | Ambas ventas aparecen en la base como registros distintos, cada una con sus propios detalles. | VEN-01 y VEN-02 se hicieron seguidas con "Nueva venta": dos ventas con ids distintos y sus propios detalles. Evidencia 09. | ✔ |
| VEN-32 | Volver al catálogo | En la confirmación, tocar `Volver al catálogo`. | — | Se muestra el Catálogo. Al presionar atrás desde ahí no se regresa a Registrar venta ni a la confirmación; el catálogo no aparece duplicado en la pila. | Se muestra el Catálogo sin botón Atrás, es decir, la pila quedó en un solo nivel (sin catálogo duplicado). | ✔ |
| VEN-33 | Botón atrás en la confirmación | En la confirmación, presionar el botón atrás del dispositivo. | — | Regresa a Registrar venta vacía. Confirmar sigue deshabilitado; no se puede duplicar la venta. | Atrás desde la confirmación lleva a Registrar venta vacía; confirmar no responde y no se crea otra venta. | ✔ |
| VEN-34 | Salir sin confirmar | Agregar productos y presionar atrás sin confirmar. | — | Vuelve al Catálogo sin crear ninguna venta. Mientras la app siga abierta, al volver a entrar a Registrar venta se conservan los productos que se habían seleccionado. | Atrás lleva al Catálogo sin crear venta. Al volver a entrar con la app abierta se conservan Pan dulce y Galleta (Q2.70). | ✔ |

## H. Usabilidad y tamaños de pantalla

| ID | Caso | Pasos | Resultado esperado | Resultado obtenido | ✔/✘ |
|---|---|---|---|---|---|
| VEN-35 | Pantalla pequeña (≈ 360×640) | Hacer la venta de VEN-04 en un dispositivo o emulador pequeño. | Sin textos cortados ni franjas de desborde amarillas/negras. Las dos listas, el total y el botón son accesibles. | Ventana de 380×700: sin franjas de desborde. Pero "Venta actual" solo deja ver unas 2 filas (la tercera exige scroll), "Subtotal" se parte en dos líneas y la última fila queda recortada. Captura 10 (ver D-03). | ✘ |
| VEN-36 | Pantalla grande | Repetir en un dispositivo grande. | Misma validación que VEN-35. | Ventana de 1300×900: sin desbordes ni recortes. Captura 13. | ✔ |
| VEN-37 | Rotación | Rotar el dispositivo en Registrar venta y en la confirmación. | La pantalla se adapta, no pierde la venta en curso ni muestra errores. | Apaisado (820×470): la lista de productos muestra una fila y "Venta actual" una fila con el campo de cantidad y el subtotal recortados. No hay errores ni se pierde la venta. Captura 11 (ver D-03). | ✘ |
| VEN-38 | Teclado numérico | Tocar el campo de cantidad. | Aparece teclado numérico. | No ejecutable en Windows de escritorio (no hay teclado táctil) y no se pudo probar en Android. Queda sin ejecutar. | ➖ |
| VEN-39 | Nombre largo | Con un producto de nombre muy largo, agregarlo a la venta. | El nombre se corta con `…` sin romper la fila. | El nombre se corta con "…" ("Refresco gase…") sin romper la fila. Captura 12. | ✔ |
| VEN-40 | Rapidez de la venta | Con cronómetro, registrar una venta de 3 productos. | Anotar el tiempo y cualquier punto que haya costado trabajo (observación de usabilidad, no criterio de aprobación). | No ejecutado: requiere una persona con cronómetro. | ➖ |

---

## Evidencia

Capturas y volcados en [`evidencia-m3/capturas/`](evidencia-m3/capturas/).
No se grabará video del flujo completo (decisión del equipo).

| Paso | Caso | Qué debe verse | Archivo | ✔/✘ |
|---|---|---|---|---|
| 1 | VEN-21 | Registrar venta sin productos en el catálogo. | No ejecutable desde la interfaz (ver VEN-21) | ➖ |
| 2 | VEN-04 | Productos seleccionados con cantidades, subtotales y total `Q36.50`. | [`02-venta-varios-productos.png`](evidencia-m3/capturas/02-venta-varios-productos.png) | ✔ |
| 3 | VEN-14 | Cantidad inválida con mensaje y confirmar deshabilitado. | [`03-error-cantidad.png`](evidencia-m3/capturas/03-error-cantidad.png) | ✔ |
| 4 | VEN-13 | Venta vacía con confirmar deshabilitado. | [`04-venta-vacia.png`](evidencia-m3/capturas/04-venta-vacia.png) | ✔ |
| 5 | VEN-29 | Confirmación con el total. | [`05-confirmacion.png`](evidencia-m3/capturas/05-confirmacion.png) | ✔ |
| 6 | VEN-30 | Nueva venta vacía con `Q0.00`. | [`06-nueva-venta.png`](evidencia-m3/capturas/06-nueva-venta.png) | ✔ |
| 7 | VEN-22 / VEN-23 | Base de datos con las ventas y sus detalles tras reabrir la app, y catálogo intacto. | [`07-persistencia-bd.txt`](evidencia-m3/capturas/07-persistencia-bd.txt), [`07-catalogo-tras-reiniciar.png`](evidencia-m3/capturas/07-catalogo-tras-reiniciar.png) | ✔ |
| 8 | VEN-25 | Mensaje de error de guardado con la selección conservada. | [`08-error-guardado.png`](evidencia-m3/capturas/08-error-guardado.png) | ✔ |
| 9 | VEN-31 | Ventas consecutivas en la base de datos. | [`09-dos-ventas-bd.txt`](evidencia-m3/capturas/09-dos-ventas-bd.txt) | ✔ |
| 10 | VEN-35 | Pantalla pequeña. | [`10-pantalla-pequena.png`](evidencia-m3/capturas/10-pantalla-pequena.png) | ✘ (D-03) |
| 11 | VEN-37 | Apaisado. | [`11-apaisado.png`](evidencia-m3/capturas/11-apaisado.png) | ✘ (D-03) |
| 12 | VEN-39 | Nombre largo. | [`12-nombre-largo.png`](evidencia-m3/capturas/12-nombre-largo.png) | ✔ |
| 13 | VEN-36 | Pantalla grande. | [`13-pantalla-grande.png`](evidencia-m3/capturas/13-pantalla-grande.png) | ✔ |
| 14 | D-01 | Botón flotante tapando "Probar registrar venta". | [`defecto-01-fab-tapa-boton-venta.png`](evidencia-m3/capturas/defecto-01-fab-tapa-boton-venta.png) | — |

## Cobertura automatizada de referencia

Estos casos tienen pruebas automatizadas equivalentes (`flutter test`), que no
reemplazan la ejecución manual pero ayudan a diagnosticar si algo falla:

| Casos manuales | Pruebas automatizadas |
|---|---|
| VEN-01 a VEN-12 | `test/registrar_venta_screen_test.dart`, `test/venta_reglas_negocio_test.dart` |
| VEN-13 a VEN-20 | `test/registrar_venta_screen_test.dart`, `test/venta_reglas_negocio_test.dart` |
| VEN-22, VEN-24 | `test/venta_service_test.dart`, `test/registrar_venta_integracion_test.dart` |
| VEN-25 a VEN-28 | `test/registrar_venta_integracion_test.dart`, `test/venta_reglas_negocio_test.dart` |
| VEN-29 a VEN-33 | `test/registrar_venta_integracion_test.dart` |
| VEN-35 | `test/registrar_venta_integracion_test.dart` (320×568, 360×640 y 412×915) |

El **precio al momento** (que una venta conserve su precio aunque el producto
cambie después) no se puede probar por la interfaz porque todavía no existe una
pantalla de edición de productos; se verifica con `test/venta_service_test.dart`.

## Defectos encontrados

Ningún defecto es **crítico**: se pudo completar, guardar y recuperar ventas
en todos los casos. Los issues de corrección están por crear.

| ID | Caso | Descripción | Severidad | Issue de corrección | Estado |
|---|---|---|---|---|---|
| D-01 | P4 | En el Catálogo, el botón flotante "Agregar producto" cubre el botón "Probar registrar venta" (ventana 430×880). Un clic en el centro de "Probar registrar venta" abre "Agregar producto". Se puede entrar a vender tocando una tarjeta. Captura `defecto-01`. | Media | _por crear_ | Abierto |
| D-02 | VEN-12 | El Catálogo muestra los precios con `$` y Registrar venta con `Q`. | Baja | Corregido en este PR (verificado en la app, captura `14-catalogo-en-quetzales.png`) | Corregido |
| D-03 | VEN-35, VEN-37 | En pantallas pequeñas o en apaisado, la lista de productos y "Venta actual" se reparten el alto a partes iguales: "Venta actual" muestra solo 1–2 filas, el subtotal se parte en dos líneas y las filas quedan recortadas. Capturas 10 y 11. | Media | _por crear_ | Abierto |
| D-04 | VEN-14 a VEN-18 | Con una cantidad inválida escrita, el subtotal y el total siguen mostrando el último valor válido, que no coincide con lo que se ve en el campo. | Baja | _por crear_ | Abierto |
| D-05 | VEN-21 | Registrar venta solo es accesible con productos, por lo que su mensaje de catálogo vacío no se puede ver desde la interfaz. No es un fallo, pero deja ese caso sin poder probarse a mano. | Baja | — | Informativo |

Severidad: **crítica** (impide vender o pierde/corrompe datos), **media**
(funciona pero confunde o falla en un caso poco común), **baja** (cosmética).

### Observaciones que quedan sin comprobar

- **Id de venta:** se genera con el reloj en microsegundos; dos ventas
  confirmadas casi simultáneamente podrían recibir el mismo id. No se observó en
  la ejecución (VEN-28 con doble clic creó una sola venta).
- **Sin consulta de ventas:** hasta que exista la consulta básica de ventas, la
  persistencia solo se puede comprobar inspeccionando la base de datos.

## Resultado general

| Total de casos | Aprobados | Fallidos | No ejecutados |
|---|---|---|---|
| 40 | 35 | 2 (VEN-35, VEN-37) | 3 (VEN-21, VEN-38, VEN-40) |
