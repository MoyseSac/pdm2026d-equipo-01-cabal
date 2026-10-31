# Bitácora de uso de IA

## 2026-10-18 · Moisés Sac · Claude Code · Arreglar el CI en rojo

**Qué pedí:** revisar por qué `dart format` fallaba en el CI aunque en mi computadora pasaba, y arreglarlo.

**Qué respondió:** los 25 archivos sin formato eran salida de `dart format` aplicada en mi copia local pero nunca commiteada. El CI probaba el merge con el `main` actual, que tenía 34 archivos y no estaba formateado. Propuso una rama nueva, `chore/formato-dart`, con un commit solo de formato.

**Qué acepté:** el diagnóstico y el commit de formato, después de ver que `dart format`, `flutter analyze` y `flutter test` pasaban.

**Qué rechacé o corregí:**
- Su primera explicación (diferencia de versiones de Dart o cambios de otro integrante) era una suposición. Se corrigió al revisar `git diff` y ver que eran cambios de formato en mi copia local.
- Había sugerido commitear estos cambios en `chore/ci`, pero ese PR ya se había integrado. Se usó una rama nueva.

**Cómo lo verifiqué:** corrí los tres comandos del CI desde `app_cabal/` y revisé que el diff fuera solo formato.



## 2026-10-18 · Luis De Leon - Alexander Mendez - Julian Vasquez · ChatGPT · Implementación de cuatro estados en CatalogoScreen

**Qué pedí:** Revisar el repositorio Cabal y el laboratorio de CI para implementar correctamente los estados cargando, error, vacío y datos en la pantalla CatalogoScreen, incluyendo pruebas automatizadas.

**Qué respondió:** Propuso utilizar un FutureProvider de Riverpod conectado al servicio de productos existente, utilizar AsyncValue.when para manejar los cuatro estados y agregar un botón Reintentar que vuelva a consultar los productos mediante ref.invalidate. También propuso pruebas de widget utilizando un servicio falso mediante override.

**Qué acepté:** La creación de catalogo_provider.dart, la modificación de catalogo_screen.dart para manejar los cuatro estados y las pruebas automatizadas del catálogo.

**Qué rechacé o corregí:** Se decidió no actualizar Riverpod a la versión 3 ni reemplazar productoProvider, porque otras pantallas dependen de él. Se mantuvo el servicio SQLite existente, sin agregar funcionalidades nuevas ni modificar la base de datos.

**Cómo lo verifiqué:** Ejecuté dart format, flutter analyze y flutter test. El análisis terminó sin errores, las cuatro pruebas del catálogo fueron aprobadas y la suite completa finalizó con 105 pruebas aprobadas.


## 2026-10-22 · Daniel Ixcot · Claude · Navegación con pestañas y provider (Lab 4)

**Qué pedí:** implementar la parte de navegación del laboratorio adaptada a Cabal: pestaña activa en un provider, pantallas en un IndexedStack y ninguna opción de la barra sin hacer nada.

**Qué respondió:** propuso `tabProvider` (Notifier), un `HomeShell` con `NavigationBar` + `IndexedStack` (Catálogo, Vender, Ventas, Cierre) y una pantalla "Próximamente" para Cierre del día. Las pantallas de flujo (agregar producto, confirmación y detalle de venta) siguen como rutas encima del shell.

**Qué acepté:** el diseño anterior, "Ver ventas" en la confirmación de venta como el "Ver todo" del laboratorio y quitar el icono de ventas del catálogo (ahora es pestaña).

**Qué rechacé o corregí:**
- Invalidar el catálogo al cambiar de pestaña: hacía perder el scroll; se dejó solo para Ventas, con `skipLoadingOnReload` para conservar la lista visible.
- El botón "Probar registrar venta" del catálogo quedaba tapado por el botón flotante y es redundante con la pestaña Vender; se eliminó.
- Se restauró `venta_service_test.dart`, que `dart format` local cambiaba distinto al CI.

**Cómo lo verifiqué:** `flutter analyze` sin observaciones, `flutter test` completo en verde (incluye `navegacion_test.dart`: cambio de pestañas, scroll conservado y navegación desde el provider).


## 2026-10-28 · Moisés Sac · Claude Code · Agregar a la venta desde el catálogo

**Qué pedí:** analizar el flujo en que tocar un producto del catálogo llevaba directo a la pestaña Vender, y proponer alternativas con un selector de cantidad con + y -.

**Qué respondió:** observó que el toque solo cambiaba de pestaña sin pasar el producto. Propuso cuatro opciones (hoja inferior, stepper en la fila, diálogo, agregar 1 directo) y recomendó la hoja inferior con aviso "Ver venta" y un badge en la pestaña Vender. Después la implementó, con pruebas.

