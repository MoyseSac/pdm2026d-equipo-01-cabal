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

> **Estado:** plan definido. Las columnas **Resultado obtenido** y **✔/✘**
> están vacías hasta que alguien ejecute las pruebas (ver
> [Datos de la ejecución](#datos-de-la-ejecución)). Las capturas se guardan en
> `docs/evidencia-m3/capturas/`.

## Datos de la ejecución

Completar al ejecutar.

| Dato | Valor |
|---|---|
| Fecha | _pendiente_ |
| Quién ejecutó | _pendiente_ |
| Rama / commit probado | _pendiente_ |
| Dispositivo (emulador o físico) | _pendiente_ |
| Versión del sistema | _pendiente_ |

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
| VEN-01 | Venta mínima | 1. Entrar a Registrar venta. 2. Tocar `Coca Cola`. 3. Tocar `Confirmar venta`. | Coca Cola ×1 | Aparece en `Venta actual` con cantidad 1, subtotal `Q10.50` y total `Q10.50`. Al confirmar se muestra `Venta registrada` y `Total: Q10.50`. En la base: 1 fila en `venta` y 1 en `detalle_venta` (cantidad 1, precio 10.5). | | |
| VEN-02 | Cambiar la cantidad escribiéndola | 1. Tocar `Coca Cola`. 2. Cambiar el campo de cantidad a `4`. 3. Confirmar. | Coca Cola ×4 | Subtotal `Q42.00` y total `Q42.00`. Confirmación con `Total: Q42.00`. En la base: cantidad 4, precio 10.5. | | |
| VEN-03 | Cambiar la cantidad con +/− | 1. Tocar `Coca Cola`. 2. Tocar `+` dos veces. 3. Tocar `−` una vez. | Coca Cola ×2 | Cantidad 2, subtotal `Q21.00`. El botón `−` está deshabilitado cuando la cantidad es 1. | | |

## B. Venta con varios productos y distintas cantidades

| ID | Caso | Pasos | Datos | Resultado esperado | Resultado obtenido | ✔/✘ |
|---|---|---|---|---|---|---|
| VEN-04 | Varios productos | 1. Tocar `Coca Cola`, `Pan dulce` y `Agua pura`. 2. Poner cantidades 2, 3 y 1. 3. Confirmar. | Coca Cola ×2, Pan dulce ×3, Agua pura ×1 | Subtotales `Q21.00`, `Q7.50` y `Q8.00`; total `Q36.50`. Confirmación con `Total: Q36.50`. En la base: 1 venta y 3 detalles con las cantidades y precios indicados. | | |
| VEN-05 | Producto repetido no se duplica | 1. Tocar `Coca Cola` tres veces. | Coca Cola ×3 | Una sola fila de `Coca Cola` con cantidad 3 y subtotal `Q31.50`. | | |
| VEN-06 | Eliminar un producto | 1. Agregar `Coca Cola` y `Pan dulce`. 2. Eliminar `Coca Cola` con el ícono de basura. | — | Solo queda `Pan dulce`; el total se actualiza a `Q2.50`. | | |
| VEN-07 | Eliminar todos los productos | 1. Agregar un producto. 2. Eliminarlo. | — | `Venta actual` vuelve al mensaje de venta vacía, el total es `Q0.00` y `Confirmar venta` queda deshabilitado. | | |

## C. Cálculo de subtotales y total

| ID | Caso | Pasos | Datos | Resultado esperado | Resultado obtenido | ✔/✘ |
|---|---|---|---|---|---|---|
| VEN-08 | Total con decimales | Agregar `Chicle`, `Galleta` y `Dulce`, cantidad 1 cada uno. | 0.10 + 0.20 + 0.30 | Total `Q0.60` (sin `Q0.6000…` ni `Q0.59`). | | |
| VEN-09 | Subtotal con redondeo | Agregar `Aceite` con cantidad 3. | 19.99 × 3 | Subtotal y total `Q59.97`. | | |
| VEN-10 | Cantidad grande | Agregar `Coca Cola` con cantidad `100`. | 10.50 × 100 | Subtotal y total `Q1050.00`. | | |
| VEN-11 | El total sigue a cada cambio | Agregar un producto, subir su cantidad, agregar otro y eliminar el primero. | — | Después de cada acción el total refleja exactamente la suma de los subtotales visibles. | | |
| VEN-12 | Formato en quetzales | Revisar precios y totales en toda la pantalla. | — | Todos con prefijo `Q` y dos decimales. | | |

## D. Venta vacía o con datos inválidos

| ID | Caso | Pasos | Datos | Resultado esperado | Resultado obtenido | ✔/✘ |
|---|---|---|---|---|---|---|
| VEN-13 | Venta vacía | Entrar a Registrar venta sin tocar productos. | — | Total `Q0.00`. `Confirmar venta` deshabilitado. No se puede registrar nada. | | |
| VEN-14 | Cantidad 0 | Agregar un producto y escribir `0` en la cantidad. | `0` | Campo en rojo y mensaje `La cantidad debe ser mayor que cero.`; `Confirmar venta` deshabilitado. | | |
| VEN-15 | Cantidad negativa | Escribir `-1`. | `-1` | Mismo mensaje que VEN-14; confirmar deshabilitado. | | |
| VEN-16 | Cantidad decimal | Escribir `1.5`. | `1.5` | Mensaje `La cantidad debe ser un número entero.`; confirmar deshabilitado. | | |
| VEN-17 | Cantidad no numérica | Escribir `abc`. | `abc` | Mensaje `Ingresa una cantidad válida.`; confirmar deshabilitado. | | |
| VEN-18 | Cantidad vacía | Borrar el contenido del campo. | (vacío) | Mensaje `Ingresa una cantidad válida.`; confirmar deshabilitado. | | |
| VEN-19 | Corregir la cantidad | Provocar VEN-14 y luego escribir `2`. | `0` → `2` | El mensaje desaparece, el subtotal se calcula con 2 y confirmar se habilita. | | |
| VEN-20 | Un producto inválido bloquea toda la venta | Agregar dos productos y poner `0` en el segundo. | — | Confirmar deshabilitado. Al eliminar el producto inválido se habilita. | | |
| VEN-21 | Catálogo sin productos | Con instalación limpia, entrar a Registrar venta. | — | Mensaje `No hay productos registrados` con indicación de agregar productos al catálogo y botón `Agregar producto`. | | |

## E. Persistencia

| ID | Caso | Pasos | Datos | Resultado esperado | Resultado obtenido | ✔/✘ |
|---|---|---|---|---|---|---|
| VEN-22 | La venta sobrevive al reinicio | 1. Registrar la venta de VEN-04. 2. Cerrar la app por completo. 3. Abrirla de nuevo. 4. Revisar la base. | VEN-04 | La venta y sus 3 detalles siguen en `venta` y `detalle_venta` con los mismos valores. | | |
| VEN-23 | El catálogo sobrevive al reinicio | Tras VEN-22, abrir el Catálogo. | — | Los productos cargados en P3 siguen ahí. | | |
| VEN-24 | La venta en curso no se guarda sin confirmar | 1. Agregar productos sin confirmar. 2. Cerrar la app por completo. 3. Revisar la base. | — | No se creó ninguna venta nueva. | | |

## F. Errores durante el guardado

Requieren provocar el error como se indica en [Cómo provocar un error de
guardado](#cómo-provocar-un-error-de-guardado).

| ID | Caso | Pasos | Datos | Resultado esperado | Resultado obtenido | ✔/✘ |
|---|---|---|---|---|---|---|
| VEN-25 | Falla el guardado | Con el error provocado, agregar `Coca Cola` ×2 y confirmar. | Coca Cola ×2 | Aparece `No se pudo registrar la venta. Intenta de nuevo.`. **No** se muestra `Venta registrada`. Los productos y cantidades siguen en pantalla. En la base no se creó ninguna venta ni detalle. | | |
| VEN-26 | Reintento exitoso | Tras VEN-25, quitar la excepción provocada, recompilar y repetir la venta. | — | La venta se guarda una sola vez y se muestra la confirmación. | | |
| VEN-27 | El error desaparece al corregir | Tras VEN-25, cambiar la cantidad de un producto. | — | El mensaje de error se oculta. | | |
| VEN-28 | Doble pulsación al confirmar | Con el flujo normal, tocar `Confirmar venta` dos veces seguidas lo más rápido posible. | — | Se registra una sola venta (una fila en `venta`). El botón muestra un indicador de carga mientras guarda. | | |

## G. Confirmación y navegación

| ID | Caso | Pasos | Datos | Resultado esperado | Resultado obtenido | ✔/✘ |
|---|---|---|---|---|---|---|
| VEN-29 | Confirmación con total | Registrar una venta. | VEN-04 | `Venta registrada` e indicación del total (`Total: Q36.50`). | | |
| VEN-30 | Nueva venta | En la confirmación, tocar `Nueva venta`. | — | Regresa a Registrar venta sin productos seleccionados, con total `Q0.00` y confirmar deshabilitado. | | |
| VEN-31 | Dos ventas consecutivas | Registrar VEN-01, tocar `Nueva venta` y registrar VEN-02. | — | Ambas ventas aparecen en la base como registros distintos, cada una con sus propios detalles. | | |
| VEN-32 | Volver al catálogo | En la confirmación, tocar `Volver al catálogo`. | — | Se muestra el Catálogo. Al presionar atrás desde ahí no se regresa a Registrar venta ni a la confirmación; el catálogo no aparece duplicado en la pila. | | |
| VEN-33 | Botón atrás en la confirmación | En la confirmación, presionar el botón atrás del dispositivo. | — | Regresa a Registrar venta vacía. Confirmar sigue deshabilitado; no se puede duplicar la venta. | | |
| VEN-34 | Salir sin confirmar | Agregar productos y presionar atrás sin confirmar. | — | Vuelve al Catálogo sin crear ninguna venta. Mientras la app siga abierta, al volver a entrar a Registrar venta se conservan los productos que se habían seleccionado. | | |

## H. Usabilidad y tamaños de pantalla

| ID | Caso | Pasos | Resultado esperado | Resultado obtenido | ✔/✘ |
|---|---|---|---|---|---|
| VEN-35 | Pantalla pequeña (≈ 360×640) | Hacer la venta de VEN-04 en un dispositivo o emulador pequeño. | Sin textos cortados ni franjas de desborde amarillas/negras. Las dos listas, el total y el botón son accesibles. | | |
| VEN-36 | Pantalla grande | Repetir en un dispositivo grande. | Misma validación que VEN-35. | | |
| VEN-37 | Rotación | Rotar el dispositivo en Registrar venta y en la confirmación. | La pantalla se adapta, no pierde la venta en curso ni muestra errores. | | |
| VEN-38 | Teclado numérico | Tocar el campo de cantidad. | Aparece teclado numérico. | | |
| VEN-39 | Nombre largo | Con un producto de nombre muy largo, agregarlo a la venta. | El nombre se corta con `…` sin romper la fila. | | |
| VEN-40 | Rapidez de la venta | Con cronómetro, registrar una venta de 3 productos. | Anotar el tiempo y cualquier punto que haya costado trabajo (observación de usabilidad, no criterio de aprobación). | | |

---

## Evidencia

Guardar las capturas en `docs/evidencia-m3/capturas/` con estos nombres, y un
video corto del flujo completo como `flujo-completo.mp4` (o enlazarlo si
pesa demasiado).

| Paso | Caso | Qué debe verse | Archivo | ✔/✘ |
|---|---|---|---|---|
| 1 | VEN-21 | Registrar venta sin productos en el catálogo. | `01-venta-sin-productos.png` | |
| 2 | VEN-04 | Productos seleccionados con cantidades, subtotales y total `Q36.50`. | `02-venta-varios-productos.png` | |
| 3 | VEN-14 | Cantidad inválida con mensaje y confirmar deshabilitado. | `03-error-cantidad.png` | |
| 4 | VEN-13 | Venta vacía con confirmar deshabilitado. | `04-venta-vacia.png` | |
| 5 | VEN-29 | Confirmación con el total. | `05-confirmacion.png` | |
| 6 | VEN-30 | Nueva venta vacía con `Q0.00`. | `06-nueva-venta.png` | |
| 7 | VEN-22 | Base de datos con la venta y sus detalles tras reabrir la app. | `07-persistencia-bd.png` | |
| 8 | VEN-25 | Mensaje de error de guardado con la selección conservada. | `08-error-guardado.png` | |
| 9 | VEN-31 | Dos ventas consecutivas en la base de datos. | `09-dos-ventas-bd.png` | |
| 10 | VEN-35 | Pantalla pequeña sin desbordes. | `10-pantalla-pequena.png` | |

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

Registrar aquí cada defecto detectado durante la ejecución. Los de severidad
**crítica** deben corregirse o vincularse a un issue de corrección antes de
cerrar M3.

| ID | Caso | Descripción | Severidad | Issue de corrección | Estado |
|---|---|---|---|---|---|
| _pendiente_ | | | | | |

Severidad: **crítica** (impide vender o pierde/corrompe datos), **media**
(funciona pero confunde o falla en un caso poco común), **baja** (cosmética).

### Observaciones previas por confirmar al ejecutar

Detectadas al revisar el código y las pruebas automatizadas; **no** son
resultados de la ejecución manual.

- **Moneda inconsistente:** Registrar venta y la confirmación muestran `Q`,
  pero el Catálogo todavía muestra `$` (relacionado con VEN-12).
- **Botón tapado en el Catálogo:** en una prueba automatizada de M2, el botón
  flotante "Agregar producto" cubría el botón "Probar registrar venta" en una
  pantalla de 400×800. Confirmar si ocurre en dispositivo real, porque es la
  puerta de entrada a Registrar venta (P4).
- **Id de venta:** se genera con el reloj en microsegundos; dos ventas
  confirmadas casi simultáneamente podrían recibir el mismo id. Improbable en
  uso real (VEN-31).
- **Sin consulta de ventas:** hasta que exista la consulta básica de ventas,
  la persistencia solo se puede comprobar inspeccionando la base de datos.

## Resultado general

Completar tras ejecutar.

| Total de casos | Aprobados | Fallidos | No ejecutados |
|---|---|---|---|
| 40 | | | |
