# Evidencia M2 — Flujo catálogo → agregar producto

Evidencia de que el flujo de catálogo y alta de producto funciona de punta a
punta. Sigue el plan de pruebas definido en
[`../plan-pruebas-manuales-catalogo-producto.md`](../plan-pruebas-manuales-catalogo-producto.md)
(issue #36). Corresponde al issue #37.

Las capturas viven en [`capturas/`](capturas/) para que quien no pueda correr
la app localmente pueda revisarlas desde el repositorio.

## Datos de la ejecución

| Dato | Valor |
|---|---|
| Fecha | 2026-10-12 |
| Quién ejecutó | Daniel Ixcot |
| Rama / commit probado | `windows-sqflite-ffi` sobre `main` (`4a89d95`) |
| Dispositivo (emulador o físico) | Windows de escritorio (con `sqflite_common_ffi`) |
| Versión del sistema | Windows 10 (10.0.19045) |

> **Estado:** casi completo. Cubre el flujo principal y dos casos de
> validación fallando. Faltan las capturas opcionales 02 (formulario vacío) y
> 05 (persistencia tras reabrir la app).

> **Nota sobre la plataforma:** la ejecución se hizo en Windows de escritorio.
> sqflite no funciona ahí de forma nativa, por lo que se probó con el cambio
> de `sqflite_common_ffi` de la rama `windows-sqflite-ffi` (aún no está en
> `main`). Conviene repetir en Android antes de cerrar M2.

## Preparación

1. Dispositivo o emulador Android (sqflite no funciona en Windows de escritorio ni en web sin configuración extra).
2. Instalación limpia: desinstalar la app o borrar sus datos (precondición P2 del plan).
3. Desde `app_cabal/`:

   ```bash
   flutter pub get
   flutter run
   ```
4. Entrar con Login (placeholder) → "Ingresar" → Catálogo (P3).

## Evidencia requerida

Nombre de archivo sugerido para cada captura, guardada en `capturas/`.
Si se graba video corto, guardarlo como `capturas/flujo-completo.mp4`
(o enlazarlo aquí si pesa demasiado).

### 1. Flujo principal: catálogo vacío → agregar → catálogo con producto

| Paso | Caso del plan | Qué debe verse | Archivo | ✔/✘ |
|---|---|---|---|---|
| 1 | CAT-01 | Catálogo vacío: ícono, "Catálogo vacío", "No hay productos registrados aún" y botón "Agregar primer producto". Sin grid. | [`01-catalogo-vacio.png`](capturas/01-catalogo-vacio.png) | ✔ |
| 2 | CAT-02 / AGR-01 | Pantalla "Agregar producto" con formulario vacío y sin errores. | `02-agregar-vacio.png` | |
| 3 | AGR-V02 | Formulario con `Coca Cola` y `5` escritos (precio entero válido). | [`03-formulario-lleno.png`](capturas/03-formulario-lleno.png) | ✔ |
| 4 | AGR-V02 / AGR-F06 | Catálogo con el producto agregado (`$5.00`) y el estado vacío ya no aparece. | [`04-catalogo-con-producto.png`](capturas/04-catalogo-con-producto.png) | ✔ |
| 5 | AGR-F05 / CAT-12 | Tras cerrar la app por completo y reabrir, el producto sigue en el catálogo. | `05-persistencia.png` | |

### 2. Validación fallando (mínimo un caso)

El producto no se guarda y la pantalla permanece abierta.

| Caso del plan | Datos | Mensaje esperado | Archivo | ✔/✘ |
|---|---|---|---|---|
| AGR-I09 | `Pepsi` / `0` | `El precio debe ser mayor que cero.` | [`06-error-precio-cero.png`](capturas/06-error-precio-cero.png) | ✔ |
| AGR-I12 | `Pan` / `10.999` | `El precio puede tener máximo 2 decimales.` | `07-error-decimales.png` | |
| AGR-I05 | _(vacío)_ / _(vacío)_ | Errores de Nombre y Precio a la vez. | [`08-error-campos-vacios.png`](capturas/08-error-campos-vacios.png) | ✔ |

Opcional: AGR-F01 (corregir el error y guardar) como `09-corregido-y-guardado.png`.

## Resultado obtenido

Completar tras ejecutar. Si algún caso falla, anotar ID, pasos y resultado
obtenido, como pide el plan.

| Caso | Resultado | Observaciones |
|---|---|---|
| _pendiente_ | | |

### Observaciones del plan por confirmar

- **SnackBar "Producto agregado":** el catálogo lo muestra solo si la pantalla
  de alta devuelve `true`, pero hace `Navigator.pop()` sin resultado.
  Resultado observado: _pendiente_.
- **`NaN`, `Infinity`, `1e2` como precio:** esperado `Ingresa un precio válido.`
  Resultado observado: _pendiente_.

## Checklist del issue #37

- [x] Evidencia del flujo: catálogo vacío → agregar producto → catálogo muestra el producto
- [x] Al menos un caso de validación fallando
- [x] La evidencia sigue el plan de pruebas del issue #36
- [x] Evidencia en `docs/` (o adjunta al milestone M2), accesible sin correr la app

## Fuera de alcance

Pruebas automatizadas y cualquier funcionalidad fuera de catálogo/producto
(venta, cierre del día).