**Qué acepté:** la hoja inferior de cantidad (`cantidad_producto_sheet.dart`), el aviso con la acción "Ver venta", el badge de unidades y las cinco pruebas nuevas. Se reutilizó `agregarProducto(producto, cantidad)` de `ventaProvider`, sin cambios en el provider.

**Qué rechacé o corregí:**
- Se descartó el stepper dentro de la fila (choca con deslizar para borrar y duplica la pestaña Vender) y el diálogo centrado (peor alcance con el pulgar).
- Una de las pruebas nuevas falló al inicio porque `find.byTooltip` devuelve el `Tooltip` y no el `IconButton`; se corrigió buscando el `IconButton` ancestro.
- La prueba de `navegacion_test.dart` que daba por hecho que tocar un producto lleva a Vender se reescribió, porque ese comportamiento cambió a propósito.

**Cómo lo verifiqué:** `dart format`, `flutter analyze` sin observaciones y `flutter test` completo en verde. Además probé el funcionamiento manualmente en la app.


## Laboratorio 4 — Filtro de ventas por período

**Fecha:** 26 de octubre de 2026

**Equipo:** Cabal — Pareja JULIAN Y LUIS
**Funcionalidad:** Filtro reactivo de ventas registradas

### 1. Objetivo

Implementar un filtro de ventas por período utilizando Flutter, Riverpod y SQLite, permitiendo consultar automáticamente los registros correspondientes a Hoy, Últimos 7 días, Este mes y Todas.

### 2. Uso de inteligencia artificial

Se utilizó ChatGPT como herramienta de apoyo para diseñar la lógica del filtro, generar código de implementación, preparar pruebas automatizadas y analizar errores encontrados durante el desarrollo.

La herramienta se utilizó principalmente para:

- Diseñar la clase inmutable `VentasFiltro`.
- Implementar `VentasFiltroNotifier` mediante Riverpod.
- Calcular rangos de fechas a partir de una fecha proporcionada.
- Modificar `VentaService.obtenerVentas()` para aceptar parámetros opcionales de fecha.
- Conectar `ventasRegistradasProvider` al filtro mediante `ref.watch`.
- Incorporar el selector de períodos a la pantalla.
- Crear pruebas de widget y pruebas con SQLite real.

### 3. Cambios realizados

Se creó el archivo `ventas_filtro_provider.dart`, que contiene el enum `Periodo`, el modelo inmutable del filtro y el Notifier.

Se modificó `venta_service.dart` para filtrar las consultas directamente en SQLite utilizando condiciones parametrizadas sobre la columna `fecha_hora`.

Se actualizó `ventas_registradas_provider.dart` para observar el filtro y ejecutar automáticamente nuevas consultas cuando cambia el período.

Se modificó `ventas_registradas_screen.dart` para agregar el selector de períodos y los estados vacíos correspondientes.

### 4. Errores encontrados y correcciones

**Error 1: incompatibilidad de métodos sobrescritos**

Al ejecutar `flutter analyze`, apareció un error `invalid_override` porque las clases falsas utilizadas en las pruebas conservaban la firma anterior de `obtenerVentas()`.

Se corrigieron los métodos sobrescritos para aceptar los parámetros opcionales `desde` y `hastaExclusivo`.

**Error 2: filtro fuera del área visible**

Durante las pruebas de widget, Flutter no podía seleccionar el filtro «Este mes» porque se encontraba fuera del área visible del selector horizontal.

Se corrigió utilizando `tester.ensureVisible()` antes de seleccionar el filtro, en lugar de ocultar la advertencia con `warnIfMissed: false`.

### 5. Propuestas descartadas o ajustadas

Se descartó utilizar un botón manual de recarga para aplicar filtros, debido a que el laboratorio solicita actualización reactiva mediante `ref.watch`.

Se evitó filtrar todas las ventas únicamente en memoria, utilizando en su lugar consultas SQL con rangos de fechas.

Se mantuvo el registro histórico de ventas sin implementar su eliminación física, debido a las implicaciones sobre la información contable. El borrado con Deshacer quedó asignado al trabajo del Trío B, sujeto a la aceptación de esta distribución por el docente.

### 6. Pruebas y validación

Se implementaron cuatro pruebas de widget para comprobar la actualización automática de la lista, los estados vacíos y el botón Reintentar.

Se implementaron nueve pruebas adicionales para comprobar consultas reales con SQLite y el cálculo de períodos, incluyendo los límites de fechas.

Se ejecutaron los comandos:

`dart format`

`flutter analyze`

`flutter test`

Después de corregir los errores detectados, las comprobaciones finalizaron satisfactoriamente.

### 7. Conclusión

El uso de IA facilitó la generación inicial de código y la identificación de errores, pero fue necesario revisar, ajustar y validar las propuestas mediante las herramientas de Flutter.

La implementación final permite consultar ventas por período sin recarga manual y mantiene el comportamiento de las funciones existentes.


## 2026-10-29 · Moisés Sac · Claude Code · Imagen opcional en los productos

