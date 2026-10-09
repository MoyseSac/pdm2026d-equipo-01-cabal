# Reglas de negocio y criterios de aceptación — Registro de ventas

## Objetivo

Este documento define las reglas que debe cumplir el registro de una venta
antes de implementar su lógica y sus pantallas. Su propósito es garantizar que
las ventas sean válidas, que los cálculos sean correctos y que la información
almacenada sea consistente.

Este documento únicamente define y documenta reglas. La implementación de
pantallas, servicios y cálculos queda fuera de su alcance.

## Documentos y modelos relacionados

| Referencia | Qué aporta |
|---|---|
| `alcance_m2.md` | Prioridades del milestone: el registro de ventas se implementa después del catálogo. |
| `validacion_producto.md` | Reglas de precio de producto (positivo, máximo 2 decimales) que determinan qué precios pueden llegar a una venta. |
| `esquema_sql.md` | Tablas `venta` y `detalle_venta` en las que se persiste la venta. |
| `app_cabal/lib/models/venta.dart` | Modelo `Venta`: `id`, `fechaHora`, `detalles`. |
| `app_cabal/lib/models/detalle_venta.dart` | Modelo `DetalleVenta`: `producto`, `cantidad`, `precioAlMomento`. |

## 1. Datos obligatorios de una venta

Para registrar una venta son obligatorios los siguientes datos:

| Dato | Nivel | Origen | Campo del modelo / columna |
|---|---|---|---|
| Identificador | Venta | Generado por la app; el tendero no lo ingresa | `Venta.id` / `venta.id` |
| Fecha y hora | Venta | Asignada automáticamente al confirmar la venta | `Venta.fechaHora` / `venta.fecha_hora` |
| Productos | Venta | Seleccionados del catálogo | `Venta.detalles` / filas de `detalle_venta` |
| Cantidad | Detalle | Ingresada por el tendero | `DetalleVenta.cantidad` / `cantidad` |
| Precio unitario | Detalle | Tomado del catálogo al momento de la venta | `DetalleVenta.precioAlMomento` / `precio_al_momento` |
| Total | Venta | Calculado por la app (ver sección 4) | No se almacena; se deriva de los detalles |

Reglas sobre estos datos:

- **Fecha y hora:** la asigna la app con la hora del dispositivo en el momento
  de confirmar la venta. El tendero no la escribe ni la edita. Se guarda como
  texto en formato ISO 8601, según `esquema_sql.md`.
- **Total:** no se guarda como columna. Se calcula siempre a partir de los
  detalles, de modo que no pueda contradecirlos.
- Cada detalle debe referirse a un producto que exista en el catálogo.

## 2. Una venta debe tener al menos un producto

- Una venta debe contener **al menos un detalle**.
- No se permite guardar una venta con la lista de detalles vacía.
- Mientras no haya productos en la venta, la acción de confirmar debe estar
  deshabilitada o, si se intenta, debe rechazarse.

Mensaje de error:

`Agrega al menos un producto a la venta.`

## 3. Cantidades

Cada detalle debe cumplir:

- La cantidad es un **número entero**.
- La cantidad es **mayor que cero** (mínimo `1`).

Casos inválidos:

| Entrada | Motivo |
|---|---|
| `0` | No es mayor que cero |
| `-1`, `-3` | Negativa |
| `1.5`, `2.0` | No es entero |
| `abc` | No es un número |
| Vacío | Falta la cantidad |

Mensajes de error:

| Caso | Mensaje |
|---|---|
| Vacío o no numérico | `Ingresa una cantidad válida.` |
| Decimal | `La cantidad debe ser un número entero.` |
| Cero o negativa | `La cantidad debe ser mayor que cero.` |

Antes de validar se eliminan los espacios al inicio y al final del valor.

Esta definición no establece una cantidad máxima.

## 4. Precios, subtotales y total

### Precio unitario válido

El precio utilizado en un detalle debe cumplir las mismas reglas definidas en
`validacion_producto.md`: número mayor que cero y con máximo 2 decimales. Si el
producto del catálogo tuviera un precio que no cumpla estas reglas, la venta
no debe registrarse (ver sección 8).

### Cálculo

