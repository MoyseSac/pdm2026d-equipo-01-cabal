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

## 2026-10-31 · Moisés Sac · Claude Code · Revisión del PR #91 y formulario de producto sin providers

**Qué pedí:** analizar el PDF del laboratorio S16 y el PR #91 de Daniel contra la rúbrica, usando como referencia las retroalimentaciones de mis laboratorios anteriores, para que el grupo no perdiera puntos por proceso. Después pedí un borrador de comentario de revisión y que corrigiera el hallazgo sobre el formulario.

**Qué respondió:** dijo que el código cubría bien las reglas de borrado, el nombre único y la migración v4 con su prueba, y que el riesgo estaba en el proceso. Listó varios hallazgos: la bitácora de Daniel no estaba en el PR, la casilla de emulador estaba sin marcar, tocar la fila abre la hoja de cantidad y no el formulario, el PR junta CRUD y migración, y `AgregarProductoScreen` seguía leyendo `imagenProductoServiceProvider` aunque la descripción decía que ya no conocía providers. Para este último hizo la corrección: el formulario pasó a `StatefulWidget`, recibe `imagenes` por constructor y `FormularioProductoConectado` es el único que lee el provider. Redactó el borrador del comentario.

**Qué acepté:** solo dos cosas. Le hice saber a Daniel que faltaba su entrada de bitácora, y la subió en `78e085b`. Y acepté la corrección del formulario, un commit de dos archivos que comprobé con `grep`: el formulario ya no importa Riverpod ni `providers/`.

**Qué rechacé o corregí:**
- Propuso que Alexander actualizara `docs/esquema_sql.md`. Lo rechacé porque no es parte de la rúbrica de este lab.
- Los demás hallazgos (tocar la fila, un PR en lugar de dos, emulador y capturas) no tomé decisión sobre ellos; quedaron como observaciones.
- Su análisis partió de la rama en `33096b1`, antes de que Daniel subiera `78e085b`, así que su punto sobre la bitácora quedó obsoleto.
- Al correr `dart format` antes de `flutter pub get`, reformateó 10 archivos que no había tocado. Se revirtieron y el commit quedó solo con los 2 archivos del cambio.
- No dejé que la IA empujara a la rama de Daniel. Traje el commit con `git pull --ff-only` y `git cherry-pick`, sin `--force`.

**Cómo lo verifiqué:** en un worktree aparte, `dart format --set-exit-if-changed` sin cambios, `flutter analyze` sin observaciones y `flutter test` con 195 pruebas aprobadas. CI en GitHub sobre `3b4b000`: verde. Prueba manual en emulador: la hice y todo siguió funcionando.

## 2026-11-04 · Moisés Sac · Claude Code · Animación de entrada, paleta y logo

**Qué pedí:** explicarle que Cabal ya no tendrá usuario ni contraseña (el catedrático dijo que sería innecesario y que exigiría un servicio en la nube para registrar o reiniciar contraseñas, así que se usará la huella o el desbloqueo del teléfono) y preguntar qué opciones había para animar la entrada a la app. Después pedí tres propuestas de paleta de colores a partir del objetivo del README, un logo y más ideas con la paleta elegida. Por último pedí que la IA hiciera la animación mientras yo supervisaba, dejando el diseño y el plan registrados.

**Qué respondió:** presentó cuatro opciones de animación (implícita, explícita, transición entre rutas y Lottie/Rive) y recomendó la explícita, con un solo controlador y tramos escalonados. Propuso tres paletas con contrastes calculados, tres conceptos de logo y después cinco más, con la C con visto como recomendación. Hizo un plan, creó el issue #92 con `gh` y lo implementó en seis commits: fuente y paleta, logo y palabra animados, renombre de Login a Entrada, la pantalla animada con sus pruebas, el documento de diseño y esta entrada.

**Qué acepté:** la animación explícita, letra por letra; la paleta B (marino y verde); el logo C con visto; el plan; que la IA creara el issue y descargara la fuente Montserrat (con su licencia OFL) al proyecto; y renombrar Login a Entrada en un commit aparte.

