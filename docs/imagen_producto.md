# Decisión: imagen de producto

## Alcance

Esta funcionalidad está fuera del alcance de M2. `docs/alcance_m2.md` no la pide y no se modifica: M2 se considera completo sin ella. La imagen es una mejora opcional sobre el catálogo que ya existe.

## Contexto

El catálogo reservaba un cuadro para la imagen de cada producto, pero siempre mostraba el mismo icono de "sin imagen". La app es local y no tiene servidor, así que cualquier imagen debe vivir en el teléfono.

## Decisión

Cada producto puede tener una de tres cosas, y el catálogo las dibuja en este orden:

1. Una foto propia, tomada o elegida de la galería por el tendero.
2. Un icono de categoría de un registro fijo (Bebida, Pan, Limpieza, Mascotas y otros).
3. Si no tiene ninguna, o la foto ya no se puede leer, un icono genérico.

Nada de esto es obligatorio. Un producto sin imagen se guarda igual y nunca se ve roto.

## Por qué no una galería predefinida de productos

Una galería con imágenes de productos comerciales parece completa, pero no lo es:

- Las variantes no tienen fin. Coca-Cola lata, Coca-Cola botella 600 ml y Coca-Cola 3 L retornable son productos distintos con precios distintos. Cubrir marca por envase por tamaño es imposible.
- No cubre las marcas locales ni los productos a granel de cada tienda.
- Aumenta el tamaño de la app y usa logotipos con derechos de marca.

Las variantes ya se distinguen por el nombre, porque cada una es una fila distinta del catálogo. La imagen es una ayuda visual, no la identidad del producto. Por eso la foto propia cubre el caso exacto y el icono cubre la categoría sin trabajo extra.

## Foto o icono, nunca ambos

La tabla `producto` tiene dos columnas nullable, `imagen` e `icono`. En el código, la elección se modela con un solo tipo, `ImagenProducto` (`app_cabal/lib/models/imagen_producto.dart`), con tres casos: sin imagen, icono o foto. Al guardar, ese valor llena una columna y deja la otra en `NULL`, así que un producto no puede quedar con las dos.

## Cómo se guarda la foto

- `image_picker` entrega un archivo temporal que el sistema puede borrar. La app lo copia a `<documentos de la app>/productos/` con un nombre único.
- Se reduce al elegirla (ancho máximo de 512 px, calidad 80). Una foto de cámara pesa varios MB y haría lenta la lista del catálogo.
- La base guarda solo el nombre del archivo, no la ruta completa. En iOS la ruta del contenedor de la app cambia entre actualizaciones, y una ruta absoluta dejaría de funcionar.
- Al reemplazar o quitar una foto, el archivo anterior se borra después de que la base se actualiza. Si la base falla, la foto anterior sigue siendo la del producto.
- Al eliminar un producto no se borra su foto, porque el borrado se puede deshacer.

## Esquema

La base pasa a la versión 3. `onUpgrade` agrega `imagen` e `icono` a `producto` sin rellenar datos: los productos existentes quedan sin imagen. Ver `docs/esquema_sql.md`.

## Permisos y plataformas

- iOS: `NSPhotoLibraryUsageDescription` y `NSCameraUsageDescription` en `Info.plist`.
- macOS: `com.apple.security.files.user-selected.read-only` en los entitlements, para abrir el selector de archivos dentro del sandbox.
- Android: el selector de fotos del sistema no pide permisos.
- En escritorio no hay cámara, así que el botón "Tomar foto" no aparece. Si elegir la foto falla en cualquier plataforma, se muestra un aviso y el producto se puede guardar con icono o sin imagen.

## Fuera de esta decisión

- Duplicar un producto conservando su foto, útil para variantes de una misma marca.
- Mostrar la imagen en la pantalla de registrar venta.