```text
subtotal de un detalle = cantidad × precioAlMomento
total de la venta      = suma de los subtotales de todos los detalles
```

- Los cálculos usan el `precioAlMomento` del detalle, nunca el precio actual
  del catálogo.
- El resultado se redondea a **2 decimales** al mostrarse y al calcular el
  total, para evitar errores de representación de números decimales (por
  ejemplo, que `0.1 + 0.2` produzca `0.30000000000000004`).
- El total siempre es mayor que cero, porque toda venta tiene al menos un
  producto con cantidad y precio positivos.

Ejemplo:

| Producto | Cantidad | Precio al momento | Subtotal |
|---|---|---|---|
| Coca Cola | 2 | 10.50 | 21.00 |
| Pan dulce | 3 | 2.50 | 7.50 |
| **Total** | | | **28.50** |

## 5. Conservación del precio al momento de la venta

- Al registrar la venta, el precio vigente del producto en el catálogo se
  **copia** a `DetalleVenta.precioAlMomento` y se guarda en
  `detalle_venta.precio_al_momento`.
- Si después el precio del producto cambia en el catálogo, las ventas
  anteriores **no se modifican**: conservan el precio con el que se vendieron.
- Una venta ya registrada no debe recalcularse con el precio actual del
  producto.
- Las ventas nuevas usan el precio del catálogo vigente en el momento de
  confirmarlas.

## 6. Productos repetidos

El esquema define la llave primaria de `detalle_venta` como
`(venta_id, producto_id)`. Por lo tanto, **un mismo producto solo puede
aparecer una vez dentro de una venta**.

Regla:

- Si el tendero agrega un producto que ya está en la venta, **no se crea un
  segundo detalle**: se suma la nueva cantidad a la del detalle existente.
- El detalle resultante conserva el `precioAlMomento` con el que se agregó
  por primera vez dentro de esa venta.
- La cantidad resultante debe seguir siendo un entero mayor que cero.

Ejemplo: agregar Coca Cola ×2 y luego Coca Cola ×1 produce un único detalle
de Coca Cola ×3.

## 7. Ventas sin productos

- Una venta sin productos **no se guarda**: no se crea el registro en
  `venta` ni ninguna fila en `detalle_venta`.
- Si el tendero quita todos los productos de una venta en curso, la venta
  vuelve a estar vacía y aplica la regla de la sección 2.
- Si el catálogo está vacío, no se puede iniciar una venta; se debe indicar al
  tendero que primero agregue productos.

Mensaje cuando no hay productos en el catálogo:

`Agrega productos al catálogo para registrar ventas.`

## 8. Errores durante el guardado

Una venta se compone de una fila en `venta` y una o más en `detalle_venta`.
Para que la información sea consistente:

1. **Todo o nada.** El guardado de la venta y de todos sus detalles debe
   hacerse en una sola transacción. Si falla cualquier parte, no queda
   ninguna información de la venta en la base de datos (ni venta sin detalles
   ni detalles sin venta).
2. **Validar antes de guardar.** Se validan las reglas de las secciones 2, 3 y
   4 antes de abrir la transacción. Si algo es inválido, no se intenta
   guardar.
3. **No perder lo capturado.** Si el guardado falla, la venta en curso se
   conserva en pantalla para que el tendero pueda reintentar sin volver a
   capturarla.
4. **Mensaje claro.** Se informa del error al tendero y no se navega a la
   pantalla de confirmación de venta.
5. **Sin doble registro.** Mientras se guarda, la acción de confirmar queda
   deshabilitada para evitar que un doble toque cree dos ventas.
6. **Confirmación solo si se guardó.** La pantalla de confirmación de venta
   se muestra únicamente cuando la transacción terminó correctamente.

Mensaje de error de guardado:

`No se pudo registrar la venta. Intenta de nuevo.`

Situaciones consideradas:

| Situación | Resultado esperado |
|---|---|
| Falla de la base de datos al guardar | No se guarda nada; se muestra el mensaje de error de guardado; la venta en curso se conserva. |
| Producto del detalle ya no existe en el catálogo | La venta no se guarda; se muestra el mensaje de error de guardado. |
| Falla al guardar un detalle intermedio | Se revierte toda la transacción; no queda la venta parcial. |
| Doble toque en confirmar | Se registra una sola venta. |