**Qué rechacé o corregí:** nada explícito en esta sesión: elegí entre las opciones que la IA propuso. Lo que la IA corrigió por su cuenta mientras trabajaba: una prueba del logo que fallaba (el escalado del lienzo cuenta como pintar, así que `paintsNothing` no servía) y una prueba de animaciones desactivadas, donde un redondeo de decimales dejaba la última letra al 99.99 % de opacidad. Además, al diseñar la pantalla descartó una pausa final con `Future.delayed`, porque `pumpAndSettle` terminaría antes de la navegación y habría que cambiar las pruebas existentes; la pausa quedó dentro del mismo controlador.

**Cómo lo verifiqué:** `dart format`, `flutter analyze` sin observaciones y `flutter test` con 188 pruebas aprobadas (eran 175). En un emulador Android 17 (Pixel 8 Pro) la IA vio el logo, CABAL con la L en menta y el paso automático al Catálogo. En ese emulador los iconos de la barra de estado se vieron oscuros sobre el marino aunque la app pide iconos claros; yo la probé después en mi teléfono y ahí se ven claros y legibles al abrir la app, así que parece un detalle del emulador. No se anotó el modelo del teléfono y no se probó en iOS. Antes de la animación se ve la pantalla de arranque nativa blanca de Android; queda para otro issue, junto con la huella (`local_auth`), el `ThemeData` global y el ícono de la app.

## 2026-11-04 · Moisés Sac · Claude Code · Tema de color de toda la app

**Qué pedí:** que el siguiente issue fuera aplicar en la app los colores de la paleta ya decidida, que hasta entonces solo usaba la pantalla de entrada.

**Qué respondió:** exploró el código y encontró que `MaterialApp` no definía tema (por eso todo se veía morado) y que había unos 45 colores fijos (`Colors.red`, `Colors.green`, `Colors.grey[...]`) en 13 archivos. Propuso un plan con un `ColorScheme` armado a mano con la paleta, temas de componentes y el reemplazo de esos colores por los del tema, y me hizo dos preguntas de diseño. Creó el issue #94 con `gh` y lo implementó en cinco commits: el tema con sus pruebas, los rojos y verdes, los grises, un ajuste de los campos de texto y la documentación con capturas.

**Qué acepté:** el plan; que la barra superior fuera marino con texto blanco; que el precio de cada producto pasara de verde a marino en negrita (el verde queda para acciones y para "salió bien"); que la IA creara el issue.

**Qué rechacé o corregí:** nada explícito en esta sesión: elegí entre las opciones que la IA propuso. Lo que la IA corrigió por su cuenta: al ver una captura del formulario con errores, la etiqueta de un campo con error salía verde porque el tema de campos fijaba ese color; quitó ese tema y dejó que el esquema decida (la etiqueta con error ahora sale roja). Además agregó tres colores que la paleta no traía (error, un menta claro y un color de borde) con su contraste calculado, y los documentó como nuevos.

**Cómo lo verifiqué:** `dart format`, `flutter analyze` sin observaciones y `flutter test` con 226 pruebas aprobadas (eran 208), incluida una prueba que comprueba el contraste de cada pareja de colores del tema. La IA revisó en un emulador Android (Pixel 8 Pro) con la app compilada en modo release: catálogo vacío y con productos, formulario con errores, hoja de cantidad, Vender, venta actual, venta confirmada, Ventas, Cierre y deslizar para borrar; las capturas están en `docs/evidencia-tema-de-color/`. No probé todavía en mi teléfono ni en iOS, y no se revisaron en pantalla Archivados ni el detalle de una venta. El modo oscuro no existe y queda fuera.

## 2026-11-04 · Moisés Sac · Claude Code · La pestaña Vender muestra solo lo agregado a la venta

**Qué pedí:** corregir un problema que ya había visto desde varios merges atrás: al ir a Vender aparecían los mismos productos de la primera pestaña, y quería que esa vista mostrara solo el listado de lo agregado al carrito. Después pedí que se creara el issue, que la rama saliera de `main` y que se hicieran los commits y el PR.

**Qué respondió:** exploró el código y encontró que `RegistrarVentaScreen` pintaba dos listas a propósito: "Productos" (todo el catálogo, tocable para agregar) y "Venta actual". Como el Catálogo ya agrega a la venta con la hoja de cantidad, esa primera lista sobraba. Propuso quitarla, dejar que la pantalla dependa solo de `ventaProvider` y reemplazar el aviso de "No hay productos registrados" por un estado de venta vacía con un botón "Ir al catálogo". Las pruebas agregaban productos tocando esa lista, así que las reescribió para agregar por `ventaProvider` y sumó una que comprueba que un producto del catálogo que no se agregó no aparece en Vender. Dejó el issue #96, el commit y el PR #97.