**Qué pedí:** analizar cómo darle imagen a los productos, que hoy solo tienen nombre y precio. Mi duda era entre iconos, fotos propias o una galería, sabiendo que un mismo producto tiene muchas variantes (Coca-Cola en lata, en botella, retornable, de 2 L y de 3 L). Después pedí implementar el plan  y que los commits se hicieran por pasos.

**Qué respondió:** recomendó foto propia opcional, o icono de categoría, o un icono genérico si no hay nada, y descartó la galería predefinida porque no puede cubrir las variantes ni las marcas locales. Las variantes ya se distinguen por el nombre, así que la imagen es una ayuda visual y no la identidad del producto. Después implementó la base de datos en versión 3, el selector en el formulario, el widget del catálogo, 18 pruebas nuevas y la documentación. El trabajo de código lo hizo un subagente y la IA revisó el resultado.

**Qué acepté:** la decisión de no hacer galería y el diseño donde foto e icono son una sola elección, para que un producto no quede con ambos. También acepté guardar solo el nombre del archivo y no la ruta, la migración sin relleno de los productos existentes y el borrado de la foto anterior solo después de que el guardado tuvo éxito.

**Qué rechacé o corregí:**
- Cambié la lista de iconos que propuso. Quité café, cerveza y snack, y reemplacé "Carnes" por "Embutidos" (con su etiqueta coherente). Quedaron 15 iconos en vez de 18.
- La funcionalidad queda fuera de M2: no se modificó `docs/alcance_m2.md`.

**Cómo lo verifiqué:** `flutter analyze` sin observaciones y `flutter test` con 175 pruebas aprobadas (eran 157), después de mis cambios a la lista de iconos. Revisé que cada commit intermedio compilara por separado. La IA probó la migración y el selector de galería en el emulador de Android con una base v2 real, y además rompió el código a propósito en tres sitios para confirmar que las pruebas fallaban. No se pudo verificar en iOS ni macOS (sin Xcode) ni "Tomar foto" con una cámara real.

## 2026-10-31 · Daniel Ixcot · Claude Code · CRUD de producto y migración v4 (laboratorio S16)

**Qué pedí:** revisar el PDF del laboratorio S16 y decirme sobre qué entidad hacer el CRUD (producto o venta), qué se debía hacer y cómo, antes de tocar código. Después pedí implementarlo siguiendo la rúbrica, criterio por criterio.

**Qué respondió:** recomendó Producto y descartó Venta, porque la venta es un historial que no se edita ni se borra. Producto ya tenía lista, agregar, editar y borrar con Deshacer, y `detalle_venta` apunta a él, así que sirve para la regla de "en uso". Propuso un plan y lo implementó en cuatro partes: el formulario sin providers y una sola lista que se refresca con `invalidate`; la regla de borrado con archivar y nombre único con mensaje humano; la migración v4 con su prueba; y la pantalla de archivados.

**Qué acepté:** elegir Producto, el plan en ese orden y la migración v4 como bloque nuevo `oldVersion < 4`, sin tocar las versiones 2 y 3. También acepté renombrar los nombres repetidos ("Pan (2)") antes de crear el índice único, para que la migración no falle en teléfonos que ya tienen repetidos, y usar un índice único que ignora mayúsculas y los productos borrados.

**Qué rechacé o corregí:**
- Interrumpí dos veces a la IA cuando iba a ejecutar un comando grande de una sola vez, y le pedí que explicara primero qué iba a hacer. Después trabajó en pasos más pequeños.
- Pedí que Archivados fuera una pantalla propia y no un bottom sheet. La IA lo cambió y borró el sheet.
- La IA dejó incompleto un commit (solo borraba el sheet y faltaban la pantalla nueva y sus ajustes). Lo detecté revisando qué faltaba por commitear y lo corregí.
- Un primer intento invalidaba la lista al borrar y desmontaba la fila antes de mostrar el aviso y el Deshacer; la IA lo corrigió y dejó la invalidación solo al descartar.
- `dart format` reformateó `venta_service_test.dart`, que el CI espera con su formato original; se revirtió.
- La IA ajustó pruebas existentes: la versión esperada de la base pasó de 3 a 4 y dos servicios falsos ahora devuelven 0 en `ventasDeProducto`.

**Cómo lo verifiqué:** `flutter analyze` sin observaciones. Pasan las pruebas nuevas: migración v3 a v4 con datos y nombres repetidos, reglas del servicio sobre una base real y pantalla del catálogo (borrar en uso, archivar, restaurar). En mi máquina `venta_provider_test.dart` falla con `UNIQUE constraint failed: producto.id`, también sin mis cambios, y sospecho de un archivo `cabal.db` viejo en `.dart_tool` que no pude borrar; no está confirmado, se confirma con el CI. Falta probarlo a mano en un emulador o dispositivo.