## 9. Resumen de reglas

| # | Regla |
|---|---|
| R1 | Una venta tiene id, fecha y hora, productos con cantidad y precio unitario, y un total calculado. |
| R2 | La fecha y hora se asignan automáticamente al confirmar. |
| R3 | Una venta debe tener al menos un producto. |
| R4 | La cantidad es un entero mayor que cero. |
| R5 | El precio unitario cumple las reglas de precio de producto. |
| R6 | Subtotal = cantidad × precio al momento; total = suma de subtotales, redondeado a 2 decimales. |
| R7 | El precio del producto se copia a la venta y no cambia aunque el catálogo cambie. |
| R8 | Un producto repetido se fusiona en un solo detalle sumando cantidades. |
| R9 | Una venta sin productos no se guarda. |
| R10 | El guardado es atómico: todo o nada. |
| R11 | Si el guardado falla, se informa al tendero y la venta en curso se conserva. |

## 10. Criterios de aceptación

Estos criterios permiten verificar que el registro de ventas funciona de
principio a fin una vez implementado. Cada uno debe poder comprobarse con
datos concretos.

### Flujo principal

- [ ] **CA-01.** Con al menos un producto en el catálogo, el tendero puede
  seleccionar un producto, indicar una cantidad válida y confirmar la venta.
- [ ] **CA-02.** Al confirmar, la venta queda guardada con un id, la fecha y
  hora actuales y un detalle por producto con su cantidad y precio al momento.
- [ ] **CA-03.** Tras guardar correctamente, se muestra la confirmación de
  venta.
- [ ] **CA-04.** Una venta con varios productos distintos guarda un detalle por
  cada producto.
- [ ] **CA-05.** La venta sigue presente después de cerrar y volver a abrir la
  app.

### Datos y validaciones

- [ ] **CA-06.** No se puede confirmar una venta sin productos; se muestra
  `Agrega al menos un producto a la venta.` y no se crea ningún registro.
- [ ] **CA-07.** Las cantidades `0`, `-1`, `1.5` y `abc` son rechazadas con el
  mensaje correspondiente, y `1` y `25` son aceptadas.
- [ ] **CA-08.** Un campo de cantidad vacío es rechazado con
  `Ingresa una cantidad válida.`
- [ ] **CA-09.** La fecha y hora no pueden ser escritas por el tendero y
  corresponden al momento de confirmar la venta.

### Cálculos

- [ ] **CA-10.** El subtotal de cada producto es cantidad × precio al momento.
- [ ] **CA-11.** El total es la suma de los subtotales. Con Coca Cola ×2 a
  10.50 y Pan dulce ×3 a 2.50, el total es 28.50.
- [ ] **CA-12.** Sumar valores con decimales no produce resultados con errores
  de representación: con tres productos de 0.10 ×1, 0.20 ×1 y 0.30 ×1 el total
  es 0.60.

### Precio al momento

- [ ] **CA-13.** Se registra una venta de un producto a 10.00; luego se edita
  el producto a 12.00; la venta ya registrada conserva 10.00 como precio al
  momento y su total no cambia.
- [ ] **CA-14.** Una venta nueva del mismo producto, hecha después del cambio,
  usa 12.00.

### Productos repetidos

- [ ] **CA-15.** Agregar el mismo producto dos veces (×2 y ×1) a la misma venta
  produce un único detalle con cantidad 3 y no genera error de llave
  duplicada.

### Errores de guardado

- [ ] **CA-16.** Si falla el guardado, se muestra
  `No se pudo registrar la venta. Intenta de nuevo.`, no se navega a la
  confirmación y la venta en curso se conserva.
- [ ] **CA-17.** Si falla el guardado de un detalle, no queda en la base de
  datos ni la venta ni ningún detalle de esa venta.
- [ ] **CA-18.** Un doble toque en confirmar registra una sola venta.

## Fuera de alcance

- Implementación de pantallas, servicios, providers y cálculos.
- Cierre del día y consulta de ventas registradas.
- Descuentos, impuestos, formas de pago, devoluciones, cancelación o edición
  de ventas ya registradas, y control de existencias.