**Qué acepté:** el plan completo, incluido dejar sin tocar `docs/pruebas-manuales-ventas-m3.md` y `docs/pantallas-navegacion-mvp.md`, que describen la lista "Productos" como registro del hito M3; el texto y el botón del estado vacío; reescribir las pruebas en lugar de borrarlas.

**Qué rechacé o corregí:** la IA recomendaba abrir la rama nueva desde la del tema de color (#94). Pedí que fuera desde `main` y que primero se creara el issue. Como la rama local `main` estaba desactualizada, se hizo desde `origin/main`, que ya incluía el PR #95.

**Cómo lo verifiqué:** `dart format`, `flutter analyze` sin observaciones y `flutter test` con 227 pruebas aprobadas (eran 226). Probé la app en mi dispositivo y todo funcionó: Vender muestra solo lo agregado y la venta vacía lleva de vuelta al Catálogo. El CI del PR #97 salió en verde. No se probó en iOS.

## 2026-11-04 · Moisés Sac · Claude Code · Migración de la base repetible

**Qué pedí:** una propuesta de cambios para que funcione el cierre del día. Decidí que el cierre fuera un registro guardado, con historial de cierres anteriores, lo que exige una migración nueva de la base.

**Qué respondió:** en una sesión anterior me había salido el error "duplicate column name: archivado_en" al abrir la base en mi teléfono, y lo resolví reinstalando la app, sin arreglar la causa. Al querer trabajar el cierre, la IA señaló que ese error seguía pendiente y que había que arreglarlo antes: `onUpgrade` se detiene en el primer paso que falla, así que la versión 5 del cierre no correría en una base así. Recomendó hacerlo en su propio issue y lo hizo: comprueba con `PRAGMA table_info` antes de cada `ADD COLUMN`, usa `IF NOT EXISTS` en el índice único y rellena `nombre_producto` solo donde está vacío.

**Qué acepté:** arreglar primero ese error, por separado del cierre; que el arreglo no cambie la versión de la base ni el resultado de las migraciones que ya corrían bien.

**Qué rechacé o corregí:** nada explícito en esta sesión: acepté lo que propuso. Lo que la IA ajustó por su cuenta: el relleno de `nombre_producto` de la v2 pisaba nombres que ya existían, y lo limitó a los vacíos con una prueba aparte.

**Cómo lo verifiqué:** `dart format`, `flutter analyze` sin observaciones y `flutter test` con 233 pruebas aprobadas (eran 227); el CI del PR salió en verde. Las pruebas nuevas, con una base v3 que ya tiene `archivado_en`, una v1 con columnas repetidas y una con el índice ya creado, fallaban antes del arreglo. En mi teléfono Android dejé una base en versión 3 con `archivado_en` ya presente: con el código anterior reproduje el error, y con el arreglo la app abrió sin desinstalarla y la base quedó en la versión 4. Las capturas de ambos pasos están en el PR. No se probó en iOS.

## 2026-11-05 · Moisés Sac · Claude Code · Cierre del día de hoy

**Qué pedí:** que la pestaña Cierre dejara de decir "Próximamente" y mostrara el cierre de hoy. Decidí que el cierre fuera un registro guardado y no solo una vista calculada, que hubiera un historial de cierres anteriores en un issue aparte, y que la evidencia fueran capturas en el PR y no un documento de pruebas manuales. Este issue es solo el cierre de hoy. Ya con la pantalla funcionando pedí tres cambios: quitar los productos "sin vender", una confirmación antes de cerrar, y que la vista fuera más clara con pocos y con muchos productos, primero como maqueta y luego aplicada lo más parecido posible con componentes de Flutter.

**Qué respondió:** propuso guardar el cierre como una foto del día en dos tablas nuevas (`cierre` y `cierre_producto`, versión 5 de la base), con el dinero en centavos enteros y la suma hecha en SQL para no acumular errores de decimales, y que cerrar otra vez el mismo día reemplace el cierre en una transacción. Implementó el esquema con su prueba de migración, el servicio, el provider, la pantalla con sus cuatro estados y las pruebas, y actualizó `docs/esquema_sql.md`, que decía versión 3. Para la legibilidad propuso un bloque con el total en grande, cada producto con una barra de su peso en el total y ordenados por monto, solo los 5 primeros con "Ver los N restantes" y un buscador, y una barra fija abajo con el total y el botón. Para la confirmación agregó un diálogo con el número de ventas y el total, que avisa cuando va a reemplazar un cierre anterior.

**Qué acepté:** el plan aprobado, incluido que solo se pueda cerrar hoy, que se pueda volver a cerrar con un aviso cuando hay ventas nuevas y que la pantalla muestre la foto guardada mientras no haya cambios. El issue #100 ya estaba creado; la IA trabajó sobre él. También acepté que el dinero de toda la app lleve separador de miles (Q1,234.57 en vez de Q1234.57).

**Qué rechacé o corregí:** el plan incluía una lista de productos "sin vender" (primero decidí que no incluyera archivados). Al verla objeté que con 50 productos no tendría sentido enlistarlos; la IA la dejó colapsada y después pedí quitarla por completo porque no es relevante para el cierre de caja. La pantalla y el cierre guardado solo tienen los productos vendidos. Esto se aparta del texto del README y de `docs/pantallas-navegacion-mvp.md`, que hablan de "qué se vendió y qué no"; esos documentos no se cambiaron. También noté que un toque sin querer en "Cerrar día" guardaba el cierre al instante y pedí la confirmación.

Lo que la IA corrigió por su cuenta: el botón de cerrar quedaba tapado por el aviso de error al fallar, así que lo dejó en la parte inferior de la pantalla, donde el aviso aparece encima; y las pruebas de migraciones anteriores comprobaban la versión 4, así que las actualizó a 5 (cambia a propósito, no son migraciones nuevas). Al poner el separador de miles actualizó la prueba que fijaba el formato anterior.

**Cómo lo verifiqué:** `dart format`, `flutter analyze` sin observaciones y `flutter test` con 288 pruebas aprobadas (eran 233). Las pruebas del servicio usan una base real e incluyen los límites del día, el precio al momento, productos archivados o borrados después de vender, y que 0.10 + 0.20 + 0.30 dé 0.60. Probé la pantalla y la migración en mi teléfono y todo funcionó; las capturas las subo al PR. No se probó en iOS.


## 2026-11-08 · Moisés Sac · Codex · Búsqueda de productos en el catálogo (#102)

**Qué pedí:** leer el README, analizar cómo buscar productos sin recorrer manualmente el catálogo e implementar la lupa, dejando la paginación para después. Después pedí usar una rama con el formato del proyecto y subir el cambio.

**Qué respondió:** agregó una barra fija que filtra por nombre parcial sobre los productos activos ya cargados, ignora mayúsculas, tildes y espacios sobrantes, permite limpiar la consulta y distingue la ausencia de coincidencias del catálogo vacío. Conservó las acciones de cada producto y cierra el teclado al abrir la hoja de cantidad. No cambió la base ni agregó dependencias.

**Qué acepté:** implementar la búsqueda; evaluar la paginación por separado.

**Qué rechacé o corregí:** la rama inicial llevaba el prefijo de la herramienta. Pedí seguir el formato del proyecto; se reemplazó por `feat/102-busqueda-productos`, vinculada al issue #102 y basada en `main`.

**Cómo lo verifiqué:** 32 pruebas de catálogo, venta, edición y eliminación aprobadas y `flutter analyze` sin observaciones. Antes de subir se ejecutó la suite completa: 290 pruebas aprobadas. Se agregaron pruebas de filtro con tildes y espacios, limpiar, ausencia de coincidencias y agregar a la venta desde resultados filtrados. Se verifico manualmente en emulador


## 2026-11-08 · Moisés Sac · Codex · Rediseño de la fila de producto del catálogo

**Qué pedí:** analizar la vista principal del catálogo para identificar mejoras de limpieza y consistencia visual con la skill ui-styling. Después pedí aplicar el rediseño de la fila de producto y preparar una rama con los commits, dejando la bitácora para revisión antes del push.

**Qué respondió:** revisó el código de la pantalla, el tema y una captura guardada, y aclaró que la captura era anterior al buscador. Detectó que tocar la fila agrega a la venta, aunque la acción visible era editar. Propuso colocar el nombre sobre el precio junto a la imagen, mostrar un botón “+” para agregar a la venta y mover editar y eliminar a un menú secundario.

**Qué acepté:** aplicar el rediseño de la fila. El nombre usa el estilo del tema con peso semibold y el precio aparece debajo con menor énfasis. El botón “+” abre la hoja de cantidad existente y el menú permite editar o eliminar. Se conservaron tocar la fila para agregar, mantener pulsado para editar y deslizar para eliminar.

**Qué rechacé o corregí:** no hubo correcciones solicitadas durante la implementación. Las otras propuestas del análisis (buscador, espacio bajo la lista y estado vacío) quedaron fuera de este cambio. El borrado desde el menú reutiliza la validación de productos con ventas y la opción Deshacer.

**Cómo lo verifiqué:** Codex ejecutó las pruebas de catálogo, agregar a la venta, edición, eliminación y productos en uso: 37 pruebas aprobadas. Actualizó las pruebas de edición para acceder desde el menú, comprobó el botón “+” y agregó una prueba de eliminar desde el menú y deshacer. Ejecutó `flutter analyze` sin observaciones y `git diff --check` sin errores. No se ejecutó la suite completa. Verifiqué visualmente todo el flujo desde la aplicación. Al revisar esta entrada, pedí corregir la ausencia de esa validación manual. El push queda pendiente.


## 2026-11-09 · Moisés Sac · Codex · Espacio inferior del catálogo y convivencia con avisos

**Qué pedí:** preparar primero un plan para evitar que «Agregar producto» tape el último producto y permitir desplazar la lista por encima del botón. Después pedí implementar el plan, ejecutar las pruebas y mostrar la entrada de bitácora antes de abrir el PR.

**Qué respondió:** revisó `CatalogoScreen`, `HomeShell`, la navegación inferior, el teclado y los avisos. Aumentó el padding inferior de la lista de 12 a 88 píxeles lógicos, conservando los demás márgenes. Como los avisos se muestran en el contenedor exterior y este no conoce el FAB del catálogo, los colocó por encima del botón. Limitó a tres líneas, con puntos suspensivos, el mensaje de agregar a la venta para evitar que un nombre largo saque el aviso de la pantalla.

**Qué acepté:** implementar el espacio inferior y ajustar la convivencia de lista, FAB y avisos. El buscador, el estado vacío y el diseño de las filas quedaron fuera del cambio.

**Qué rechacé o corregí:** durante las pruebas, la IA corrigió el aviso largo y ajustó la prueba del teclado para arrastrar hacia una dirección con recorrido disponible.

**Cómo lo verifiqué:** Codex ejecutó 43 pruebas de catálogo, agregar a la venta, edición, eliminación y navegación; todas aprobaron. Incluyen pantallas de 320 × 568 y 360 × 640, nombres largos, texto ampliado, teclado y acceso al último producto. `flutter analyze` terminó sin observaciones y `git diff --check` sin errores. No se ejecutó la suite completa. También realicé las pruebas manuales del ajuste desde la aplicación.

Las pruebas automatizadas detectaron desbordamientos con texto ampliado en la hoja de cantidad y en la pantalla de venta; quedaron fuera del alcance. Para comprobar el aviso ampliado sin mezclar esos problemas, la prueba abre la hoja con escala normal, amplía el texto al mostrar el aviso y vuelve a escala normal antes de navegar.

## 2026-11-10 · Moisés Sac · Codex · Buscador y alineaciones del catálogo

**Qué pedí:** unificar el buscador y las alineaciones del catálogo, primero con un plan para revisión y después con la implementación.

**Qué respondió:** estandarizó los márgenes exteriores del buscador y las tarjetas en 16 píxeles lógicos, con 16 entre el buscador y la primera tarjeta y 8 entre tarjetas. El buscador usa fondo blanco del tema, radio de 12 como las tarjetas, altura mínima de 56 que permite crecer con texto ampliado y relleno explícito. El borde verde identifica el foco y el botón de limpiar conserva un área mínima de 48. El estilo se aplica solo al catálogo para no afectar otros formularios.

**Qué acepté:** el ajuste del buscador y las alineaciones, conservando la fila rediseñada, el espacio inferior de 88, los avisos sobre el botón flotante y las acciones existentes.

**Qué rechacé o corregí:** no solicité cambios al ajuste después de probarlo en el emulador.

**Cómo lo verifiqué:** se ejecutaron 51 pruebas focalizadas de catálogo, agregar a la venta, edición, eliminación, productos en uso y navegación; todas aprobaron. Incluyen alineación y adaptación del buscador en anchos de 320 y 360 con texto normal y al doble de tamaño, además de búsqueda con tildes y espacios, limpiar, teclado, acceso al último producto, avisos y Deshacer. `flutter analyze` terminó sin observaciones y `git diff --check` sin errores. También realicé la validación visual en el emulador y confirmé que el ajuste funciona correctamente. No se ejecutó la suite completa. Los desbordamientos ya documentados en cantidad y venta quedan como deuda separada.


## 2026-11-10 · Moisés Sac · Jerarquía tipográfica del catálogo

**Qué pedí:** preparar un plan para mejorar la jerarquía visual y tipografía del catálogo y después empezar a implementar los cambios propuestos.

**Qué respondió:** comprobó que nombre y precio ya usan `titleMedium/w600` y `bodyMedium/w500` con color secundario. Conservó esos estilos y el título y acciones heredados de Material. Cambió el mensaje de error de tamaño fijo 16 a `textTheme.bodyLarge` para derivar su tipografía del tema sin afectar otras pantallas. No modificó el tema global, buscador, márgenes, espacio inferior ni estado vacío.

**Qué acepté:** implementar el ajuste acotado y validar nombres largos y escalado.

**Qué rechacé o corregí:** no hubo nuevas correcciones del usuario. Se corrigió el precio esperado en la prueba nueva para incluir el separador de miles que ya usa la aplicación.

**Cómo lo verifiqué:** Se ejecutaron 51 pruebas focalizadas de catálogo, agregar a la venta, edición, eliminación y productos en uso; todas aprobaron. Las cuatro pruebas nuevas comprueban nombres largos con y sin espacios y precios de distinta longitud a anchos de 320 y 360 y escalas 1 y 2, sin excepciones de layout y sin superposición de nombre, precio y botón de agregar. `flutter analyze` terminó sin observaciones. El contraste calculado con la paleta actual es 6.67:1 para precio sobre tarjeta blanca, 15.77:1 para nombre sobre blanco y título blanco sobre marino, y 6.23:1 para texto secundario sobre fondo claro. Antes del push, tras integrar `main`, se ejecutó la suite completa: 305 pruebas aprobadas y `flutter analyze` sin observaciones. También verifiqué los cambios desde la aplicación y confirmé que todo está bien.

## 2026-11-10 · Moisés Sac · Estado vacío del catálogo

**Qué pedí:** mejorar el estado vacío del catálogo, con un plan previo y después su implementación.

**Qué respondió:** confirmó que el botón central y el flotante duplicaban la acción de agregar. Dejó solo «Agregar primer producto» cuando no hay productos activos, cambió el carrito por un icono de inventario y propuso «Tu catálogo está vacío» con una explicación orientada a empezar a registrar ventas. La composición usa el tema existente, centra el contenido cuando hay espacio y permite desplazarlo cuando falta altura; el botón admite varias líneas y tiene altura mínima de 48.

**Qué acepté:** aplicar el plan, conservando la búsqueda sin coincidencias como un estado distinto, los estados de carga y error, las filas y el comportamiento de Deshacer.

**Qué rechacé o corregí:** no hubo nuevas correcciones del usuario. Durante la validación, se corrigió la lectura de datos para que la condición del botón flotante no interfiriera con el estado de error. Las pruebas con texto al doble detectaron un desbordamiento en `palabra_cabal.dart`, en la pantalla de entrada; quedó fuera del alcance y la adaptación del catálogo se comprobó directamente dentro de `HomeShell`.

**Cómo lo verifiqué:** Se ejecutaron 55 pruebas focalizadas de catálogo, eliminación, edición, productos en uso y agregar a la venta; todas aprobaron. Incluyen la ausencia del botón flotante en vacío, su regreso tras Deshacer, navegación al formulario y el estado vacío dentro de `HomeShell` en 320 × 568 y 360 × 640 con escalas de texto 1 y 2 y espacio de teclado simulado. `flutter analyze` terminó sin observaciones y `git diff --check` sin errores. Después se actualizaron tres pruebas de imágenes para abrir el formulario desde «Agregar primer producto», y se ejecutó la suite completa: 309 pruebas aprobadas. También realicé la validación visual desde el emulador y adjunté capturas del catálogo vacío y de la búsqueda sin coincidencias. No se hizo validación de lector de pantalla o de teclado físico.

## 2026-11-11 · Moisés Sac · Codex · Estados y recuperación de Vender (#115)

**Qué pedí:** implementar el primer bloque de mejoras de Vender sobre el PR #114, con issue previo y commits separados. El objetivo es explicar cómo empezar, continuar y recuperar una venta, conservando la paleta de Cabal.

**Qué acepté:** distinguir venta vacía, catálogo sin productos, carga y error; ocultar el resumen vacío; mostrar productos y unidades y permitir agregar más. La edición informa las cantidades inválidas y aclara que el total conserva los últimos valores válidos. Deshacer recupera la fila con su posición, cantidad y precio original. Durante el registro se deshabilitan edición y navegación; un fallo conserva la selección y ofrece reintentar. Nueva venta lleva al catálogo.

**Qué se dejó fuera:** tarjetas, reorganización visual de las filas y animaciones, correspondientes al segundo PR. Se conservaron el esquema, las dependencias y las reglas monetarias existentes. No se introdujo una nueva decisión de arquitectura.

**Cómo se verificó:** 53 pruebas focalizadas y la suite completa de 318 pruebas aprobadas; `flutter analyze` sin observaciones y `git diff --check` sin errores. Las pruebas agregadas cubren carga y recuperación del catálogo, creación del primer producto, contador y continuidad de la selección, Deshacer y sus límites, corrección de cantidades desde el catálogo y bloqueo de edición/navegación durante el guardado. La persistencia se comprobó también con SQLite real. La revisión manual en la app y las capturas quedan pendientes del autor; esta entrada no las da por realizadas. La adaptación visual completa de las filas a texto ampliado sigue en el segundo PR.

## 2026-11-11 · Moisés Sac · Codex · Composición visual de Vender (#117)

**Qué pedí:** mejorar la lectura y edición de una venta sin que dos productos consuman casi toda la pantalla. Pedí distinguir claramente subtotal y total, corregir la etiqueta Cantidad recortada y adoptar una lista similar a la referencia compartida, con imagen e importe por producto.

**Qué acepté:** lista con imágenes pequeñas del catálogo y separadores suaves, sin tarjetas individuales. Cada fila muestra nombre de hasta dos líneas, precio unitario y subtotal a la derecha cuando hay espacio; si falta ancho, el subtotal baja con su etiqueta. El precio unitario conserva el ancho disponible debajo del nombre y el importe. Cantidad se lee completa encima del grupo de controles, fuera del campo numérico; las acciones conservan áreas de al menos 48 y nombres accesibles por producto. Eliminar mantiene Deshacer. El total tiene mayor énfasis en un resumen separado, fijo cuando hay altura e integrado al desplazamiento con teclado, paisaje o texto ampliado. Se conservan errores, edición en listas largas y transiciones con movimiento reducido.

**Qué se corrigió:** la composición inicial separaba demasiadas zonas en tarjetas y la etiqueta abreviada se recortaba dentro del campo. La lista elimina esos contenedores y facilita comparar nombres e importes, manteniendo los controles visibles para editar sin abrir otra pantalla. Se conserva la paleta actual y no cambian esquema, dependencias ni reglas monetarias.

**Cómo se verificó:** 68 pruebas focalizadas y suite completa de 340 pruebas aprobadas; análisis, formato y `git diff --check` sin observaciones. La verificación de dos productos cortos completos sobre el resumen en 360 × 640 incluye la ausencia de tarjetas, presencia de imágenes, posición del subtotal y filas de hasta 144 de altura con la fuente de pruebas. La matriz cubre teléfono pequeño, paisaje, tablet, escalas 1 y 2, etiqueta Cantidad completa, importes largos, teclado, errores, listas largas, edición rápida y nombres semánticos. La revisión manual de la nueva vista de lista, capturas y prueba real con lector de pantalla quedan pendientes; la validación automatizada no se presenta como revisión manual.
