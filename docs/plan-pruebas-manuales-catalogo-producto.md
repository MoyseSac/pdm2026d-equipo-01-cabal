# Plan de pruebas manuales — Catálogo y Agregar producto (M2)

## Propósito

Guía de qué probar antes de dar por cerrado el flujo de catálogo y alta de
producto. Sirve como **checklist de revisión de PRs** de las pantallas de
este milestone: quien revise (QA o cualquier integrante) verifica lo mismo
que se definió como criterio de aceptación, sin improvisar.

- Pantallas cubiertas: **Catálogo** (#34) y **Agregar producto** (#35).
- **Fuera de alcance:** la ejecución de las pruebas y la evidencia de que
  pasaron. Este documento solo define el plan.
- Reglas de validación tomadas de `app_cabal/lib/validators/producto_validator.dart`.

## Precondiciones generales

| # | Precondición |
|---|---|
| P1 | App compilada y corriendo desde la rama del PR (`flutter run`) en emulador o dispositivo. |
| P2 | Para las pruebas de catálogo vacío: instalación limpia (desinstalar la app o borrar datos) para que la base SQLite no tenga productos. |
| P3 | Flujo de entrada: Login (placeholder) → botón "Ingresar" → Catálogo. |

## Reglas de validación (referencia)

| Campo | Regla | Mensaje esperado |
|---|---|---|
| Nombre | Obligatorio; no puede ser solo espacios | `Ingresa el nombre del producto.` |
| Precio | Obligatorio; no puede ser solo espacios | `Ingresa el precio del producto.` |
| Precio | Debe ser un número | `Ingresa un precio válido.` |
| Precio | Mayor que cero | `El precio debe ser mayor que cero.` |
| Precio | Máximo 2 decimales | `El precio puede tener máximo 2 decimales.` |

La validación se dispara al pulsar **Guardar producto**; si hay errores no
se guarda nada y el formulario permanece abierto.

---

## A. Pantalla de Catálogo

| ID | Caso | Pasos | Resultado esperado | ✔/✘ |
|---|---|---|---|---|
| CAT-01 | Catálogo vacío — estado especial | Con P2, entrar al Catálogo. | Se muestra el estado vacío: ícono, título "Catálogo vacío", texto "No hay productos registrados aún" y botón "Agregar primer producto". No se muestra el grid ni el botón "Probar registrar venta". | |
| CAT-02 | Catálogo vacío — acción principal | En el estado vacío, pulsar "Agregar primer producto". | Navega a la pantalla "Agregar producto" con el formulario vacío. | |
| CAT-03 | Catálogo vacío — botón flotante | En el estado vacío, pulsar el botón flotante "Agregar producto". | Navega a "Agregar producto". | |
| CAT-04 | Catálogo con productos — grid | Con al menos 3 productos cargados, entrar al Catálogo. | Se muestra un grid de **2 columnas**. Cada tarjeta muestra imagen placeholder, nombre y precio. | |
| CAT-05 | Formato de precio | Revisar productos con precios 10, 10.5 y 10.55. | Se muestran como `$10.00`, `$10.50` y `$10.55` (siempre 2 decimales, prefijo `$`). | |
| CAT-06 | Nombre largo | Tener un producto con nombre de más de 2 líneas. | El nombre se corta a máximo 2 líneas con `…`; la tarjeta no se desborda ni rompe el layout. | |
| CAT-07 | Muchos productos — scroll | Tener más productos de los que caben en pantalla (≥ 10). | El grid hace scroll vertical sin errores y el botón inferior sigue visible. | |
| CAT-08 | Navegación desde tarjeta | Tocar una tarjeta de producto. | Navega a "Registrar venta". | |
| CAT-09 | Botón "Probar registrar venta" | Con productos, pulsar "Probar registrar venta". | Navega a "Registrar venta". | |
| CAT-10 | Botón flotante con productos | Con productos, pulsar "Agregar producto". | Navega a "Agregar producto". | |
| CAT-11 | Rotación de pantalla | Rotar el dispositivo en el Catálogo (con y sin productos). | La pantalla se adapta sin overflow ni excepciones en consola. | |
| CAT-12 | Persistencia | Con productos cargados, cerrar la app por completo y volver a abrirla. | El Catálogo muestra los mismos productos. | |

## B. Pantalla Agregar producto

### B.1 Estructura

| ID | Caso | Pasos | Resultado esperado | ✔/✘ |
|---|---|---|---|---|
| AGR-01 | Estado inicial | Abrir "Agregar producto". | Título "Agregar producto"; campos "Nombre del producto" (hint `Ej: Coca Cola`) y "Precio" (hint `Ej: 10.50`) vacíos; botón "Guardar producto" habilitado; sin mensajes de error visibles. | |
| AGR-02 | Teclado del precio | Tocar el campo Precio. | Se abre teclado numérico con opción de punto decimal. | |

### B.2 Casos válidos

| ID | Nombre | Precio | Resultado esperado | ✔/✘ |
|---|---|---|---|---|
| AGR-V01 | `Coca Cola` | `10.50` | Se guarda, se vuelve al Catálogo y el producto aparece con `$10.50`. | |
| AGR-V02 | `Pan` | `5` | Se guarda; aparece con `$5.00` (precio entero válido). | |
| AGR-V03 | `Chicle` | `0.01` | Se guarda; aparece con `$0.01` (mínimo positivo). | |
| AGR-V04 | `Aceite` | `12.5` | Se guarda; aparece con `$12.50` (un decimal válido). | |
| AGR-V05 | `  Leche  ` | `18` | Se guarda con el nombre **sin espacios** al inicio/fin (`Leche`). | |
| AGR-V06 | Nombre de ~50 caracteres | `20` | Se guarda; en el Catálogo se corta con `…` sin romper el layout (ver CAT-06). | |
| AGR-V07 | `Café ñandú 100%` | `35` | Se guarda y muestra correctamente acentos, ñ y símbolos. | |
| AGR-V08 | `Arroz` | `  25.00  ` | Se guarda (el precio se recorta); aparece `$25.00`. | |
| AGR-V09 | Dos productos con el mismo nombre (`Pan` dos veces) | `5` | Ambos se guardan sin error (no hay regla de unicidad); ambos aparecen en el Catálogo. | |

### B.3 Casos inválidos

En todos: el producto **no** se guarda, la pantalla permanece abierta y el
Catálogo no cambia al volver atrás.

| ID | Nombre | Precio | Resultado esperado | ✔/✘ |
|---|---|---|---|---|
| AGR-I01 | *(vacío)* | `10` | Error bajo Nombre: `Ingresa el nombre del producto.` | |
| AGR-I02 | `   ` (solo espacios) | `10` | Error bajo Nombre: `Ingresa el nombre del producto.` | |
| AGR-I03 | `Pan` | *(vacío)* | Error bajo Precio: `Ingresa el precio del producto.` | |
| AGR-I04 | `Pan` | `   ` (solo espacios) | Error bajo Precio: `Ingresa el precio del producto.` | |
| AGR-I05 | *(vacío)* | *(vacío)* | Ambos errores a la vez (Nombre y Precio). | |
| AGR-I06 | `Pan` | `abc` | Error bajo Precio: `Ingresa un precio válido.` | |
| AGR-I07 | `Pan` | `10,50` (coma) | Error bajo Precio: `Ingresa un precio válido.` | |
| AGR-I08 | `Pan` | `$10` | Error bajo Precio: `Ingresa un precio válido.` | |
| AGR-I09 | `Pan` | `0` | Error bajo Precio: `El precio debe ser mayor que cero.` | |
| AGR-I10 | `Pan` | `0.00` | Error bajo Precio: `El precio debe ser mayor que cero.` | |
| AGR-I11 | `Pan` | `-5` | Error bajo Precio: `El precio debe ser mayor que cero.` | |
| AGR-I12 | `Pan` | `10.999` | Error bajo Precio: `El precio puede tener máximo 2 decimales.` | |
| AGR-I13 | `Pan` | `0.001` | Error bajo Precio: `El precio puede tener máximo 2 decimales.` | |

### B.4 Comportamiento del formulario

| ID | Caso | Pasos | Resultado esperado | ✔/✘ |
|---|---|---|---|---|
| AGR-F01 | Corregir tras error | Provocar AGR-I09, corregir el precio a `9.99` y guardar. | El error desaparece y el producto se guarda. | |
| AGR-F02 | Errores no persisten al reabrir | Provocar un error, volver atrás y abrir de nuevo "Agregar producto". | El formulario aparece limpio, sin textos ni errores previos. | |
| AGR-F03 | Doble toque en Guardar | Con datos válidos, pulsar "Guardar producto" dos veces rápido. | Se crea **un solo** producto (el botón se deshabilita y muestra indicador de carga mientras guarda). | |
| AGR-F04 | Botón atrás sin guardar | Escribir datos válidos y pulsar atrás sin guardar. | Vuelve al Catálogo y no se crea el producto. | |
| AGR-F05 | Persistencia tras guardar | Guardar un producto válido, cerrar la app por completo y reabrir. | El producto sigue en el Catálogo. | |
| AGR-F06 | Primer producto desde catálogo vacío | Con P2, agregar un producto válido desde el estado vacío. | Al volver, el estado vacío desaparece y se muestra el grid con el producto. | |

---

## Cómo usar este documento en la revisión de un PR

1. Identificar qué pantalla toca el PR (Catálogo, Agregar producto o ambas).
2. Ejecutar los casos de la sección correspondiente y marcar ✔/✘ en una copia
   del checklist (en la descripción del PR o en un comentario).
3. Si un caso falla, registrar ID, pasos y resultado obtenido; el PR no se
   da por cerrado hasta resolverlo o acordar explícitamente el cambio de
   criterio.
4. Si el PR cambia una regla de validación o un texto de la UI, actualizar
   este documento en el mismo PR.

## Observaciones para el equipo (a confirmar al ejecutar el plan)

Detectadas al leer el código; no son parte del criterio de aceptación, pero
conviene verificarlas al ejecutar el plan:

- **Mensaje "Producto agregado":** el Catálogo muestra el SnackBar solo si
  la pantalla de alta devuelve `true`, pero `AgregarProductoScreen` hace
  `Navigator.pop()` sin resultado. En AGR-V01 probablemente **no** aparezca
  el mensaje. Si se espera confirmación visual, es un defecto a corregir.
- **Valores especiales de precio:** `double.parse` acepta textos como `NaN`,
  `Infinity` o `1e2`, y el validador actual no los rechaza explícitamente
  (`NaN <= 0` es falso). Probar `NaN`, `Infinity` y `1e2` como casos
  exploratorios; lo esperado según las reglas es `Ingresa un precio válido.`
- **Edición de producto:** el criterio de este plan cubre el alta. La edición
  (`editarProducto` existe en el provider) no tiene pantalla todavía, por lo
  que no se incluye.
